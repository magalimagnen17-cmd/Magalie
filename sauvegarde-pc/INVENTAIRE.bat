@echo off
title Inventaire avant sauvegarde  -  lecture seule
setlocal
REM ==========================================================
REM  A DOUBLE-CLIQUER. Rien a taper, rien a coller.
REM  Ce fichier porte le script PowerShell a sa suite.
REM  Il l extrait dans le dossier temporaire puis l execute.
REM  Aucun reglage de la machine n est modifie.
REM ==========================================================
set "PS1=%TEMP%\Inventaire-Sauvegarde.ps1"
set "PWSH=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PWSH%" set "PWSH=powershell.exe"
more +25 "%~f0" > "%PS1%"
if not exist "%PS1%" goto ERR
findstr /c:"INVENTAIRE AVANT SAUVEGARDE" "%PS1%" >nul || goto ERR
"%PWSH%" -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
if errorlevel 1 goto ERR
exit /b 0
:ERR
echo.
echo   Le lancement a echoue.
echo   Recopiez le message ci-dessus et envoyez-le.
echo.
pause
exit /b 1
# ==========================================================
#  INVENTAIRE AVANT SAUVEGARDE
#  LECTURE SEULE : ne copie rien, ne deplace rien,
#  ne supprime rien, ne modifie rien.
#  Repond a une seule question : quoi sauvegarder,
#  et est-ce que ca rentre dans Google Drive ?
# ==========================================================

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference    = "SilentlyContinue"

# ---------- Outils ----------
$L = New-Object System.Collections.ArrayList
function W($t){ [void]$L.Add([string]$t) }
function T($t){ [void]$L.Add(""); [void]$L.Add("=== $t ===") }

function Go($o){
  if ($o -eq $null) { return "?" }
  if ($o -ge 1GB) { return ("{0:N2} Go" -f ($o/1GB)) }
  if ($o -ge 1MB) { return ("{0:N0} Mo" -f ($o/1MB)) }
  return ("{0:N0} Ko" -f ($o/1KB))
}

# Le Bureau n'est pas toujours dans C:\Users\<nom>\Desktop :
# OneDrive le deplace souvent sans prevenir. On cherche le vrai.
function CheminBureau {
  $reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
  $b = (Get-ItemProperty -Path $reg -Name "Desktop" -ErrorAction SilentlyContinue).Desktop
  if ($b) { $b = [Environment]::ExpandEnvironmentVariables($b) }
  $candidats = @(
    $b,
    [Environment]::GetFolderPath("Desktop"),
    (Join-Path $env:USERPROFILE "Desktop"),
    (Join-Path $env:USERPROFILE "Bureau"),
    (Join-Path $env:USERPROFILE "OneDrive\Bureau"),
    (Join-Path $env:USERPROFILE "OneDrive\Desktop")
  )
  foreach ($c in $candidats) {
    if ($c -and (Test-Path -LiteralPath $c)) { return $c }
  }
  return $env:TEMP
}

# Mesure recursive robuste : ignore les liens de jonction,
# sinon AppData boucle sur lui-meme sur les vieux profils Windows.
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
  return New-Object PSObject -Property @{ Octets = $somme; Fichiers = $nb }
}

function Disques {
  $d = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue
  if (-not $d) { $d = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue }
  return $d
}

