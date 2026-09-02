# ==========================================================
#  NETTOYAGE PC - Lenovo IdeaPad 110 (80TJ)
#  Ce script MODIFIE la machine.
#  Il cree d'abord un point de restauration.
#  Tout ce qu'il desactive est reactivable en 1 clic.
# ==========================================================

$ErrorActionPreference = "SilentlyContinue"
$fait = New-Object System.Collections.ArrayList
function OK($t){ [void]$fait.Add("[OK] $t"); Write-Host "  [OK] $t" -ForegroundColor Green }
function KO($t){ [void]$fait.Add("[--] $t"); Write-Host "  [--] $t" -ForegroundColor DarkGray }

# --- Verification des droits admin ---
$adm = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
       ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $adm) {
  Write-Host "`n  ARRET : cette fenetre n'est PAS en mode administrateur." -ForegroundColor Red
  Write-Host "  Fermez-la, refaites clic droit sur Demarrer > Terminal (admin).`n" -ForegroundColor Red
  Read-Host "Entree pour quitter"; exit
}

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  NETTOYAGE DU PC" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ce script va :"
Write-Host "  1. Creer un point de restauration (filet de securite)"
Write-Host "  2. Desinstaller 4 logiciels morts (WinZip 21, Skype 7.40,"
Write-Host "     CyberLink PowerDVD 14, CyberLink Power2Go 8)"
Write-Host "  3. Vous demander pour 2 logiciels sensibles"
Write-Host "  4. Desactiver 7 programmes au demarrage (reversible)"
Write-Host "  5. Couper les effets visuels et l'indexation du disque"
Write-Host "  6. Vider les fichiers temporaires"
Write-Host ""
Write-Host "Rien d'autre ne sera touche. Aucun document ne sera supprime." -ForegroundColor Yellow
Write-Host ""
if ((Read-Host "Tapez OUI pour lancer") -ne "OUI") { Write-Host "Annule."; exit }

# ==========================================================
Write-Host "`n--- 1. POINT DE RESTAURATION ---" -ForegroundColor Cyan
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" `
  -Name "SystemRestorePointCreationFrequency" -Value 0 -PropertyType DWord -Force | Out-Null
Enable-ComputerRestore -Drive "C:\"
Checkpoint-Computer -Description "Avant nettoyage performance" -RestorePointType MODIFY_SETTINGS
if ($?) { OK "Point de restauration cree" } else { KO "Point de restauration non cree (protection systeme desactivee)" }

