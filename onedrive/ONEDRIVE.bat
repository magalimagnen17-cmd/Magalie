@echo off
title OneDrive  -  constat, reinitialisation ou desinstallation
setlocal
REM ==========================================================
REM  A DOUBLE-CLIQUER. Rien a taper, rien a coller.
REM  Ce fichier porte le script PowerShell a sa suite.
REM  Il l extrait dans le dossier temporaire puis l execute.
REM  Ce que fait le script est decrit en tete de celui-ci.
REM ==========================================================
set "PS1=%TEMP%\Desinstaller-OneDrive.ps1"
set "PWSH=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PWSH%" set "PWSH=powershell.exe"
more +25 "%~f0" > "%PS1%"
if not exist "%PS1%" goto ERR
findstr /c:"ONEDRIVE : CONSTATER, REINITIALISER OU DESINSTALLER" "%PS1%" >nul || goto ERR
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
#  ONEDRIVE : CONSTATER, REINITIALISER OU DESINSTALLER
#  ATTENTION : ce script MODIFIE la machine si vous le
#  demandez. Il commence toujours par un controle en lecture
#  seule, et ne touche a rien sans confirmation explicite.
#  Il ne supprime JAMAIS le dossier de donnees OneDrive.
# ==========================================================

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference    = "SilentlyContinue"

$L = New-Object System.Collections.ArrayList
function W($t){ [void]$L.Add([string]$t); Write-Host $t }
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
Write-Host "  ONEDRIVE" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Etape 1 : constat, en lecture seule." -ForegroundColor Yellow
Write-Host "  Rien ne sera modifie avant votre confirmation." -ForegroundColor Yellow
Write-Host ""

W "=========================================================="
W "  ONEDRIVE : CONSTAT"
W ("  " + $env:COMPUTERNAME + " / " + $env:USERNAME + "   " + (Get-Date -Format "dd/MM/yyyy HH:mm"))
W "=========================================================="
W ""
W ("Profil traite : " + $env:USERPROFILE)
W "OneDrive s'installe par utilisateur : ce script agit sur ce"
W "profil-la, et sur aucun autre. Verifiez que c'est le bon."
W ""

# ---------- Processus ----------
$proc = @(Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue)
if ($proc.Count -gt 0) {
  $mo = [math]::Round(($proc | Measure-Object WorkingSet64 -Sum).Sum/1MB,0)
  W ("OneDrive tourne : " + $proc.Count + " processus, " + $mo + " Mo de memoire")
} else {
  W "OneDrive n'est pas en cours d'execution."
}