# ==========================================================
#  DEBUT
# ==========================================================
try {

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  INVENTAIRE AVANT SAUVEGARDE" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Rien ne sera modifie sur ce PC. Lecture seule." -ForegroundColor Yellow
Write-Host "  Comptez 2 a 10 minutes selon le nombre de fichiers." -ForegroundColor Yellow
Write-Host "  Ne fermez pas cette fenetre avant le message TERMINE." -ForegroundColor Yellow
Write-Host ""

$bureau = CheminBureau
$out    = Join-Path $bureau "Inventaire-Sauvegarde.txt"

W "=========================================================="
W "  INVENTAIRE AVANT SAUVEGARDE"
W ("  Machine    : " + $env:COMPUTERNAME + "   Session : " + $env:USERNAME)
W ("  Date       : " + (Get-Date -Format "dd/MM/yyyy HH:mm"))
W ("  PowerShell : " + $PSVersionTable.PSVersion)
W ("  Bureau     : " + $bureau)
W "=========================================================="

# ---------- 1. Disques ----------
Write-Host "  1/7  Espace disque..." -ForegroundColor Gray
T "ESPACE DISQUE"
$dsk = Disques
if ($dsk) {
  foreach ($x in $dsk) {
    W ("{0} {1,-14} Total {2,10}   Libre {3,10}" -f $x.DeviceID, $x.VolumeName, (Go $x.Size), (Go $x.FreeSpace))
  }
} else { W "Lecture des disques impossible sur cette machine." }

# ---------- 1 bis. Google Drive ----------
Write-Host "  1b/7  Google Drive..." -ForegroundColor Gray
T "GOOGLE DRIVE POUR ORDINATEUR"
$proc = Get-Process -Name "GoogleDriveFS" -ErrorAction SilentlyContinue
if ($proc) { W "Application Drive pour ordinateur : EN COURS D'EXECUTION" }
else {
  $exe = @(
    "$env:ProgramFiles\Google\Drive File Stream",
    "${env:ProgramFiles(x86)}\Google\Drive File Stream",
    "$env:LOCALAPPDATA\Google\DriveFS"
  ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
  if ($exe) { W "Application Drive installee mais PAS lancee actuellement." }
  else      { W "Application Drive pour ordinateur non detectee." }
}

# Le lecteur Drive n'a pas toujours la lettre G:. On le reconnait a son
# nom de volume, pas a sa lettre.
$lecteurs = Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue |
            Where-Object { $_.VolumeName -like "*Google Drive*" -or $_.ProviderName -like "*Google*" }
if ($lecteurs) {
  foreach ($g in $lecteurs) {
    W ("Lecteur {0}  nom '{1}'  type {2}" -f $g.DeviceID, $g.VolumeName, $g.DriveType)
    if ($g.Size -gt 0) {
      W ("   annonce {0} au total, {1} libres" -f (Go $g.Size), (Go $g.FreeSpace))
      W "   Attention : en mode streaming, ces chiffres refletent le quota"
      W "   du compte Google, pas le disque dur de la machine."
    }
    foreach ($nom in @("Mon Drive","My Drive","Drive partages","Shared drives")) {
      $c = Join-Path ($g.DeviceID + "\") $nom
      if (Test-Path -LiteralPath $c) { W ("   dossier present : " + $c) }
    }
  }
} else {
  W "Aucun lecteur Google Drive monte pour l'instant."
  W "Si l'application vient d'etre installee, il faut se connecter au"
  W "compte Google et attendre que le lecteur apparaisse dans"
  W "l'Explorateur avant de lancer la copie."
}
$ancien = Join-Path $env:USERPROFILE "Google Drive"
if (Test-Path -LiteralPath $ancien) {
  $m = Mesure $ancien
  W ("Dossier local 'Google Drive' : " + (Go $m.Octets) + "  (" + $ancien + ")")
}
W ""
W "Le quota reel du compte ne se lit pas depuis le PC. A relever sur"
W "drive.google.com, en bas a gauche : 'X Go utilises sur 15 Go'."

# ---------- 2. Dossiers personnels ----------
Write-Host "  2/7  Dossiers personnels..." -ForegroundColor Gray
T "DOSSIERS PERSONNELS (le coeur de la sauvegarde)"
$reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
$cles = New-Object System.Collections.Specialized.OrderedDictionary
$cles.Add("Bureau",          "Desktop")
$cles.Add("Documents",       "Personal")
$cles.Add("Images",          "My Pictures")
$cles.Add("Videos",          "My Video")
$cles.Add("Musique",         "My Music")
$cles.Add("Telechargements", "{374DE290-123F-4565-9164-39C4925E467B}")

$totalPerso = [int64]0
$detail = @()
foreach ($k in @($cles.Keys)) {
  Write-Host ("       mesure de " + $k + " ...") -ForegroundColor DarkGray
  $brut = (Get-ItemProperty -Path $reg -Name $cles[$k] -ErrorAction SilentlyContinue).($cles[$k])
  if ([string]::IsNullOrEmpty($brut)) { $chemin = Join-Path $env:USERPROFILE $k }
  else { $chemin = [Environment]::ExpandEnvironmentVariables($brut) }
  $m = Mesure $chemin
  if ($m -eq $null) { W ("{0,-16} introuvable  ({1})" -f $k, $chemin); continue }
  $totalPerso += $m.Octets
  $flag = ""
  if ($chemin -like "*OneDrive*") { $flag = "   [DEJA DANS ONEDRIVE]" }
  W ("{0,-16} {1,10}   {2,7} fichiers   {3}{4}" -f $k, (Go $m.Octets), $m.Fichiers, $chemin, $flag)
  $detail += New-Object PSObject -Property @{ Nom=$k; Chemin=$chemin; Octets=$m.Octets }
}
W ""
W ("TOTAL dossiers personnels : " + (Go $totalPerso))

# ---------- 3. Outlook ----------
Write-Host "  3/7  Boites mail Outlook..." -ForegroundColor Gray
T "MAILS OUTLOOK (.pst / .ost)"
$mails = @()
$zones = @(
  (Join-Path $env:USERPROFILE "Documents"),
  (Join-Path $env:LOCALAPPDATA "Microsoft\Outlook"),
  $bureau
)
foreach ($z in ($zones | Select-Object -Unique)) {
  if (Test-Path -LiteralPath $z) {
    $mails += Get-ChildItem -LiteralPath $z -Recurse -File -Force -ErrorAction SilentlyContinue |
              Where-Object { $_.Extension -eq ".pst" -or $_.Extension -eq ".ost" }
  }
}
$mails = @($mails | Sort-Object FullName -Unique)
if ($mails.Count -eq 0) {
  W "Aucun fichier .pst / .ost trouve."
  W "Soit il n'y a pas d'Outlook installe, soit les mails sont"
  W "uniquement en ligne et n'ont rien a sauvegarder ici."
} else {
  foreach ($f in $mails) {
    $type = "ARCHIVE A SAUVEGARDER"
    if ($f.Extension -eq ".ost") { $type = "cache local, inutile a sauvegarder" }
    W ("{0,10}  {1}" -f (Go $f.Length), $f.FullName)
    W ("            -> " + $type)
  }
}

# ---------- 4. Navigateurs ----------
Write-Host "  4/7  Navigateurs..." -ForegroundColor Gray
T "NAVIGATEURS ET FAVORIS"
$navs = @(
  @("Chrome", (Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Default\Bookmarks")),
  @("Edge",   (Join-Path $env:LOCALAPPDATA "Microsoft\Edge\User Data\Default\Bookmarks")),
  @("Brave",  (Join-Path $env:LOCALAPPDATA "BraveSoftware\Brave-Browser\User Data\Default\Bookmarks")),
  @("Opera",  (Join-Path $env:APPDATA "Opera Software\Opera Stable\Bookmarks"))
)
$trouve = $false
foreach ($n in $navs) {
  if (Test-Path -LiteralPath $n[1]) {
    $trouve = $true
    $d = (Get-Item -LiteralPath $n[1]).LastWriteTime
    W ("{0,-8} present    favoris modifies le {1:dd/MM/yyyy}" -f $n[0], $d)
  }
}
$ff = Get-ChildItem (Join-Path $env:APPDATA "Mozilla\Firefox\Profiles") -Directory -ErrorAction SilentlyContinue
foreach ($p in $ff) {
  if (Test-Path -LiteralPath (Join-Path $p.FullName "places.sqlite")) {
    $trouve = $true
    W ("{0,-8} present    profil {1}" -f "Firefox", $p.Name)
  }
}
if (-not $trouve) { W "Aucun profil navigateur standard detecte." }
W ""
W "Les favoris pesent quelques Mo, aucun probleme de place."
W "Les MOTS DE PASSE ne sont pas lisibles par un script, ils sont"
W "chiffres par Windows. Export a la main depuis le navigateur."

# ---------- 5. Profil complet ----------
Write-Host "  5/7  Profil complet, c'est la partie la plus longue..." -ForegroundColor Gray
T "PROFIL UTILISATEUR COMPLET"
$mp = Mesure $env:USERPROFILE
if ($mp -ne $null) {
  W ("{0} : {1}   ({2:N0} fichiers)" -f $env:USERPROFILE, (Go $mp.Octets), $mp.Fichiers)
}
$totalApp = [int64]0
foreach ($a in @(@("AppData\Local",$env:LOCALAPPDATA), @("AppData\Roaming",$env:APPDATA))) {
  $m = Mesure $a[1]
  if ($m -ne $null) { $totalApp += $m.Octets; W ("  dont {0,-16} {1,10}" -f $a[0], (Go $m.Octets)) }
}
W ""
W ("AppData represente " + (Go $totalApp) + " de reglages et de caches.")
W "C'est la partie technique du profil. Elle ne se restaure pas telle"
W "quelle sur un autre PC et elle gonfle enormement la sauvegarde."

# ---------- 6. Gros fichiers ----------
Write-Host "  6/7  Les plus gros fichiers..." -ForegroundColor Gray
T "LES 20 PLUS GROS FICHIERS DES DOSSIERS PERSONNELS"
$gros = @()
foreach ($d in $detail) {
  $gros += Get-ChildItem -LiteralPath $d.Chemin -Recurse -File -Force -ErrorAction SilentlyContinue |
           Sort-Object Length -Descending | Select-Object -First 20 |
           Select-Object Length, FullName
}
if ($gros.Count -eq 0) { W "Aucun fichier trouve." }
else {
  $gros | Sort-Object Length -Descending | Select-Object -First 20 | ForEach-Object {
    W ("{0,10}  {1}" -f (Go $_.Length), $_.FullName)
  }
}

# ---------- 7. Autres sessions ----------
Write-Host "  7/7  Autres comptes Windows..." -ForegroundColor Gray
T "AUTRES COMPTES SUR CETTE MACHINE"
Get-ChildItem "C:\Users" -Directory -Force -ErrorAction SilentlyContinue |
  Where-Object { @("Public","Default","Default User","All Users") -notcontains $_.Name } | ForEach-Object {
    $marque = ""
    if ($_.FullName -eq $env:USERPROFILE) { $marque = "   <-- session en cours" }
    W ("{0,-25} derniere activite {1:dd/MM/yyyy}{2}" -f $_.Name, $_.LastWriteTime, $marque)
  }
W ""
W "Un compte a l'activite ancienne contient souvent encore des"
W "documents. A verifier avant de reinstaller ou de donner le PC."

# ---------- 7 bis. Points bloquants pour une synchro Drive ----------
Write-Host "  7b/7  Points bloquants pour une synchronisation..." -ForegroundColor Gray
T "POINTS BLOQUANTS POUR UNE SYNCHRO GOOGLE DRIVE"
$bloquant = 0

# 1. Un dossier deja gere par OneDrive ne doit pas etre repris par Drive :
#    les deux se disputent le meme fichier et fabriquent des doublons.
$conflit = @($detail | Where-Object { $_.Chemin -like "*OneDrive*" })
if ($conflit.Count -gt 0) {
  $bloquant++
  W "[!] CONFLIT ONEDRIVE"
  foreach ($c in $conflit) { W ("    " + $c.Nom + " est deja synchronise par OneDrive : " + $c.Chemin) }
  W "    Ne pas ajouter ces dossiers a la sauvegarde Google Drive."
  W "    Deux synchronisations sur le meme dossier produisent des"
  W "    doublons du type 'fichier (2).docx' et des conflits sans fin."
  W "    Choisir l'un des deux services pour ces dossiers, pas les deux."
} else {
  W "[ok] Aucun dossier personnel n'est gere par OneDrive."
}
W ""

# 2. Un fichier ouvert en exclusivite ne sera jamais copie proprement.
#    Le cas classique : la boite Outlook, verrouillee tant qu'Outlook tourne.
$verrous = @()
foreach ($f in $mails) {
  try {
    $h = [IO.File]::Open($f.FullName, "Open", "Read", "None")
    $h.Close()
  } catch { $verrous += $f }
}
if ($verrous.Count -gt 0) {
  $bloquant++
  W "[!] FICHIERS VERROUILLES PAR UN LOGICIEL OUVERT"
  foreach ($v in $verrous) { W ("    " + $v.FullName) }
  W "    Fermer Outlook avant toute sauvegarde de ces fichiers."
  W "    Un .pst se compte en Go et change a chaque mail recu : laisse"
  W "    en synchronisation continue, il est renvoye en entier bien"
  W "    trop souvent. A sauvegarder a part, Outlook ferme, pas en"
  W "    synchro permanente."
} else {
  W "[ok] Aucun fichier mail verrouille a l'instant."
}
W ""

# 3. Chemins trop longs et fichiers tres gros : les deux causes
#    d'echec silencieux les plus frequentes lors d'une premiere synchro.
$longs = @()
$enormes = @()
foreach ($d in $detail) {
  Get-ChildItem -LiteralPath $d.Chemin -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.FullName.Length -gt 250) { $longs += $_.FullName }
    if ($_.Length -gt 2GB) { $enormes += $_ }
  }
}
if ($longs.Count -gt 0) {
  $bloquant++
  W ("[!] " + $longs.Count + " FICHIERS AU CHEMIN TROP LONG (plus de 250 caracteres)")
  $longs | Select-Object -First 5 | ForEach-Object { W ("    " + $_) }
  if ($longs.Count -gt 5) { W ("    ... et " + ($longs.Count - 5) + " autres") }
  W "    Ils echouent souvent sans message. Raccourcir les noms de"
  W "    dossiers avant de lancer la synchronisation."
} else {
  W "[ok] Aucun chemin excessivement long."
}
W ""
if ($enormes.Count -gt 0) {
  W ("[i] " + $enormes.Count + " fichiers de plus de 2 Go :")
  $enormes | Sort-Object Length -Descending | Select-Object -First 5 | ForEach-Object {
    W ("    {0,10}  {1}" -f (Go $_.Length), $_.FullName)
  }
  W "    Ils passeront, mais ils monopoliseront la connexion. Les"
  W "    envoyer en dernier, ou par le disque externe."
} else {
  W "[ok] Aucun fichier de plus de 2 Go."
}
W ""
if ($bloquant -eq 0) { W "Aucun point bloquant. La synchronisation peut etre configuree." }
else { W ("A regler avant de lancer : " + $bloquant + " point(s) ci-dessus.") }

# ---------- 8. Verdict ----------
T "VERDICT"
$utile = $totalPerso
foreach ($f in $mails) { if ($f.Extension -eq ".pst") { $utile += $f.Length } }
W ("Sauvegarde utile, dossiers personnels + archives mail : " + (Go $utile))
if ($mp -ne $null) { W ("Sauvegarde integrale du profil, AppData compris       : " + (Go $mp.Octets)) }
W ""
W "Repere : un compte Google gratuit offre 15 Go partages entre"
W "Drive, Gmail et Google Photos. La place reellement libre est donc"
W "toujours inferieure a 15 Go. A verifier sur drive.google.com,"
W "en bas a gauche de la page."
W ""
if ($utile -lt 10GB) {
  W "-> Le volume utile tient dans un Drive gratuit. Sauvegarde simple."
} elseif ($utile -lt 100GB) {
  W "-> Trop gros pour un Drive gratuit tel quel. Trois voies :"
  W "   trier et n'envoyer que l'essentiel, prendre 200 Go de"
  W "   stockage Google pour environ 2 euros par mois, ou passer"
  W "   par un disque dur externe."
} else {
  W "-> Volume important. Le disque dur externe est la bonne solution."
  W "   Drive servira pour les documents seulement."
}
W ""
W "--- Duree de la premiere synchronisation ---"
W "Ce qui coince rarement, c'est la place. Ce qui coince toujours,"
W "c'est le debit MONTANT, souvent dix fois plus faible que le"
W "descendant sur une ligne domestique."
foreach ($d in @(1, 5, 20)) {
  $heures = ($utile * 8) / ($d * 1000000) / 3600
  if ($heures -lt 1) { $t = ("{0:N0} minutes" -f ($heures*60)) }
  elseif ($heures -lt 48) { $t = ("{0:N0} heures" -f $heures) }
  else { $t = ("{0:N1} jours" -f ($heures/24)) }
  W ("   a {0,2} Mbit/s en montee : {1}" -f $d, $t)
}
W "Sur plusieurs jours, laisser le PC allume et brancher la veille"
W "sur Jamais, sinon la synchronisation s'arrete a chaque mise en"
W "veille et repart au ralenti."
W ""
W "Prochaine etape : envoyer ce rapport, on decide ensuite quoi"
W "sauvegarder et par quel moyen."

# ---------- Sortie ----------
$texte = $L -join "`r`n"
$ecrit = $false
foreach ($cible in @($out, (Join-Path $env:USERPROFILE "Inventaire-Sauvegarde.txt"), (Join-Path $env:TEMP "Inventaire-Sauvegarde.txt"))) {
  if ($ecrit) { break }
  try {
    $texte | Out-File -FilePath $cible -Encoding UTF8 -ErrorAction Stop
    $out = $cible; $ecrit = $true
  } catch { }
}

Write-Host ""
if ($ecrit) {
  Write-Host "  TERMINE." -ForegroundColor Green
  Write-Host ("  Rapport : " + $out) -ForegroundColor Green
  Write-Host ""
  Start-Process notepad.exe -ArgumentList "`"$out`"" -ErrorAction SilentlyContinue
} else {
  Write-Host "  Impossible d'ecrire le fichier. Voici le rapport a l'ecran :" -ForegroundColor Red
  Write-Host ""
  $texte | Write-Host
}

} catch {
  Write-Host ""
  Write-Host "  ERREUR PENDANT L'INVENTAIRE :" -ForegroundColor Red
  Write-Host ("  " + $_.Exception.Message) -ForegroundColor Red
  Write-Host ("  Ligne " + $_.InvocationInfo.ScriptLineNumber) -ForegroundColor Red
  Write-Host ""
  Write-Host "  Recopiez ces lignes rouges et envoyez-les." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  Appuyez sur Entree pour fermer cette fenetre." -ForegroundColor Cyan
Read-Host