# ==========================================================
function Get-Apps {
  Get-ItemProperty `
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' |
    Where-Object { $_.DisplayName }
}

function Remove-App($motif) {
  $app = Get-Apps | Where-Object { $_.DisplayName -like $motif } | Select-Object -First 1
  if (-not $app) { KO "$motif : deja absent"; return }
  $nom = $app.DisplayName
  $u = $app.QuietUninstallString; if (-not $u) { $u = $app.UninstallString }
  if (-not $u) { KO "$nom : pas de desinstalleur"; return }

  if ($u -match '(\{[0-9A-Fa-f]{8}-[0-9A-Fa-f\-]+\})') {
    Write-Host "  ... desinstallation silencieuse de $nom"
    Start-Process msiexec.exe -ArgumentList "/x $($matches[1]) /qn /norestart" -Wait
    OK "$nom desinstalle"
  } else {
    if ($u -match '^"([^"]+)"\s*(.*)$') { $exe=$matches[1]; $arg=$matches[2] }
    else { $exe=$u; $arg='' }
    Write-Host "  ... $nom : une fenetre va s'ouvrir, cliquez sur Oui / Desinstaller / Terminer" -ForegroundColor Yellow
    if ($arg) { Start-Process $exe -ArgumentList $arg -Wait } else { Start-Process $exe -Wait }
    OK "$nom : desinstalleur execute"
  }
}

Write-Host "`n--- 2. LOGICIELS MORTS (suppression) ---" -ForegroundColor Cyan
Remove-App "WinZip 21*"
Remove-App "Skype*7.40*"
Remove-App "CyberLink PowerDVD 14*"
Remove-App "CyberLink Power2Go 8*"

# ==========================================================
Write-Host "`n--- 3. LOGICIELS A CONFIRMER ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Backup and Sync from Google : produit ABANDONNE par Google en 2021."
Write-Host "  Il ne se met plus a jour mais continue de synchroniser et d'user le disque."
Write-Host "  Les fichiers deja telecharges restent sur le PC dans tous les cas."
if ((Read-Host "  Le desinstaller ? (O/N)") -match '^[OoYy]') { Remove-App "Backup and Sync*" }
else { KO "Backup and Sync conserve" }

Write-Host ""
Write-Host "  OpenOffice 4.1.2 : fait doublon avec Microsoft Office 2016 deja installe."
Write-Host "  ATTENTION : ne le retirez QUE si Office 2016 s'ouvre et fonctionne."
Write-Host "  Si Office 2016 n'est pas active, OpenOffice est sa seule suite bureautique."
if ((Read-Host "  Le desinstaller ? (O/N)") -match '^[OoYy]') { Remove-App "OpenOffice*" }
else { KO "OpenOffice conserve" }

# ==========================================================
Write-Host "`n--- 4. PROGRAMMES AU DEMARRAGE ---" -ForegroundColor Cyan
$off = [byte[]](3,0,0,0,0,0,0,0,0,0,0,0)
$cibles = @('Update Notifier','HP Officejet 4630 series (NET)','MicrosoftEdgeAutoLaunch_*',
            'StartCN','LenovoUtility','RtHDVBg_LENOVO_DOLBYDRAGON','RtHDVBg_LENOVO_MICPKEY',
            'WinZip Preloader')
$racines = @('HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion',
             'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion',
             'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion')

foreach ($c in $cibles) {
  $trouve = $false
  foreach ($r in $racines) {
    $run = "$r\Run"
    $app = "$r\Explorer\StartupApproved\Run"
    $vals = (Get-Item $run).Property | Where-Object { $_ -like $c }
    foreach ($v in $vals) {
      if (-not (Test-Path $app)) { New-Item $app -Force | Out-Null }
      Set-ItemProperty -Path $app -Name $v -Value $off -Type Binary -Force
      $trouve = $true
    }
  }
  if ($trouve) { OK "Demarrage desactive : $c" } else { KO "Demarrage : $c introuvable" }
}

# Raccourcis du dossier Demarrage commun
$sf = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
$bk = Join-Path $sf "_Desactives"
Get-ChildItem $sf -Filter *.lnk | Where-Object {
  $_.BaseName -match 'WinZip|Update Notifier'
} | ForEach-Object {
  if (-not (Test-Path $bk)) { New-Item $bk -ItemType Directory -Force | Out-Null }
  Move-Item $_.FullName $bk -Force
  OK "Raccourci de demarrage mis de cote : $($_.Name)"
}

# ==========================================================
Write-Host "`n--- 5. EFFETS VISUELS ET INDEXATION ---" -ForegroundColor Cyan
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' VisualFXSetting 2 -Force
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' ListviewAlphaSelect 0 -Force
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' TaskbarAnimations 0 -Force
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' ListviewShadow 0 -Force
Set-ItemProperty 'HKCU:\Control Panel\Desktop\WindowMetrics' MinAnimate "0" -Force
New-ItemProperty 'HKCU:\Software\Microsoft\Windows\DWM' EnableAeroPeek -Value 0 -PropertyType DWord -Force | Out-Null
OK "Effets visuels reduits (lissage des polices conserve)"

$vol = Get-WmiObject Win32_Volume -Filter "DriveLetter='C:'"
if ($vol.IndexingEnabled) { $vol.IndexingEnabled = $false; [void]$vol.Put(); OK "Indexation du disque C: desactivee" }
else { KO "Indexation deja desactivee" }

# ==========================================================
Write-Host "`n--- 6. FICHIERS TEMPORAIRES ---" -ForegroundColor Cyan
$avant = (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace
Remove-Item "$env:TEMP\*" -Recurse -Force
Remove-Item "$env:WINDIR\Temp\*" -Recurse -Force
Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force
$apres = (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace
OK "Temporaires vides ($([math]::Round(($apres-$avant)/1MB,0)) Mo recuperes)"

# ==========================================================
Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "  RECAPITULATIF" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
$fait | ForEach-Object { Write-Host "  $_" }
$log = "$env:USERPROFILE\Desktop\Nettoyage-PC-log.txt"
$fait | Out-File $log -Encoding UTF8
Write-Host ""
Write-Host "  Journal enregistre sur le Bureau : Nettoyage-PC-log.txt" -ForegroundColor Green
Write-Host ""
Write-Host "  POUR ANNULER un programme de demarrage :" -ForegroundColor Yellow
Write-Host "  Ctrl+Maj+Echap > onglet Demarrage > clic droit > Activer" -ForegroundColor Yellow
Write-Host ""
Write-Host "  IL FAUT MAINTENANT REDEMARRER pour que tout s'applique." -ForegroundColor Yellow
Write-Host ""
if ((Read-Host "Redemarrer maintenant ? (O/N)") -match '^[OoYy]') { Restart-Computer -Force }