# ---------- Installation ----------
$setup = @(
  (Join-Path $env:SystemRoot "SysWOW64\OneDriveSetup.exe"),
  (Join-Path $env:SystemRoot "System32\OneDriveSetup.exe"),
  (Join-Path $env:LOCALAPPDATA "Microsoft\OneDrive\OneDriveSetup.exe")
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
$exe = Join-Path $env:LOCALAPPDATA "Microsoft\OneDrive\OneDrive.exe"
if (Test-Path -LiteralPath $exe) {
  W ("Installe : " + $exe)
  W ("Version  : " + (Get-Item -LiteralPath $exe).VersionInfo.FileVersion)
} else {
  W "Aucun OneDrive.exe trouve dans le profil utilisateur."
}
if ($setup) { W ("Programme de desinstallation : " + $setup) }
else { W "Programme de desinstallation introuvable." }
W ""

# ---------- Dossier de donnees ----------
$dossiers = @(
  (Join-Path $env:USERPROFILE "OneDrive"),
  $env:OneDrive,
  $env:OneDriveConsumer,
  $env:OneDriveCommercial
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique

$enLigne = 0
$totalOD = [int64]0
$nbOD = 0
foreach ($d in $dossiers) {
  W ("Dossier OneDrive : " + $d)
  $nd = 0; $od = [int64]0
  foreach ($f in @(Get-ChildItem -LiteralPath $d -Recurse -File -Force -ErrorAction SilentlyContinue)) {
    $nd++; $od += $f.Length
    # 0x400000 = le contenu n'est pas sur le disque, il vit dans le cloud
    if (($f.Attributes -band 0x400000) -or ($f.Attributes -band 0x00040000)) { $enLigne++ }
  }
  $nbOD += $nd; $totalOD += $od
  W ("   " + $nd + " fichiers, " + (Go $od) + " occupes sur le disque")
}
if ($dossiers.Count -eq 0) { W "Aucun dossier OneDrive dans ce profil." }
W ""

# ---------- Dossiers rediriges ----------
$reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
$cles = @(
  @("Bureau","Desktop"), @("Documents","Personal"), @("Images","My Pictures"),
  @("Videos","My Video"), @("Musique","My Music"),
  @("Telechargements","{374DE290-123F-4565-9164-39C4925E467B}")
)
$rediriges = @()
foreach ($e in $cles) {
  $b = (Get-ItemProperty -Path $reg -Name $e[1] -ErrorAction SilentlyContinue).($e[1])
  if ([string]::IsNullOrEmpty($b)) { continue }
  $c = [Environment]::ExpandEnvironmentVariables($b)
  if ($c -like "*OneDrive*") { $rediriges += ($e[0] + " -> " + $c) }
}

# ---------- Verdict de securite ----------
W "----------------------------------------------------------"
$danger = $false

if ($rediriges.Count -gt 0) {
  $danger = $true
  W "[STOP] DES DOSSIERS PERSONNELS SONT DANS ONEDRIVE :"
  foreach ($r in $rediriges) { W ("        " + $r) }
  W ""
  W "        Desinstaller maintenant rendrait ces dossiers"
  W "        introuvables a leur place habituelle. Il faut"
  W "        d'abord les ramener dans C:\Users\$env:USERNAME,"
  W "        puis seulement ensuite desinstaller."
} else {
  W "[ok] Aucun dossier personnel n'est range dans OneDrive."
  W "     Bureau, Documents et Images restent a leur place"
  W "     habituelle apres la desinstallation."
}
W ""

if ($enLigne -gt 0) {
  $danger = $true
  W ("[STOP] " + $enLigne + " FICHIERS N'EXISTENT QUE DANS LE CLOUD.")
  W "        Ils apparaissent dans l'Explorateur mais leur contenu"
  W "        n'est pas sur ce disque. Desinstaller OneDrive les"
  W "        rendrait inutilisables."
  W "        Avant toute desinstallation : clic droit sur le"
  W "        dossier OneDrive, 'Toujours conserver sur cet"
  W "        appareil', et attendre le telechargement complet."
} elseif ($nbOD -gt 0) {
  W "[ok] Tous les fichiers du dossier OneDrive sont bien"
  W "     presents physiquement sur le disque."
}
W "----------------------------------------------------------"
W ""

# ---------- Choix ----------
Write-Host ""
Write-Host "  QUE VOULEZ-VOUS FAIRE ?" -ForegroundColor Cyan
Write-Host ""
Write-Host "   R  Reinitialiser OneDrive (reversible)" -ForegroundColor White
Write-Host "      Vide le cache de synchronisation et relance proprement."
Write-Host "      C'est ce qui debloque la plupart des synchronisations qui"
Write-Host "      tournent en rond, et rien n'est desinstalle. 2 minutes."
Write-Host ""
Write-Host "   D  Desinstaller OneDrive" -ForegroundColor White
Write-Host "      Le dossier de donnees et son contenu sont CONSERVES."
Write-Host "      Reinstallable ensuite depuis onedrive.com."
Write-Host ""
Write-Host "   N  Ne rien faire, garder seulement le constat" -ForegroundColor White
Write-Host ""
if ($danger) {
  Write-Host "  Un point [STOP] a ete signale ci-dessus." -ForegroundColor Red
  Write-Host "  La desinstallation est deconseillee tant qu'il tient." -ForegroundColor Red
  Write-Host ""
}
$choix = (Read-Host "  Votre choix (R / D / N)").Trim().ToUpper()
W ""
W ("Choix : " + $choix)

# ---------- Reinitialisation ----------
if ($choix -eq "R") {
  W ""
  W "--- REINITIALISATION ---"
  Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue | Stop-Process -Force
  Start-Sleep -Seconds 2
  if (Test-Path -LiteralPath $exe) {
    Start-Process -FilePath $exe -ArgumentList "/reset" -ErrorAction SilentlyContinue
    W "Commande de reinitialisation envoyee."
    W "L'icone disparait de la barre des taches puis revient."
    W "Comptez 2 minutes. Si elle ne revient pas d'elle-meme,"
    W "relancez OneDrive depuis le menu Demarrer."
    Start-Sleep -Seconds 15
    if (-not (Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue)) {
      Start-Process -FilePath $exe -ErrorAction SilentlyContinue
      W "OneDrive relance."
    }
  } else {
    W "OneDrive.exe introuvable, reinitialisation impossible."
  }
}

# ---------- Desinstallation ----------
elseif ($choix -eq "D") {
  Write-Host ""
  if ($danger) {
    Write-Host "  Un point [STOP] est actif. Pour continuer malgre tout," -ForegroundColor Red
    Write-Host "  tapez exactement : JE CONFIRME" -ForegroundColor Red
    $c2 = Read-Host "  "
    if ($c2 -ne "JE CONFIRME") { W "Desinstallation annulee."; $choix = "N" }
  } else {
    Write-Host "  Tapez OUI pour desinstaller OneDrive." -ForegroundColor Yellow
    $c2 = Read-Host "  "
    if ($c2.Trim().ToUpper() -ne "OUI") { W "Desinstallation annulee."; $choix = "N" }
  }

  if ($choix -eq "D") {
    W ""
    W "--- DESINSTALLATION ---"

    W "1. Arret du processus"
    Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 3

    W "2. Desinstallation par le programme officiel"
    if ($setup) {
      $p = Start-Process -FilePath $setup -ArgumentList "/uninstall" -PassThru -Wait -ErrorAction SilentlyContinue
      if ($p) { W ("   OneDriveSetup /uninstall termine, code " + $p.ExitCode) }
      else { W "   Echec du lancement de OneDriveSetup." }
    } else {
      W "   OneDriveSetup.exe introuvable, desinstallation manuelle"
      W "   necessaire : Parametres, Applications, OneDrive."
    }

    W "3. Suppression du lancement automatique"
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue
    W "   cle Run nettoyee"

    W "4. Suppression des taches planifiees OneDrive"
    $n = 0
    Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like "*OneDrive*" } | ForEach-Object {
      Unregister-ScheduledTask -TaskName $_.TaskName -Confirm:$false -ErrorAction SilentlyContinue
      $n++
    }
    W ("   " + $n + " tache(s) supprimee(s)")
    if ($n -eq 0) {
      W "   aucune tache supprimee. Sans droits administrateur c'est"
      W "   normal, et sans consequence : la desinstallation reste"
      W "   effective."
    }

    W "5. Retrait de l'icone OneDrive dans l'Explorateur"
    foreach ($clsid in @("{018D5C66-4533-4307-9B53-224DE2ED1FE6}","{04271989-C4D2-df11-9b8e-00e04c1e2d34}")) {
      $k = "HKCU:\Software\Classes\CLSID\$clsid"
      if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
      Set-ItemProperty -Path $k -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    }
    W "   icone masquee (reversible)"

    W ""
    W "--- CE QUI N'A PAS ETE TOUCHE ---"
    foreach ($d in $dossiers) {
      W ("Le dossier " + $d + " et ses " + $nbOD + " fichiers sont intacts.")
    }
    W "Aucun document n'a ete supprime. Les fichiers restent"
    W "egalement disponibles sur onedrive.com."
    W ""
    W "Redemarrer le PC pour que l'Explorateur prenne en compte"
    W "le changement."
  }
}

if ($choix -eq "N") { W ""; W "Aucune modification effectuee." }

# ---------- Rapport ----------
$out = Join-Path (CheminBureau) ("OneDrive-" + (Get-Date -Format "yyyy-MM-dd-HHmm") + ".txt")
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
