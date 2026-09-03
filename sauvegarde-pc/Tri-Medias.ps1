# ==========================================================
#  TRI ET DOUBLONS - LECTURE SEULE
#  Ne supprime rien, ne deplace rien, ne renomme rien.
#  Repond a une seule question : comment faire tenir la
#  sauvegarde dans la place disponible, sans rien perdre.
# ==========================================================

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference    = "SilentlyContinue"

$L = New-Object System.Collections.ArrayList
function W($t){ [void]$L.Add([string]$t) }
function T($t){ [void]$L.Add(""); [void]$L.Add("=== $t ===") }
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

# Categories par extension. Le classement decide de ce qui part
# dans Drive et de ce qui part sur un disque externe.
$PHOTO = @(".jpg",".jpeg",".png",".heic",".heif",".gif",".bmp",".tif",".tiff",".webp",".raw",".cr2",".nef",".dng",".arw")
$VIDEO = @(".mov",".mp4",".avi",".mkv",".m4v",".3gp",".mpg",".mpeg",".wmv",".mts",".m2ts",".flv")
$DOC   = @(".pdf",".doc",".docx",".xls",".xlsx",".ppt",".pptx",".odt",".ods",".odp",".txt",".rtf",".csv",".pub",".one")
$INST  = @(".exe",".msi",".zip",".rar",".7z",".iso",".cab",".dmg",".appx",".msu")
$SON   = @(".mp3",".wav",".m4a",".flac",".aac",".wma",".ogg")

function Categorie($ext){
  $e = $ext.ToLower()
  if ($PHOTO -contains $e) { return "Photos" }
  if ($VIDEO -contains $e) { return "Videos" }
  if ($DOC   -contains $e) { return "Documents bureautique" }
  if ($INST  -contains $e) { return "Installeurs et archives" }
  if ($SON   -contains $e) { return "Musique et sons" }
  return "Autres"
}

