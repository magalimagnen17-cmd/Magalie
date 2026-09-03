@echo off
title Recouvrement entre dossiers  -  lecture seule
setlocal
REM ==========================================================
REM  A DOUBLE-CLIQUER. Rien a taper, rien a coller.
REM  Ce fichier porte le script PowerShell a sa suite.
REM  Il l extrait dans le dossier temporaire puis l execute.
REM  Ce que fait le script est decrit en tete de celui-ci.
REM ==========================================================
set "PS1=%TEMP%\Recouvrement.ps1"
set "PWSH=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PWSH%" set "PWSH=powershell.exe"
more +25 "%~f0" > "%PS1%"
if not exist "%PS1%" goto ERR
findstr /c:"RECOUVREMENT ENTRE DOSSIERS - LECTURE SEULE" "%PS1%" >nul || goto ERR
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
#  RECOUVREMENT ENTRE DOSSIERS - LECTURE SEULE
#  Ne supprime rien, ne deplace rien.
#  Repond a une seule question, dossier par dossier :
#  qu'est-ce qui existe deja ailleurs, et surtout
#  qu'est-ce qui N'EXISTE QU'ICI et serait perdu.
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

try {

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  RECOUVREMENT ENTRE DOSSIERS" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Lecture seule. Aucun fichier ne sera touche." -ForegroundColor Yellow
Write-Host "  Comptez 5 a 15 minutes." -ForegroundColor Yellow
Write-Host ""

$bureau = CheminBureau
$out = Join-Path $bureau ("Recouvrement-" + (Get-Date -Format "yyyy-MM-dd-HHmm") + ".txt")

# Documents et Bureau sont deja synchronises dans Drive. Ce qui est
# range la est deja sauvegarde, et c'est ce qui rend la comparaison
# interessante : une photo d'Images presente aussi dans Documents est
# deja a l'abri, inutile de la renvoyer.
$reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
$racines = @(
  @("Documents",       "Personal",  $true),
  @("Bureau",          "Desktop",   $true),
  @("Images",          "My Pictures", $false),
  @("Videos",          "My Video",  $false),
  @("Musique",         "My Music",  $false),
  @("Telechargements", "{374DE290-123F-4565-9164-39C4925E467B}", $false)
)

W "=========================================================="
W "  RECOUVREMENT ENTRE DOSSIERS"
W ("  " + $env:COMPUTERNAME + " / " + $env:USERNAME + "   " + (Get-Date -Format "dd/MM/yyyy HH:mm"))
W "=========================================================="
W ""
W "Documents et Bureau sont deja synchronises dans Drive."
W "Images, Musique et Telechargements ne le sont pas."
W ""

# ---------- Collecte ----------
Write-Host "  1/4  Lecture des fichiers..." -ForegroundColor Gray
$tous = @()
foreach ($r in $racines) {
  $b = (Get-ItemProperty -Path $reg -Name $r[1] -ErrorAction SilentlyContinue).($r[1])
  if ([string]::IsNullOrEmpty($b)) { $c = Join-Path $env:USERPROFILE $r[0] } else { $c = [Environment]::ExpandEnvironmentVariables($b) }
  if (-not (Test-Path -LiteralPath $c)) { continue }
  Write-Host ("       " + $r[0] + " ...") -ForegroundColor DarkGray
  foreach ($f in @(Get-ChildItem -LiteralPath $c -Recurse -File -Force -ErrorAction SilentlyContinue)) {
    # Fichiers techniques de Drive en cours d'envoi : ce ne sont pas
    # des fichiers de l'utilisateur, ils fausseraient le comptage.
    if ($f.FullName -like "*\.tmp.driveupload\*") { continue }
    $rel = $f.DirectoryName
    if ($rel.Length -gt $c.Length) { $prem = ($rel.Substring($c.Length).TrimStart("\") -split "\\")[0] }
    else { $prem = "  (racine)" }
    $tous += New-Object PSObject -Property @{
      F = $f; Groupe = ($r[0] + "\" + $prem); Sauve = $r[2] }
  }
}
W ("Fichiers analyses : " + $tous.Count)

# ---------- Empreintes ----------
Write-Host "  2/4  Comparaison des contenus..." -ForegroundColor Gray
# Deux fichiers de tailles differentes ne peuvent pas etre identiques :
# on ne lit que ceux dont la taille se repete.
$SEUIL = 100KB
$parTaille = $tous | Where-Object { $_.F.Length -gt $SEUIL } | Group-Object { $_.F.Length }
$aHasher = @($parTaille | Where-Object { $_.Count -gt 1 })
$nb = ($aHasher | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
if (-not $nb) { $nb = 0 }
Write-Host ("       " + $nb + " fichiers a comparer") -ForegroundColor DarkGray

$hashDe = @{}
$parHash = @{}
$i = 0
foreach ($g in $aHasher) {
  foreach ($x in $g.Group) {
    $i++
    if ($i % 25 -eq 0) { Write-Host ("       " + $i + " / " + $nb) -ForegroundColor DarkGray }
    $h = (Get-FileHash -LiteralPath $x.F.FullName -Algorithm MD5 -ErrorAction SilentlyContinue).Hash
    if (-not $h) { continue }
    $hashDe[$x.F.FullName] = $h
    if (-not $parHash.ContainsKey($h)) { $parHash[$h] = @() }
    $parHash[$h] += $x
  }
}

# ---------- Analyse par dossier ----------
Write-Host "  3/4  Analyse dossier par dossier..." -ForegroundColor Gray
$stat = @{}
foreach ($x in $tous) {
  $g = $x.Groupe
  if (-not $stat.ContainsKey($g)) {
    $stat[$g] = New-Object PSObject -Property @{
      Total=[int64]0; N=0; Ailleurs=[int64]0; NA=0;
      DejaSauve=[int64]0; NDS=0; Uniques=@(); UO=[int64]0; Sauve=$x.Sauve }
  }
  $s = $stat[$g]
  $s.Total += $x.F.Length; $s.N++

  $h = $hashDe[$x.F.FullName]
  $autres = @()
  if ($h) { $autres = @($parHash[$h] | Where-Object { $_.Groupe -ne $g }) }

  if ($autres.Count -gt 0) {
    $s.Ailleurs += $x.F.Length; $s.NA++
    # Le meme contenu se trouve dans un dossier deja synchronise :
    # ce fichier est donc deja a l'abri, meme s'il est ici en double.
    if (@($autres | Where-Object { $_.Sauve }).Count -gt 0) { $s.DejaSauve += $x.F.Length; $s.NDS++ }
  } else {
    $s.Uniques += $x.F
    $s.UO += $x.F.Length
  }
}

T "RECOUVREMENT, DOSSIER PAR DOSSIER"
W "Colonnes : volume du dossier, part qui existe aussi ailleurs,"
W "part qui n'existe QUE la. Trie par volume."
W ""
W ("{0,-42} {1,10} {2,10} {3,10}" -f "Dossier", "Volume", "Ailleurs", "Unique")
W ("-" * 76)
foreach ($k in ($stat.Keys | Sort-Object { -$stat[$_].Total })) {
  $s = $stat[$k]
  if ($s.Total -lt 10MB) { continue }
  $marque = if ($s.Sauve) { " *" } else { "  " }
  W ("{0,-42} {1,10} {2,10} {3,10}" -f ($k + $marque), (Go $s.Total), (Go $s.Ailleurs), (Go $s.UO))
}
W ""
W "* = dossier deja synchronise dans Drive"

# ---------- Ce qui est deja a l'abri ----------
T "CE QUI, DANS IMAGES, EST DEJA SAUVEGARDE"
$dejaImg = [int64]0; $nImg = 0
foreach ($k in $stat.Keys) {
  if ($k -like "Images\*" -and $stat[$k].DejaSauve -gt 0) {
    $dejaImg += $stat[$k].DejaSauve; $nImg += $stat[$k].NDS
    W ("{0,-42} {1,10}   {2} fichiers" -f $k, (Go $stat[$k].DejaSauve), $stat[$k].NDS)
  }
}
W ""
if ($dejaImg -gt 0) {
  W ("Total deja a l'abri via Documents : " + (Go $dejaImg) + " en " + $nImg + " fichiers.")
  W "Ces fichiers sont dans Images ET dans un dossier deja"
  W "synchronise. Ils n'ont pas besoin d'etre renvoyes."
} else {
  W "Aucun fichier d'Images n'est deja present dans Documents."
}

# ---------- Candidats a la suppression ----------
T "DOSSIERS ENTIEREMENT REDONDANTS"
W "Un dossier dont la part unique est nulle ou minime peut etre"
W "supprime sans rien perdre. Ceux qui ont des fichiers uniques"
W "demandent d'abord de mettre ces fichiers de cote."
W ""
W "Precision : les fichiers de moins de 100 Ko ne sont pas compares"
W "et sont comptes comme uniques par precaution. Ils ne pesent rien,"
W "mais ils peuvent gonfler le nombre affiche de fichiers uniques."
W ""
$gainTotal = [int64]0
foreach ($k in ($stat.Keys | Sort-Object { -$stat[$_].Ailleurs })) {
  $s = $stat[$k]
  if ($s.Total -lt 100MB) { continue }
  $pct = if ($s.Total -gt 0) { [math]::Round($s.Ailleurs / $s.Total * 100, 0) } else { 0 }
  if ($pct -lt 50) { continue }
  W ("--- " + $k)
  W ("    " + (Go $s.Total) + " au total, " + $pct + " % existe ailleurs")
  if ($s.Uniques.Count -eq 0) {
    W "    AUCUN fichier unique : ce dossier peut partir en entier."
    $gainTotal += $s.Total
  } else {
    W ("    " + $s.Uniques.Count + " fichiers n'existent QUE la (" + (Go $s.UO) + ") :")
    foreach ($u in ($s.Uniques | Sort-Object Length -Descending | Select-Object -First 12)) {
      W ("       " + (Go $u.Length) + "  " + $u.Name)
    }
    if ($s.Uniques.Count -gt 12) { W ("       ... et " + ($s.Uniques.Count - 12) + " autres, liste complete plus bas") }
    $gainTotal += $s.Ailleurs
  }
  W ""
}
if ($gainTotal -eq 0) { W "Aucun dossier largement redondant." }
else { W ("Place liberable au total : " + (Go $gainTotal)) }

# ---------- Liste complete des uniques ----------
T "LISTE COMPLETE DES FICHIERS UNIQUES DES DOSSIERS REDONDANTS"
W "A mettre de cote avant toute suppression."
W ""
foreach ($k in ($stat.Keys | Sort-Object)) {
  $s = $stat[$k]
  if ($s.Total -lt 100MB) { continue }
  $pct = if ($s.Total -gt 0) { [math]::Round($s.Ailleurs / $s.Total * 100, 0) } else { 0 }
  if ($pct -lt 50 -or $s.Uniques.Count -eq 0) { continue }
  W ("--- " + $k + " : " + $s.Uniques.Count + " fichiers uniques")
  foreach ($u in ($s.Uniques | Sort-Object Length -Descending)) {
    W ("    " + (Go $u.Length) + "  " + $u.FullName)
  }
  W ""
}

# ---------- Simulation ----------
T "CE QU'IL RESTE VRAIMENT A SAUVEGARDER"
$img = [int64]0; $imgU = [int64]0
foreach ($k in $stat.Keys) {
  if ($k -like "Images\*") { $img += $stat[$k].Total; $imgU += ($stat[$k].Total - $stat[$k].DejaSauve) }
}
$drive = Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue |
         Where-Object { $_.VolumeName -like "*Google Drive*" } | Select-Object -First 1
W ("Images, volume brut                       : " + (Go $img))
W ("Images, en retirant ce qui est deja a l'abri : " + (Go $imgU))
if ($drive -and $drive.FreeSpace -gt 0) {
  W ("Place libre dans Drive maintenant         : " + (Go $drive.FreeSpace))
  W ("Place libre apres le menage               : " + (Go ([int64]$drive.FreeSpace + $gainTotal)))
  W ""
  if ($imgU -le ([int64]$drive.FreeSpace + $gainTotal)) {
    W "-> Apres menage, Images TIENT dans le quota gratuit."
  } else {
    W ("-> Meme apres menage, il manquerait " + (Go ($imgU - [int64]$drive.FreeSpace - $gainTotal)) + ".")
    W "   Il faudra un forfait ou un disque externe pour les videos."
  }
}
W ""
W "Ce script n'a rien supprime. La suppression se fait a la main,"
W "apres verification, et jamais avant que la sauvegarde soit faite."

$texte = $L -join "`r`n"
$ecrit = $false
foreach ($cible in @($out, (Join-Path $env:USERPROFILE "Recouvrement.txt"), (Join-Path $env:TEMP "Recouvrement.txt"))) {
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
