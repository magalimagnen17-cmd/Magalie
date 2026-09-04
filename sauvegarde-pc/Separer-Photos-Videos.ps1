# ==========================================================
#  SEPARER LES PHOTOS DES VIDEOS
#  Google Drive synchronise des DOSSIERS entiers, pas des
#  types de fichiers. Pour ne sauvegarder que les photos, il
#  faut donc que les videos soient ailleurs.
#  Le dossier Videos de Windows est vide alors que les .MOV
#  du telephone sont ranges dans Images : on les remet a
#  leur place, en conservant l'arborescence.
#  Le script MESURE d'abord et ne deplace rien sans
#  confirmation. Aucun fichier n'est supprime ni converti.
# ==========================================================

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference    = "SilentlyContinue"

$L = New-Object System.Collections.ArrayList
function W($t){ [void]$L.Add([string]$t); Write-Host $t }
function T($t){ [void]$L.Add(""); [void]$L.Add("=== $t ==="); Write-Host ""; Write-Host "=== $t ===" -ForegroundColor Cyan }
function Go($o){
  if ($o -eq $null) { return "?" }
  if ($o -ge 1GB) { return ("{0:N2} Go" -f ($o/1GB)) }
  if ($o -ge 1MB) { return ("{0:N0} Mo" -f ($o/1MB)) }
  return ("{0:N0} Ko" -f ($o/1KB))
}
function CheminBureau {
  $reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
  $b = (Get-ItemProperty -Path $reg -Name "Desktop" -ErrorAction SilentlyContinue).Desktop
  if ($b) { $b = [Environment]::ExpandEnvironmentVariables($b) }
  foreach ($c in @($b, [Environment]::GetFolderPath("Desktop"), (Join-Path $env:USERPROFILE "Desktop"))) {
    if ($c -and (Test-Path -LiteralPath $c)) { return $c }
  }
  return $env:TEMP
}
function DossierConnu($cle, $defaut){
  $reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
  $b = (Get-ItemProperty -Path $reg -Name $cle -ErrorAction SilentlyContinue).($cle)
  if ([string]::IsNullOrEmpty($b)) { return (Join-Path $env:USERPROFILE $defaut) }
  return [Environment]::ExpandEnvironmentVariables($b)
}

$VIDEO = @(".mov",".mp4",".avi",".mkv",".m4v",".3gp",".mpg",".mpeg",".wmv",".mts",".m2ts",".flv")

