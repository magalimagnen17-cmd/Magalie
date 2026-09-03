@echo off
title Diagnostic PC  -  lecture seule
setlocal
REM ==========================================================
REM  A DOUBLE-CLIQUER. Rien a taper, rien a coller.
REM  Ce fichier porte le script PowerShell a sa suite.
REM  Il l extrait dans le dossier temporaire puis l execute.
REM  Aucun reglage de la machine n est modifie.
REM ==========================================================
net session >nul 2>&1
if not errorlevel 1 goto ADMIN
echo.
echo   Ce test a besoin des droits administrateur.
echo   Repondez Oui a la fenetre bleue de Windows.
echo.
powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
exit /b 0
:ADMIN
set "PS1=%TEMP%\Diagnostic-PC.ps1"
set "PWSH=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PWSH%" set "PWSH=powershell.exe"
more +34 "%~f0" > "%PS1%"
if not exist "%PS1%" goto ERR
findstr /c:"DIAGNOSTIC PC - LECTURE SEULE" "%PS1%" >nul || goto ERR
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
# ============================================================
#  DIAGNOSTIC PC - LECTURE SEULE
#  Ce script ne modifie RIEN. Il lit la machine et ecrit un
#  rapport horodate sur le Bureau. L'ancien rapport n'est
#  jamais ecrase : on veut pouvoir comparer avant / apres.
# ============================================================

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference    = "SilentlyContinue"

$R = New-Object System.Collections.ArrayList
$S = New-Object System.Collections.ArrayList
function W($t) { [void]$R.Add([string]$t) }
function Y($t) { [void]$S.Add([string]$t) }

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
  foreach ($c in $candidats) { if ($c -and (Test-Path -LiteralPath $c)) { return $c } }
  return $env:TEMP
}

try {

Clear-Host
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  DIAGNOSTIC PC" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Lecture seule. Rien ne sera modifie." -ForegroundColor Yellow
Write-Host "  Comptez 1 a 3 minutes." -ForegroundColor Yellow
Write-Host ""

$bureau = CheminBureau
$stamp  = Get-Date -Format "yyyy-MM-dd-HHmm"
$out    = Join-Path $bureau ("Diagnostic-PC-" + $stamp + ".txt")

$adm = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
       ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

W "=========================================="
W " RAPPORT DE DIAGNOSTIC PC"
W " Genere le $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
W (" Mode administrateur : " + $(if ($adm) { "oui" } else { "non, certaines lignes seront incompletes" }))
W "=========================================="
W ""

# --- 1. SYSTEME -------------------------------------------
Write-Host "  1/12  Systeme..." -ForegroundColor Gray
W "--- 1. SYSTEME ---"
$os   = Get-CimInstance Win32_OperatingSystem
$cs   = Get-CimInstance Win32_ComputerSystem
$bios = Get-CimInstance Win32_BIOS
W "Windows          : $($os.Caption) $($os.OSArchitecture)"
W "Version / build  : $((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').DisplayVersion) / $($os.BuildNumber)"
W "Installe le      : $($os.InstallDate)"
W "Fabricant        : $($cs.Manufacturer)"
W "Modele           : $($cs.Model)"
W "BIOS date        : $($bios.ReleaseDate)"
$up = (Get-Date) - $os.LastBootUpTime
$upj = [math]::Round($up.TotalDays,1)
W "Allume depuis    : $upj jours ($([math]::Round($up.TotalHours,1)) h)"
W ""
Y ("Allume depuis                 : " + $upj + " jours")

# --- 2. PROCESSEUR ----------------------------------------
Write-Host "  2/12  Processeur..." -ForegroundColor Gray
W "--- 2. PROCESSEUR ---"
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
W "CPU              : $($cpu.Name.Trim())"
W "Coeurs / threads : $($cpu.NumberOfCores) / $($cpu.NumberOfLogicalProcessors)"
W "Frequence base   : $($cpu.MaxClockSpeed) MHz"
W "Charge actuelle  : $($cpu.LoadPercentage) %"
W ""
Y ("Charge CPU a l instant        : " + $cpu.LoadPercentage + " %")

# --- 3. MEMOIRE -------------------------------------------
Write-Host "  3/12  Memoire..." -ForegroundColor Gray
W "--- 3. MEMOIRE VIVE (RAM) ---"
$totGB   = [math]::Round($cs.TotalPhysicalMemory/1GB,1)
$freeGB  = [math]::Round($os.FreePhysicalMemory/1MB,1)
$usedPct = [math]::Round(100 - ($os.FreePhysicalMemory/$os.TotalVisibleMemorySize*100),0)
W "RAM totale       : $totGB Go"
W "RAM libre        : $freeGB Go"
W "RAM utilisee     : $usedPct %"
W "Barrettes installees :"
Get-CimInstance Win32_PhysicalMemory | ForEach-Object {
  W "   - $([math]::Round($_.Capacity/1GB,0)) Go @ $($_.Speed) MHz  (slot $($_.DeviceLocator))"
}
$slots = (Get-CimInstance Win32_PhysicalMemoryArray | Select-Object -First 1).MemoryDevices
W "Emplacements RAM total sur la carte mere : $slots"
W ""
Y ("RAM totale                    : " + $totGB + " Go")
Y ("RAM utilisee                  : " + $usedPct + " %")

# --- 4. DISQUES -------------------------------------------
Write-Host "  4/12  Disques..." -ForegroundColor Gray
W "--- 4. DISQUES (LE POINT LE PLUS IMPORTANT) ---"
$pd = Get-PhysicalDisk
if ($pd) {
  foreach ($d in $pd) {
    W "Disque           : $($d.FriendlyName)"
    W "   Type          : $($d.MediaType)   <<< HDD = disque mecanique lent / SSD = rapide"
    W "   Bus           : $($d.BusType)"
    W "   Taille        : $([math]::Round($d.Size/1GB,0)) Go"
    W "   Sante         : $($d.HealthStatus)"
  }
  Y ("Type de disque                : " + (($pd | ForEach-Object { $_.MediaType }) -join ", "))
} else {
  W "   (lecture des disques physiques impossible sans droits administrateur)"
}
W ""
W "Espace libre par volume :"
$sys = $null
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
  $tot = [math]::Round($_.Size/1GB,1)
  $fre = [math]::Round($_.FreeSpace/1GB,1)
  $pct = if ($_.Size -gt 0) { [math]::Round($_.FreeSpace/$_.Size*100,0) } else { 0 }
  W "   $($_.DeviceID) $fre Go libres sur $tot Go  ($pct % libre)"
  if ($_.DeviceID -eq "C:") { $sys = "$fre Go libres sur $tot Go ($pct % libre)" }
}
W ""
if ($sys) { Y ("Disque C:                     : " + $sys) }

