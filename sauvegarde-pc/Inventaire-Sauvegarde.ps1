# ==========================================================
#  INVENTAIRE AVANT SAUVEGARDE
#  LECTURE SEULE : ce script ne copie, ne deplace,
#  ne supprime et ne modifie strictement rien.
#  Il repond a une seule question : quoi sauvegarder,
#  et est-ce que ca rentre dans Google Drive ?
# ==========================================================

$ErrorActionPreference = "SilentlyContinue"
$out = "$env:USERPROFILE\Desktop\Inventaire-Sauvegarde.txt"
$L   = New-Object System.Collections.ArrayList
function W($t){ [void]$L.Add($t) }
function T($t){ [void]$L.Add(""); [void]$L.Add("=== $t ==="); }

function Go($o){
  if ($o -eq $null) { return "?" }
  if ($o -ge 1GB) { return ("{0:N2} Go" -f ($o/1GB)) }
  if ($o -ge 1MB) { return ("{0:N0} Mo" -f ($o/1MB)) }
  return ("{0:N0} Ko" -f ($o/1KB))
}

# Mesure recursive robuste : ignore les liens de jonction
# (sinon AppData boucle sur lui-meme sur les vieux profils Windows)
function Mesure($chemin){
  if (-not (Test-Path -LiteralPath $chemin)) { return $null }
  $somme = [int64]0; $nb = 0
  $pile = New-Object System.Collections.Stack
  $pile.Push($chemin)
  while ($pile.Count -gt 0) {
    $d = $pile.Pop()
    try { $items = Get-ChildItem -LiteralPath $d -Force -ErrorAction Stop } catch { continue }
    foreach ($i in $items) {
      if ($i.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
      if ($i.PSIsContainer) { $pile.Push($i.FullName) }
      else { $somme += $i.Length; $nb++ }
    }
  }
  return [pscustomobject]@{ Octets = $somme; Fichiers = $nb }
}

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  INVENTAIRE AVANT SAUVEGARDE" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Rien ne sera modifie sur ce PC. Lecture seule." -ForegroundColor Yellow
Write-Host "Comptez 2 a 10 minutes selon le nombre de fichiers." -ForegroundColor Yellow
Write-Host ""

W "=========================================================="
W "  INVENTAIRE AVANT SAUVEGARDE"
W ("  Machine : " + $env:COMPUTERNAME + "   Session : " + $env:USERNAME)
W ("  Date    : " + (Get-Date -Format "dd/MM/yyyy HH:mm"))
W "=========================================================="

# ---------- 1. Disques ----------
T "ESPACE DISQUE"
Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3 or DriveType=2" | ForEach-Object {
  W ("{0} {1,-12} Total {2,10}  Libre {3,10}" -f $_.DeviceID, $_.VolumeName, (Go $_.Size), (Go $_.FreeSpace))
}

# ---------- 2. Dossiers personnels ----------
Write-Host "1/6  Mesure des dossiers personnels..." -ForegroundColor Gray
T "DOSSIERS PERSONNELS (le coeur de la sauvegarde)"

# On lit les vrais chemins dans le registre : ils peuvent avoir ete
# rediriges vers OneDrive sans que personne ne s'en apercoive.
$reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
$cles = [ordered]@{
  "Bureau"         = "Desktop"
  "Documents"      = "Personal"
  "Images"         = "My Pictures"
  "Videos"         = "My Video"
  "Musique"        = "My Music"
  "Telechargements"= "{374DE290-123F-4565-9164-39C4925E467B}"
}
$totalPerso = [int64]0
$detail = @()
foreach ($k in $cles.Keys) {
  $brut = (Get-ItemProperty -Path $reg -Name $cles[$k] -ErrorAction SilentlyContinue).($cles[$k])
  if ([string]::IsNullOrWhiteSpace($brut)) { $chemin = Join-Path $env:USERPROFILE $k }
  else { $chemin = [Environment]::ExpandEnvironmentVariables($brut) }
  $m = Mesure $chemin
  if ($m -eq $null) { W ("{0,-16} introuvable" -f $k); continue }
  $totalPerso += $m.Octets
  $flag = ""
  if ($chemin -like "*OneDrive*") { $flag = "  [deja dans OneDrive]" }
  W ("{0,-16} {1,10}   {2,7} fichiers   {3}{4}" -f $k, (Go $m.Octets), $m.Fichiers, $chemin, $flag)
  $detail += [pscustomobject]@{ Nom=$k; Chemin=$chemin; Octets=$m.Octets }
}
W ""
W ("TOTAL dossiers personnels : " + (Go $totalPerso))