try {

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  SEPARER LES PHOTOS DES VIDEOS" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Etape 1 : mesure. Rien ne bouge sans confirmation." -ForegroundColor Yellow
Write-Host ""

$bureau = CheminBureau
$images = DossierConnu "My Pictures" "Pictures"
$videos = DossierConnu "My Video" "Videos"

W "=========================================================="
W "  SEPARER LES PHOTOS DES VIDEOS"
W ("  " + $env:COMPUTERNAME + " / " + $env:USERNAME + "   " + (Get-Date -Format "dd/MM/yyyy HH:mm"))
W "=========================================================="
W ""
W ("Source      : " + $images)
W ("Destination : " + $videos)

if (-not (Test-Path -LiteralPath $images)) {
  W "Le dossier Images est introuvable."
  Write-Host ""; Write-Host "  Entree pour fermer." -ForegroundColor Cyan; Read-Host; exit
}

# ---------- Mesure ----------
Write-Host "  Lecture du dossier Images..." -ForegroundColor Gray
$tous = @(Get-ChildItem -LiteralPath $images -Recurse -File -Force -ErrorAction SilentlyContinue)
$vids = @($tous | Where-Object { $VIDEO -contains $_.Extension.ToLower() })
$rest = @($tous | Where-Object { $VIDEO -notcontains $_.Extension.ToLower() })

$oTous = ($tous | Measure-Object Length -Sum).Sum
$oVids = ($vids | Measure-Object Length -Sum).Sum
$oRest = ($rest | Measure-Object Length -Sum).Sum
if (-not $oTous) { $oTous = 0 }; if (-not $oVids) { $oVids = 0 }; if (-not $oRest) { $oRest = 0 }

T "CE QUE CONTIENT LE DOSSIER IMAGES"
W ("Total          : " + (Go $oTous) + "   " + $tous.Count + " fichiers")
W ("dont videos    : " + (Go $oVids) + "   " + $vids.Count + " fichiers")
W ("dont le reste  : " + (Go $oRest) + "   " + $rest.Count + " fichiers")

# ---------- Repartition par sous-dossier ----------
T "PAR SOUS-DOSSIER, UNE FOIS LES VIDEOS SORTIES"
$parDos = @{}
foreach ($f in $rest) {
  $rel = $f.DirectoryName
  if ($rel.Length -gt $images.Length) { $cle = ($rel.Substring($images.Length).TrimStart("\") -split "\\")[0] }
  else { $cle = "  (racine)" }
  if (-not $parDos.ContainsKey($cle)) { $parDos[$cle] = New-Object PSObject -Property @{ O=[int64]0; N=0 } }
  $parDos[$cle].O += $f.Length
  $parDos[$cle].N++
}
$drive = Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue |
         Where-Object { $_.VolumeName -like "*Google Drive*" } | Select-Object -First 1
$dispo = if ($drive -and $drive.FreeSpace -gt 0) { [int64]$drive.FreeSpace } else { $null }

W ("{0,-36} {1,10} {2,8} {3,12}" -f "Dossier", "Photos", "Fichiers", "Cumul")
W ("-" * 70)
$cumul = [int64]0
foreach ($k in ($parDos.Keys | Sort-Object { -$parDos[$_].O })) {
  $cumul += $parDos[$k].O
  $marque = ""
  if ($dispo -and $cumul -le $dispo) { $marque = "  tient" }
  W ("{0,-36} {1,10} {2,8} {3,12}{4}" -f $k, (Go $parDos[$k].O), $parDos[$k].N, (Go $cumul), $marque)
}

# ---------- Verdict ----------
T "EST-CE QUE LES PHOTOS TIENNENT DANS LE DRIVE ?"
if ($dispo) {
  W ("Place libre dans Drive : " + (Go $dispo))
  W ("Photos a sauvegarder   : " + (Go $oRest))
  W ""
  if ($oRest -le $dispo) {
    W "-> OUI. Toutes les photos tiennent, une fois les videos sorties."
    W ("   Il restera " + (Go ($dispo - $oRest)) + " de marge.")
  } else {
    W ("-> NON, il manque " + (Go ($oRest - $dispo)) + ".")
    W "   La colonne Cumul ci-dessus indique jusqu'ou descendre :"
    W "   les dossiers marques 'tient' rentrent, les suivants non."
    W "   Il faudra alors synchroniser dossier par dossier plutot"
    W "   que le dossier Images en entier."
  }
} else {
  W "Lecteur Google Drive non detecte, comparaison impossible."
}
W ""
W "Les videos, elles, resteront sur le disque de ce PC et ne"
W "seront sauvegardees nulle part. C'est un choix assume, mais"
W "il faut le savoir : ce disque est un modele mecanique, et un"
W "disque mecanique finit toujours par s'arreter. Une cle USB de"
W "32 Go, moins de dix euros, suffirait a les mettre a l'abri."

# ---------- Action ----------
if ($vids.Count -eq 0) {
  W ""
  W "Aucune video dans Images : il n'y a rien a deplacer."
  Write-Host ""; Write-Host "  Entree pour fermer." -ForegroundColor Cyan; Read-Host; exit
}

Write-Host ""
Write-Host "  DEPLACER LES $($vids.Count) VIDEOS VERS LE DOSSIER VIDEOS ?" -ForegroundColor Cyan
Write-Host ""
Write-Host "  L'arborescence est conservee : une video rangee dans"
Write-Host "  Images\giulia se retrouvera dans Videos\giulia."
Write-Host "  Rien n'est supprime, rien n'est converti, tout reste sur"
Write-Host "  le disque. Un journal des deplacements est ecrit sur le"
Write-Host "  Bureau pour pouvoir revenir en arriere."
Write-Host ""
$c = (Read-Host "  Tapez OUI pour deplacer, autre chose pour en rester la").Trim().ToUpper()
W ""
W ("Choix : " + $c)

if (@("OUI","O","OK","Y","YES") -notcontains $c) {
  W "Aucun fichier deplace. La mesure ci-dessus reste valable."
} else {
  T "DEPLACEMENT"
  $journal = New-Object System.Collections.ArrayList
  [void]$journal.Add("source;destination")
  $ok = 0; $ko = 0; $octets = [int64]0
  $i = 0
  foreach ($f in $vids) {
    $i++
    if ($i % 20 -eq 0) { Write-Host ("   " + $i + " / " + $vids.Count) -ForegroundColor DarkGray }
    $rel = $f.DirectoryName.Substring($images.Length).TrimStart("\")
    $dossierCible = if ($rel) { Join-Path $videos $rel } else { $videos }
    if (-not (Test-Path -LiteralPath $dossierCible)) {
      New-Item -ItemType Directory -Path $dossierCible -Force -ErrorAction SilentlyContinue | Out-Null
    }
    $cible = Join-Path $dossierCible $f.Name
    # Jamais d'ecrasement : en cas d'homonyme on suffixe.
    if (Test-Path -LiteralPath $cible) {
      $b = [IO.Path]::GetFileNameWithoutExtension($f.Name)
      $e = $f.Extension
      $n = 2
      while (Test-Path -LiteralPath $cible) {
        $cible = Join-Path $dossierCible ($b + "-" + $n + $e)
        $n++
      }
    }
    try {
      $taille = $f.Length
      Move-Item -LiteralPath $f.FullName -Destination $cible -ErrorAction Stop
      [void]$journal.Add($f.FullName + ";" + $cible)
      $ok++; $octets += $taille
    } catch {
      $ko++
      W ("   echec : " + $f.FullName)
      W ("           " + $_.Exception.Message)
    }
  }
  W ""
  W ($ok.ToString() + " videos deplacees, " + (Go $octets))
  if ($ko -gt 0) { W ($ko.ToString() + " echecs, listes ci-dessus.") }

  $jf = Join-Path $bureau ("Journal-deplacement-videos-" + (Get-Date -Format "yyyy-MM-dd-HHmm") + ".csv")
  try {
    ($journal -join "`r`n") | Out-File -FilePath $jf -Encoding UTF8 -ErrorAction Stop
    W ("Journal des deplacements : " + $jf)
    W "Il contient chaque fichier avec son ancien et son nouveau"
    W "chemin, de quoi revenir en arriere si besoin."
  } catch { }

  # Etat apres
  $apres = @(Get-ChildItem -LiteralPath $images -Recurse -File -Force -ErrorAction SilentlyContinue)
  $oApres = ($apres | Measure-Object Length -Sum).Sum
  if (-not $oApres) { $oApres = 0 }
  W ""
  W ("Le dossier Images pese maintenant " + (Go $oApres) + " en " + $apres.Count + " fichiers.")
  if ($dispo) {
    if ($oApres -le $dispo) { W ("Il tient dans les " + (Go $dispo) + " libres du Drive.") }
    else { W ("Il depasse encore de " + (Go ($oApres - $dispo)) + ".") }
  }

  T "ET MAINTENANT"
  W "1. Icone Drive, roue dentee, Preferences, onglet Mon ordinateur."
  W "2. Ajouter un dossier, choisir Images."
  W "3. Cocher Synchroniser avec Google Drive."
  W "4. Laisser Importer dans Google Photos DECOCHE."
  W "5. Enregistrer."
  W ""
  W "Ne pas ajouter le dossier Videos : c'est justement ce qu'on"
  W "vient d'en sortir pour tenir dans le quota."
}

$out = Join-Path $bureau ("Separation-" + (Get-Date -Format "yyyy-MM-dd-HHmm") + ".txt")
try { ($L -join "`r`n") | Out-File -FilePath $out -Encoding UTF8 -ErrorAction Stop
      Write-Host ""
      Write-Host ("  Compte rendu : " + $out) -ForegroundColor Green } catch { }

} catch {
  Write-Host ""
  Write-Host "  ERREUR :" -ForegroundColor Red
  Write-Host ("  " + $_.Exception.Message) -ForegroundColor Red
  Write-Host ("  Ligne " + $_.InvocationInfo.ScriptLineNumber) -ForegroundColor Red
}

Write-Host ""
Write-Host "  Appuyez sur Entree pour fermer cette fenetre." -ForegroundColor Cyan
Read-Host