try {

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  TRI ET DOUBLONS" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Lecture seule. Aucun fichier ne sera touche." -ForegroundColor Yellow
Write-Host "  Comptez 5 a 15 minutes : la recherche de doublons lit" -ForegroundColor Yellow
Write-Host "  le contenu des fichiers de meme taille." -ForegroundColor Yellow
Write-Host ""

$bureau = CheminBureau
$out    = Join-Path $bureau ("Tri-Medias-" + (Get-Date -Format "yyyy-MM-dd-HHmm") + ".txt")

$reg  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
$cles = @(
  @("Bureau","Desktop"), @("Documents","Personal"), @("Images","My Pictures"),
  @("Videos","My Video"), @("Musique","My Music"),
  @("Telechargements","{374DE290-123F-4565-9164-39C4925E467B}")
)

W "=========================================================="
W "  TRI ET DOUBLONS"
W ("  " + $env:COMPUTERNAME + " / " + $env:USERNAME + "   " + (Get-Date -Format "dd/MM/yyyy HH:mm"))
W "=========================================================="

# ---------- Collecte ----------
Write-Host "  1/5  Lecture des dossiers..." -ForegroundColor Gray
$tous = @()
$racines = @()
foreach ($e in $cles) {
  $b = (Get-ItemProperty -Path $reg -Name $e[1] -ErrorAction SilentlyContinue).($e[1])
  if ([string]::IsNullOrEmpty($b)) { $c = Join-Path $env:USERPROFILE $e[0] }
  else { $c = [Environment]::ExpandEnvironmentVariables($b) }
  if (-not (Test-Path -LiteralPath $c)) { continue }
  Write-Host ("       " + $e[0] + " ...") -ForegroundColor DarkGray
  $f = @(Get-ChildItem -LiteralPath $c -Recurse -File -Force -ErrorAction SilentlyContinue)
  $racines += New-Object PSObject -Property @{ Nom=$e[0]; Chemin=$c; Fichiers=$f }
  $tous += $f
}
$totalTout = ($tous | Measure-Object -Property Length -Sum).Sum
W ""
W ("Total mesure : " + (Go $totalTout) + " en " + $tous.Count + " fichiers")

# ---------- 1. Par categorie ----------
Write-Host "  2/5  Repartition par type de fichier..." -ForegroundColor Gray
T "CE QUI PESE, PAR TYPE DE FICHIER"
$parCat = @{}
foreach ($f in $tous) {
  $c = Categorie $f.Extension
  if (-not $parCat.ContainsKey($c)) { $parCat[$c] = New-Object PSObject -Property @{ O=[int64]0; N=0 } }
  $parCat[$c].O += $f.Length
  $parCat[$c].N++
}
$catTriees = $parCat.GetEnumerator() | Sort-Object { $_.Value.O } -Descending
foreach ($c in $catTriees) {
  $pct = if ($totalTout -gt 0) { [math]::Round($c.Value.O / $totalTout * 100, 0) } else { 0 }
  W ("{0,-24} {1,10}   {2,6} fichiers   {3,3} %" -f $c.Key, (Go $c.Value.O), $c.Value.N, $pct)
}

# ---------- 2. Par dossier ----------
Write-Host "  3/5  Repartition par sous-dossier..." -ForegroundColor Gray
T "LES 20 SOUS-DOSSIERS LES PLUS LOURDS"
$parDossier = @{}
foreach ($r in $racines) {
  foreach ($f in $r.Fichiers) {
    $rel = $f.DirectoryName
    if ($rel.Length -gt $r.Chemin.Length) {
      $reste = $rel.Substring($r.Chemin.Length).TrimStart("\")
      $prem = ($reste -split "\\")[0]
      $cle = $r.Nom + "\" + $prem
    } else { $cle = $r.Nom + "\  (racine)" }
    if (-not $parDossier.ContainsKey($cle)) { $parDossier[$cle] = New-Object PSObject -Property @{ O=[int64]0; N=0 } }
    $parDossier[$cle].O += $f.Length
    $parDossier[$cle].N++
  }
}
$parDossier.GetEnumerator() | Sort-Object { $_.Value.O } -Descending | Select-Object -First 20 | ForEach-Object {
  W ("{0,10}   {1,6} fichiers   {2}" -f (Go $_.Value.O), $_.Value.N, $_.Key)
}

# ---------- 3. Doublons ----------
Write-Host "  4/5  Recherche des doublons..." -ForegroundColor Gray
T "DOUBLONS : DES FICHIERS IDENTIQUES A PLUSIEURS ENDROITS"
W "Methode : on ne compare le contenu que des fichiers qui ont"
W "exactement la meme taille. Deux fichiers de taille differente"
W "ne peuvent pas etre identiques, inutile de les lire."
W ""
# Seuls les fichiers de plus de 100 Ko valent la peine : en dessous,
# le gain ne justifie pas le temps de lecture.
$candidats = $tous | Where-Object { $_.Length -gt 100KB } |
             Group-Object Length | Where-Object { $_.Count -gt 1 }
$nbCand = ($candidats | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
if (-not $nbCand) { $nbCand = 0 }
Write-Host ("       " + $nbCand + " fichiers a comparer...") -ForegroundColor DarkGray

$parHash = @{}
$i = 0
foreach ($g in $candidats) {
  foreach ($f in $g.Group) {
    $i++
    if ($i % 25 -eq 0) { Write-Host ("       " + $i + " / " + $nbCand) -ForegroundColor DarkGray }
    $h = (Get-FileHash -LiteralPath $f.FullName -Algorithm MD5 -ErrorAction SilentlyContinue).Hash
    if (-not $h) { continue }
    if (-not $parHash.ContainsKey($h)) { $parHash[$h] = @() }
    $parHash[$h] += $f
  }
}

$recuperable = [int64]0
$groupesDoublons = @()
foreach ($k in $parHash.Keys) {
  $g = $parHash[$k]
  if ($g.Count -gt 1) {
    $gain = $g[0].Length * ($g.Count - 1)
    $recuperable += $gain
    $groupesDoublons += New-Object PSObject -Property @{ Gain=$gain; Fichiers=$g }
  }
}

if ($groupesDoublons.Count -eq 0) {
  W "Aucun doublon trouve au-dessus de 100 Ko."
} else {
  W ("{0} groupes de fichiers identiques." -f $groupesDoublons.Count)
  W ("PLACE RECUPERABLE SANS RIEN PERDRE : " + (Go $recuperable))
  W ""
  W "Les 15 groupes les plus lourds. Le premier de chaque groupe est"
  W "a garder, les suivants sont des copies du meme contenu :"
  W ""
  foreach ($g in ($groupesDoublons | Sort-Object Gain -Descending | Select-Object -First 15)) {
    W ("--- " + (Go $g.Fichiers[0].Length) + " x " + $g.Fichiers.Count + " exemplaires, gain " + (Go $g.Gain))
    foreach ($f in $g.Fichiers) { W ("      " + $f.FullName) }
  }
  if ($groupesDoublons.Count -gt 15) {
    W ("... et " + ($groupesDoublons.Count - 15) + " autres groupes.")
  }
}

# ---------- 4. Simulation ----------
Write-Host "  5/5  Simulation..." -ForegroundColor Gray
T "SIMULATION : QU'EST-CE QUI TIENT DANS LE DRIVE ?"

$drive = Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue |
         Where-Object { $_.VolumeName -like "*Google Drive*" } | Select-Object -First 1
$dispo = $null
if ($drive -and $drive.FreeSpace -gt 0) { $dispo = [int64]$drive.FreeSpace }

$oVideo = if ($parCat.ContainsKey("Videos")) { $parCat["Videos"].O } else { [int64]0 }
$oInst  = if ($parCat.ContainsKey("Installeurs et archives")) { $parCat["Installeurs et archives"].O } else { [int64]0 }

W ("Tout, tel quel                        : " + (Go $totalTout))
W ("Sans les installeurs et archives      : " + (Go ($totalTout - $oInst)))
W ("Sans installeurs ni doublons          : " + (Go ($totalTout - $oInst - $recuperable)))
W ("Sans installeurs, doublons ni videos  : " + (Go ($totalTout - $oInst - $recuperable - $oVideo)))
W ""
if ($dispo) {
  W ("Place libre annoncee par le lecteur Drive : " + (Go $dispo))
  W ""
  $scenarios = @(
    @("Tout, tel quel",                       $totalTout),
    @("Sans installeurs et archives",         ($totalTout - $oInst)),
    @("Sans installeurs ni doublons",         ($totalTout - $oInst - $recuperable)),
    @("Sans installeurs, doublons ni videos", ($totalTout - $oInst - $recuperable - $oVideo))
  )
  foreach ($s in $scenarios) {
    $verdict = if ($s[1] -le $dispo) { "TIENT" } else { "ne tient pas, il manque " + (Go ($s[1] - $dispo)) }
    W ("{0,-38} {1,10}   {2}" -f $s[0], (Go $s[1]), $verdict)
  }
} else {
  W "Lecteur Google Drive non detecte, comparaison impossible."
}
W ""
W "Rappel : ce script n'a rien supprime. Il dit ce qu'il y a."
W "La suppression, s'il y en a une, se fait a la main, apres"
W "verification, et jamais avant que la sauvegarde soit faite."

# ---------- Sortie ----------
$texte = $L -join "`r`n"
$ecrit = $false
foreach ($cible in @($out, (Join-Path $env:USERPROFILE ("Tri-Medias.txt")), (Join-Path $env:TEMP "Tri-Medias.txt"))) {
  if ($ecrit) { break }
  try { $texte | Out-File -FilePath $cible -Encoding UTF8 -ErrorAction Stop; $out = $cible; $ecrit = $true } catch { }
}
Write-Host ""
if ($ecrit) {
  Write-Host "  TERMINE." -ForegroundColor Green
  Write-Host ("  Rapport : " + $out) -ForegroundColor Green
  Start-Process notepad.exe -ArgumentList "`"$out`"" -ErrorAction SilentlyContinue
} else {
  Write-Host "  Impossible d'ecrire le fichier. Rapport a l'ecran :" -ForegroundColor Red
  $texte | Write-Host
}

} catch {
  Write-Host ""
  Write-Host "  ERREUR :" -ForegroundColor Red
  Write-Host ("  " + $_.Exception.Message) -ForegroundColor Red
  Write-Host ("  Ligne " + $_.InvocationInfo.ScriptLineNumber) -ForegroundColor Red
}

Write-Host ""
Write-Host "  Appuyez sur Entree pour fermer cette fenetre." -ForegroundColor Cyan
Read-Host