# ---------- 3. Outlook ----------
Write-Host "2/6  Recherche des boites mail Outlook..." -ForegroundColor Gray
T "MAILS OUTLOOK (.pst / .ost)"
$mails = @()
$zones = @(
  (Join-Path $env:USERPROFILE "Documents\Fichiers Outlook"),
  (Join-Path $env:USERPROFILE "Documents\Outlook Files"),
  (Join-Path $env:LOCALAPPDATA "Microsoft\Outlook"),
  (Join-Path $env:USERPROFILE "Documents"),
  (Join-Path $env:USERPROFILE "Desktop")
)
foreach ($z in $zones | Select-Object -Unique) {
  if (Test-Path -LiteralPath $z) {
    $mails += Get-ChildItem -LiteralPath $z -Recurse -File -Force -ErrorAction SilentlyContinue |
              Where-Object { $_.Extension -eq ".pst" -or $_.Extension -eq ".ost" }
  }
}
$mails = @($mails | Sort-Object FullName -Unique)
$totalMail = [int64]0
if ($mails.Count -eq 0) {
  W "Aucun fichier .pst / .ost trouve."
  W "Soit il n'y a pas d'Outlook installe, soit les mails sont"
  W "uniquement en ligne (webmail) et n'ont rien a sauvegarder ici."
} else {
  foreach ($f in $mails) {
    $totalMail += $f.Length
    $type = "ARCHIVE A SAUVEGARDER"
    if ($f.Extension -eq ".ost") { $type = "cache local, inutile a sauvegarder" }
    W ("{0,10}  {1}" -f (Go $f.Length), $f.FullName)
    W ("            -> " + $type)
  }
  W ""
  W ("TOTAL fichiers mail : " + (Go $totalMail))
}

