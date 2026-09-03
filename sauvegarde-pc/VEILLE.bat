@echo off
title Veille pendant la sauvegarde
setlocal
REM ==========================================================
REM  A DOUBLE-CLIQUER. Rien a taper, rien a coller.
REM  Ce fichier porte le script PowerShell a sa suite.
REM  Il l extrait dans le dossier temporaire puis l execute.
REM  Ce que fait le script est decrit en tete de celui-ci.
REM ==========================================================
set "PS1=%TEMP%\Veille.ps1"
set "PWSH=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PWSH%" set "PWSH=powershell.exe"
more +25 "%~f0" > "%PS1%"
if not exist "%PS1%" goto ERR
findstr /c:"VEILLE PENDANT UNE SAUVEGARDE" "%PS1%" >nul || goto ERR
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
#  VEILLE PENDANT UNE SAUVEGARDE
#  Empeche le PC de s'endormir tant que la synchronisation
#  n'est pas finie, puis remet les reglages d'origine.
#  Ne touche a rien d'autre que la mise en veille.
# ==========================================================

$ErrorActionPreference = "SilentlyContinue"

function CheminBureau {
  $reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
  $b = (Get-ItemProperty -Path $reg -Name "Desktop" -ErrorAction SilentlyContinue).Desktop
  if ($b) { $b = [Environment]::ExpandEnvironmentVariables($b) }
  foreach ($c in @($b, [Environment]::GetFolderPath("Desktop"), (Join-Path $env:USERPROFILE "Desktop"))) {
    if ($c -and (Test-Path -LiteralPath $c)) { return $c }
  }
  return $env:TEMP
}
$memo = Join-Path (CheminBureau) "Veille-reglages-precedents.txt"

# powercfg parle la langue de Windows, mais les valeurs restent en
# hexadecimal : on lit les nombres, pas les phrases autour.
function LireDelais($sub, $param){
  $t = powercfg /query SCHEME_CURRENT $sub $param 2>$null
  $hex = @($t | Select-String -Pattern "0x[0-9a-fA-F]{8}" -AllMatches |
           ForEach-Object { $_.Matches } | ForEach-Object { $_.Value })
  if ($hex.Count -ge 2) {
    return New-Object PSObject -Property @{
      AC = [Convert]::ToInt32($hex[$hex.Count-2],16)
      DC = [Convert]::ToInt32($hex[$hex.Count-1],16) }
  }
  return $null
}

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  MISE EN VEILLE PENDANT LA SAUVEGARDE" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$veille = LireDelais "SUB_SLEEP" "STANDBYIDLE"
$ecran  = LireDelais "SUB_VIDEO" "VIDEOIDLE"

if ($veille) { Write-Host ("  Veille actuelle : " + $veille.AC + " s sur secteur, " + $veille.DC + " s sur batterie") }
if ($ecran)  { Write-Host ("  Ecran actuel    : " + $ecran.AC + " s sur secteur, " + $ecran.DC + " s sur batterie") }
Write-Host ""
Write-Host "   1  Empecher la veille pendant la sauvegarde" -ForegroundColor White
Write-Host "      L'ecran continue de s'eteindre, ce qui economise la"
Write-Host "      dalle, mais la machine ne s'endort plus et la"
Write-Host "      synchronisation continue la nuit."
Write-Host ""
Write-Host "   2  Remettre les reglages d'avant" -ForegroundColor White
Write-Host ""
Write-Host "   3  Ne rien faire" -ForegroundColor White
Write-Host ""
$c = (Read-Host "  Votre choix (1 / 2 / 3)").Trim()

if ($c -eq "1") {
  if ($veille) {
    "STANDBYIDLE AC=$($veille.AC) DC=$($veille.DC)" | Out-File $memo -Encoding UTF8
    Write-Host ""
    Write-Host ("  Reglages precedents notes dans " + $memo) -ForegroundColor Gray
  }
  powercfg /change standby-timeout-ac 0   | Out-Null
  powercfg /change standby-timeout-dc 0   | Out-Null
  powercfg /change hibernate-timeout-ac 0 | Out-Null
  Write-Host ""
  Write-Host "  La machine ne se mettra plus en veille." -ForegroundColor Green
  Write-Host "  Laissez-la branchee sur le secteur." -ForegroundColor Yellow
  Write-Host "  Pensez a relancer ce script en choisissant 2 une fois" -ForegroundColor Yellow
  Write-Host "  la sauvegarde terminee : une machine qui ne dort jamais" -ForegroundColor Yellow
  Write-Host "  chauffe et use sa batterie pour rien." -ForegroundColor Yellow
}
elseif ($c -eq "2") {
  $ac = 1800; $dc = 900; $source = "valeurs standard de Windows"
  if (Test-Path -LiteralPath $memo) {
    $t = Get-Content -LiteralPath $memo -Raw
    if ($t -match "AC=(\d+)\s+DC=(\d+)") {
      $ac = [int]$matches[1]; $dc = [int]$matches[2]; $source = "vos reglages d'avant"
      if ($ac -eq 0) { $ac = 1800 }
      if ($dc -eq 0) { $dc = 900 }
    }
  }
  powercfg /change standby-timeout-ac $ac | Out-Null
  powercfg /change standby-timeout-dc $dc | Out-Null
  Write-Host ""
  Write-Host ("  Veille retablie : " + $ac + " s sur secteur, " + $dc + " s sur batterie") -ForegroundColor Green
  Write-Host ("  D'apres " + $source) -ForegroundColor Gray
}
else { Write-Host ""; Write-Host "  Aucune modification." }

Write-Host ""
Write-Host "  Appuyez sur Entree pour fermer cette fenetre." -ForegroundColor Cyan
Read-Host
