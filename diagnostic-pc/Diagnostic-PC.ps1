# ============================================================
#  DIAGNOSTIC PC - LECTURE SEULE
#  Ce script ne modifie RIEN. Il lit et ecrit un rapport texte
#  sur le Bureau : Diagnostic-PC.txt
# ============================================================

$ErrorActionPreference = "SilentlyContinue"
$out = Join-Path ([Environment]::GetFolderPath("Desktop")) "Diagnostic-PC.txt"
$R = New-Object System.Collections.ArrayList
function W($t) { [void]$R.Add($t) }

W "=========================================="
W " RAPPORT DE DIAGNOSTIC PC"
W " Genere le $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
W "=========================================="
W ""

# --- 1. SYSTEME -------------------------------------------
W "--- 1. SYSTEME ---"
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$bios = Get-CimInstance Win32_BIOS
W "Windows          : $($os.Caption) $($os.OSArchitecture)"
W "Version / build  : $((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').DisplayVersion) / $($os.BuildNumber)"
W "Installe le      : $($os.InstallDate)"
W "Fabricant        : $($cs.Manufacturer)"
W "Modele           : $($cs.Model)"
W "BIOS date        : $($bios.ReleaseDate)"
$up = (Get-Date) - $os.LastBootUpTime
W "Allume depuis    : $([math]::Round($up.TotalDays,1)) jours ($([math]::Round($up.TotalHours,1)) h)"
W ""

# --- 2. PROCESSEUR ----------------------------------------
W "--- 2. PROCESSEUR ---"
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
W "CPU              : $($cpu.Name.Trim())"
W "Coeurs / threads : $($cpu.NumberOfCores) / $($cpu.NumberOfLogicalProcessors)"
W "Frequence base   : $($cpu.MaxClockSpeed) MHz"
W "Charge actuelle  : $($cpu.LoadPercentage) %"
W ""

# --- 3. MEMOIRE -------------------------------------------
W "--- 3. MEMOIRE VIVE (RAM) ---"
$totGB = [math]::Round($cs.TotalPhysicalMemory/1GB,1)
$freeGB = [math]::Round($os.FreePhysicalMemory/1MB,1)
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

# --- 4. DISQUES -------------------------------------------
W "--- 4. DISQUES (LE POINT LE PLUS IMPORTANT) ---"
Get-PhysicalDisk | ForEach-Object {
  W "Disque           : $($_.FriendlyName)"
  W "   Type          : $($_.MediaType)   <<< HDD = disque mecanique lent / SSD = rapide"
  W "   Bus           : $($_.BusType)"
  W "   Taille        : $([math]::Round($_.Size/1GB,0)) Go"
  W "   Sante         : $($_.HealthStatus)"
}
W ""
W "Espace libre par volume :"
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
  $tot = [math]::Round($_.Size/1GB,1)
  $fre = [math]::Round($_.FreeSpace/1GB,1)
  $pct = if ($_.Size -gt 0) { [math]::Round($_.FreeSpace/$_.Size*100,0) } else { 0 }
  W "   $($_.DeviceID) $fre Go libres sur $tot Go  ($pct % libre)"
}
W ""

# --- 5. DEMARRAGE -----------------------------------------
W "--- 5. PROGRAMMES QUI SE LANCENT AU DEMARRAGE ---"
$startup = Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location
if ($startup) { $startup | ForEach-Object { W "   - $($_.Name)   [$($_.Location)]" } }
else { W "   (aucun detecte par cette methode)" }
W ""

# --- 6. PROCESSUS GOURMANDS -------------------------------
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
W "--- 8. ANTIVIRUS / SECURITE ---"
$av = Get-CimInstance -Namespace root\SecurityCenter2 -ClassName AntiVirusProduct
if ($av) { $av | ForEach-Object { W "   - $($_.displayName)" } }
else { W "   (non lisible)" }
W "   >>> Plusieurs antivirus en meme temps = ralentissement garanti"
W ""

# --- 9. ALIMENTATION --------------------------------------
W "--- 9. MODE D'ALIMENTATION ---"
W (powercfg /getactivescheme)
$bat = Get-CimInstance Win32_Battery
if ($bat) { W "Batterie presente : oui (portable)" } else { W "Batterie : aucune (fixe)" }
W ""

# --- 10. LOGICIELS INSTALLES ------------------------------
W "--- 10. LOGICIELS INSTALLES (pour reperer les bloatwares) ---"
$paths = @(
 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
Get-ItemProperty $paths | Where-Object { $_.DisplayName } |
  Sort-Object DisplayName | Select-Object -Unique DisplayName |
  ForEach-Object { W "   - $($_.DisplayName)" }
W ""

# --- 11. NAVIGATEURS / EXTENSIONS -------------------------
W "--- 11. INDICE NAVIGATEUR ---"
$chromeProf = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Extensions"
if (Test-Path $chromeProf) { W "   Extensions Chrome installees : $((Get-ChildItem $chromeProf).Count)" }
$edgeProf = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Extensions"
if (Test-Path $edgeProf) { W "   Extensions Edge installees   : $((Get-ChildItem $edgeProf).Count)" }
W ""

# --- 12. ERREURS RECENTES ---------------------------------
W "--- 12. ERREURS SYSTEME DES 7 DERNIERS JOURS (top 10) ---"
Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2; StartTime=(Get-Date).AddDays(-7)} -MaxEvents 200 |
  Group-Object ProviderName | Sort-Object Count -Descending | Select-Object -First 10 |
  ForEach-Object { W "   $($_.Count) x  $($_.Name)" }
W ""

W "=========================================="
W " FIN DU RAPPORT"
W "=========================================="

$R | Out-File -FilePath $out -Encoding UTF8
Write-Host ""
Write-Host "Rapport genere sur le Bureau : Diagnostic-PC.txt" -ForegroundColor Green
Write-Host ""
notepad $out