# --- 5. DEMARRAGE -----------------------------------------
Write-Host "  5/12  Programmes au demarrage..." -ForegroundColor Gray
W "--- 5. PROGRAMMES QUI SE LANCENT AU DEMARRAGE ---"
$startup = @(Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location)
if ($startup.Count -gt 0) { $startup | ForEach-Object { W "   - $($_.Name)   [$($_.Location)]" } }
else { W "   (aucun detecte par cette methode)" }
W ""
Y ("Programmes au demarrage       : " + $startup.Count)

# --- 6. PROCESSUS GOURMANDS -------------------------------
Write-Host "  6/12  Processus..." -ForegroundColor Gray
W "--- 6. TOP 12 PROCESSUS PAR MEMOIRE ---"
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 12 | ForEach-Object {
  W ("   {0,-32} {1,8} Mo" -f $_.ProcessName, [math]::Round($_.WorkingSet64/1MB,0))
}
W ""
W "--- 7. TOP 12 PROCESSUS PAR TEMPS CPU CUMULE ---"
Get-Process | Sort-Object CPU -Descending | Select-Object -First 12 | ForEach-Object {
  W ("   {0,-32} {1,8} s CPU" -f $_.ProcessName, [math]::Round($_.CPU,0))
}
W ""

# --- 8. ANTIVIRUS -----------------------------------------
Write-Host "  7/12  Antivirus..." -ForegroundColor Gray
W "--- 8. ANTIVIRUS / SECURITE ---"
$av = @(Get-CimInstance -Namespace root\SecurityCenter2 -ClassName AntiVirusProduct)
if ($av.Count -gt 0) { $av | ForEach-Object { W "   - $($_.displayName)" } }
else { W "   (non lisible)" }
W "   >>> Plusieurs antivirus en meme temps = ralentissement garanti"
W ""
Y ("Antivirus declares            : " + $av.Count)