# ---------- 4. Navigateurs ----------
Write-Host "3/6  Detection des navigateurs..." -ForegroundColor Gray
T "NAVIGATEURS ET FAVORIS"
$navs = @(
  @{ Nom="Chrome"; Fav=(Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Default\Bookmarks") },
  @{ Nom="Edge";   Fav=(Join-Path $env:LOCALAPPDATA "Microsoft\Edge\User Data\Default\Bookmarks") },
  @{ Nom="Brave";  Fav=(Join-Path $env:LOCALAPPDATA "BraveSoftware\Brave-Browser\User Data\Default\Bookmarks") },
  @{ Nom="Opera";  Fav=(Join-Path $env:APPDATA "Opera Software\Opera Stable\Bookmarks") }
)
$trouve = $false
foreach ($n in $navs) {
  if (Test-Path -LiteralPath $n.Fav) {
    $trouve = $true
    $d = (Get-Item -LiteralPath $n.Fav).LastWriteTime
    W ("{0,-8} present   favoris modifies le {1:dd/MM/yyyy}" -f $n.Nom, $d)
  }
}
$ff = Get-ChildItem (Join-Path $env:APPDATA "Mozilla\Firefox\Profiles") -Directory -ErrorAction SilentlyContinue
foreach ($p in $ff) {
  if (Test-Path -LiteralPath (Join-Path $p.FullName "places.sqlite")) {
    $trouve = $true
    W ("{0,-8} present   profil {1}" -f "Firefox", $p.Name)
  }
}
if (-not $trouve) { W "Aucun profil navigateur standard detecte." }
W ""
W "Les favoris pesent quelques Mo, ils ne posent aucun probleme de place."
W "Les MOTS DE PASSE ne sont pas lisibles par un script : ils sont"
W "chiffres par Windows. Ils s'exportent a la main depuis le"
W "navigateur, la procedure est dans le mode d'emploi."

# ---------- 5. Profil complet ----------
Write-Host "4/6  Mesure du profil complet (le plus long)..." -ForegroundColor Gray
T "PROFIL UTILISATEUR COMPLET"
$mp = Mesure $env:USERPROFILE
if ($mp -ne $null) {
  W ("{0} : {1}   ({2:N0} fichiers)" -f $env:USERPROFILE, (Go $mp.Octets), $mp.Fichiers)
}
$appd = @(
  @{ N="AppData\Local";   P=$env:LOCALAPPDATA },
  @{ N="AppData\Roaming"; P=$env:APPDATA }
)
$totalApp = [int64]0
foreach ($a in $appd) {
  $m = Mesure $a.P
  if ($m -ne $null) { $totalApp += $m.Octets; W ("  dont {0,-16} {1,10}" -f $a.N, (Go $m.Octets)) }
}
W ""
W ("AppData represente " + (Go $totalApp) + " de reglages et de caches d'applications.")
W "C'est la partie technique du profil. Elle ne se restaure pas telle"
W "quelle sur un autre PC et elle gonfle enormement la sauvegarde."

# ---------- 6. Gros fichiers ----------
Write-Host "5/6  Recherche des plus gros fichiers..." -ForegroundColor Gray
T "LES 20 PLUS GROS FICHIERS DU PROFIL"
$gros = @()
foreach ($d in $detail) {
  $gros += Get-ChildItem -LiteralPath $d.Chemin -Recurse -File -Force -ErrorAction SilentlyContinue |
           Sort-Object Length -Descending | Select-Object -First 20 |
           Select-Object Length, FullName
}
if ($gros.Count -eq 0) {
  W "Aucun fichier trouve dans les dossiers personnels."
} else {
  $gros | Sort-Object Length -Descending | Select-Object -First 20 | ForEach-Object {
    W ("{0,10}  {1}" -f (Go $_.Length), $_.FullName)
  }
}

# ---------- 7. Autres sessions ----------
Write-Host "6/6  Verification des autres comptes..." -ForegroundColor Gray
T "AUTRES COMPTES SUR CETTE MACHINE"
Get-ChildItem "C:\Users" -Directory -Force -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -notin @("Public","Default","Default User","All Users") } | ForEach-Object {
    $marque = ""
    if ($_.FullName -eq $env:USERPROFILE) { $marque = "  <-- session en cours" }
    W ("{0,-25} derniere activite {1:dd/MM/yyyy}{2}" -f $_.Name, $_.LastWriteTime, $marque)
  }
W ""
W "Un compte a la derniere activite ancienne contient souvent encore"
W "des documents. A verifier avant de reinstaller ou de donner le PC."

# ---------- 8. Verdict ----------
T "VERDICT"
$utile = $totalPerso
foreach ($f in $mails) { if ($f.Extension -eq ".pst") { $utile += $f.Length } }
W ("Sauvegarde utile (dossiers personnels + archives mail) : " + (Go $utile))
if ($mp -ne $null) { W ("Sauvegarde integrale du profil, AppData compris       : " + (Go $mp.Octets)) }
W ""
W "Repere : un compte Google gratuit offre 15 Go, partages entre"
W "Drive, Gmail et Google Photos. La place reellement libre est donc"
W "toujours inferieure a 15 Go. A verifier sur drive.google.com,"
W "en bas a gauche de la page."
W ""
if ($utile -lt 10GB) {
  W "-> Le volume utile tient dans un Drive gratuit. Sauvegarde simple."
} elseif ($utile -lt 100GB) {
  W "-> Trop gros pour un Drive gratuit tel quel. Deux voies :"
  W "   soit on trie et on envoie l'essentiel, soit on prend"
  W "   200 Go de stockage Google (environ 2 euros par mois),"
  W "   soit on passe par un disque dur externe."
} else {
  W "-> Volume important. Le disque dur externe est la bonne solution,"
  W "   Drive servira pour les documents seulement."
}
W ""
W "Prochaine etape : envoyer ce rapport, on decide ensuite quoi"
W "sauvegarder et par quel moyen."

# ---------- Sortie ----------
$L -join "`r`n" | Out-File -FilePath $out -Encoding UTF8
Write-Host ""
Write-Host "  TERMINE." -ForegroundColor Green
Write-Host "  Rapport : $out" -ForegroundColor Green
Write-Host ""
notepad $out