# --- 9. ALIMENTATION --------------------------------------
Write-Host "  8/12  Mode d alimentation..." -ForegroundColor Gray
W "--- 9. MODE D'ALIMENTATION ---"
$alim = (powercfg /getactivescheme)
W $alim
$bat = Get-CimInstance Win32_Battery
if ($bat) { W "Batterie presente : oui (portable)" } else { W "Batterie : aucune (fixe)" }
W ""
if ($alim) { Y ("Mode d alimentation           : " + ($alim -replace ".*\((.*)\).*",'$1')) }

# --- 10. LOGICIELS INSTALLES ------------------------------
Write-Host "  9/12  Logiciels installes..." -ForegroundColor Gray
W "--- 10. LOGICIELS INSTALLES (pour reperer les bloatwares) ---"
$paths = @(
 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
$logs = @(Get-ItemProperty $paths | Where-Object { $_.DisplayName } |
  Sort-Object DisplayName | Select-Object -Unique DisplayName)
$logs | ForEach-Object { W "   - $($_.DisplayName)" }
W ""
Y ("Logiciels installes           : " + $logs.Count)

# --- 11. NAVIGATEURS / EXTENSIONS -------------------------
Write-Host " 10/12  Navigateurs..." -ForegroundColor Gray
W "--- 11. INDICE NAVIGATEUR ---"
$chromeProf = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Extensions"
if (Test-Path $chromeProf) { W "   Extensions Chrome installees : $(@(Get-ChildItem $chromeProf).Count)" }
$edgeProf = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Extensions"
if (Test-Path $edgeProf) { W "   Extensions Edge installees   : $(@(Get-ChildItem $edgeProf).Count)" }
W ""

# --- 12. ERREURS RECENTES ---------------------------------
Write-Host " 11/12  Journal des erreurs..." -ForegroundColor Gray
W "--- 12. ERREURS SYSTEME DES 7 DERNIERS JOURS (top 10) ---"
$ev = @(Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2; StartTime=(Get-Date).AddDays(-7)} -MaxEvents 200)
if ($ev.Count -gt 0) {
  $ev | Group-Object ProviderName | Sort-Object Count -Descending | Select-Object -First 10 |
    ForEach-Object { W "   $($_.Count) x  $($_.Name)" }
} else { W "   (aucune erreur lue, ou journal inaccessible)" }
W ""
Y ("Erreurs systeme sur 7 jours   : " + $ev.Count)

# --- 13. RAPPORTS PRECEDENTS ------------------------------
Write-Host " 12/12  Rapports precedents..." -ForegroundColor Gray
W "--- 13. RAPPORTS PRECEDENTS SUR CE BUREAU ---"
$anciens = @(Get-ChildItem -LiteralPath $bureau -Filter "Diagnostic-PC*.txt" -File -ErrorAction SilentlyContinue |
             Sort-Object LastWriteTime)
if ($anciens.Count -gt 0) {
  foreach ($a in $anciens) { W ("   {0:dd/MM/yyyy HH:mm}   {1}" -f $a.LastWriteTime, $a.Name) }
  W ""
  W "Ouvrir l'ancien et le nouveau cote a cote pour comparer la"
  W "synthese en tete de rapport, ligne par ligne."
} else {
  W "   Aucun rapport precedent. Celui-ci servira de reference."
}
W ""

W "=========================================="
W " FIN DU RAPPORT"
W "=========================================="

# --- Synthese en tete -------------------------------------
$entete = New-Object System.Collections.ArrayList
[void]$entete.Add("==========================================")
[void]$entete.Add(" SYNTHESE  -  $(Get-Date -Format 'dd/MM/yyyy HH:mm')")
[void]$entete.Add(" Les chiffres a comparer avec le rapport precedent")
[void]$entete.Add("==========================================")
foreach ($x in $S) { [void]$entete.Add(" " + $x) }
[void]$entete.Add("")

$texte = (@($entete) + @($R)) -join "`r`n"

$ecrit = $false
foreach ($cible in @($out, (Join-Path $env:USERPROFILE ("Diagnostic-PC-" + $stamp + ".txt")), (Join-Path $env:TEMP ("Diagnostic-PC-" + $stamp + ".txt")))) {
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
  Write-Host "  ERREUR PENDANT LE DIAGNOSTIC :" -ForegroundColor Red
  Write-Host ("  " + $_.Exception.Message) -ForegroundColor Red
  Write-Host ("  Ligne " + $_.InvocationInfo.ScriptLineNumber) -ForegroundColor Red
  Write-Host ""
  Write-Host "  Recopiez ces lignes rouges et envoyez-les." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  Appuyez sur Entree pour fermer cette fenetre." -ForegroundColor Cyan
Read-Host
