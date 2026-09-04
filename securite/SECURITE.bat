@echo off
title Etat de securite
setlocal
REM ==========================================================
REM  A DOUBLE-CLIQUER. Rien a taper, rien a coller.
REM  Ce fichier porte le script PowerShell a sa suite.
REM  Il l extrait dans le dossier temporaire puis l execute.
REM  Ce que fait le script est decrit en tete de celui-ci.
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
set "PS1=%TEMP%\Etat-Securite.ps1"
set "PWSH=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PWSH%" set "PWSH=powershell.exe"
more +34 "%~f0" > "%PS1%"
if not exist "%PS1%" goto ERR
findstr /c:"ETAT DE SECURITE" "%PS1%" >nul || goto ERR
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
#  ETAT DE SECURITE
#  Constat en lecture seule, puis deux reglages proposes,
#  chacun avec confirmation. N'installe rien, ne supprime
#  rien, ne lance aucun scan sans qu'on le demande.
# ==========================================================

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference    = "SilentlyContinue"

$L = New-Object System.Collections.ArrayList
function W($t){ [void]$L.Add([string]$t); Write-Host $t }
function T($t){ [void]$L.Add(""); [void]$L.Add("=== $t ==="); Write-Host ""; Write-Host "=== $t ===" -ForegroundColor Cyan }
function CheminBureau {
  $reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
  $b = (Get-ItemProperty -Path $reg -Name "Desktop" -ErrorAction SilentlyContinue).Desktop
  if ($b) { $b = [Environment]::ExpandEnvironmentVariables($b) }
  foreach ($c in @($b, [Environment]::GetFolderPath("Desktop"), (Join-Path $env:USERPROFILE "Desktop"))) {
    if ($c -and (Test-Path -LiteralPath $c)) { return $c }
  }
  return $env:TEMP
}

# Le nom d'une extension est souvent une cle de traduction du type
# __MSG_appName__ : il faut alors aller le chercher dans les fichiers
# de langue de l'extension.
function NomExtension($dossierVersion){
  $mf = Join-Path $dossierVersion "manifest.json"
  if (-not (Test-Path -LiteralPath $mf)) { return $null }
  try { $j = Get-Content -LiteralPath $mf -Raw -Encoding UTF8 | ConvertFrom-Json } catch { return $null }
  $n = $j.name
  if ($n -like "__MSG_*__") {
    $cle = $n.Trim("_").Substring(4)
    $loc = $j.default_locale
    foreach ($l in @($loc, "fr", "en", "en_US")) {
      if (-not $l) { continue }
      $m = Join-Path $dossierVersion ("_locales\" + $l + "\messages.json")
      if (Test-Path -LiteralPath $m) {
        try {
          $mj = Get-Content -LiteralPath $m -Raw -Encoding UTF8 | ConvertFrom-Json
          if ($mj.$cle.message) { return $mj.$cle.message }
        } catch { }
      }
    }
    return "(nom localise illisible)"
  }
  return $n
}

try {

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  ETAT DE SECURITE" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$adm = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
       ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$bureau = CheminBureau

W ""
W "=========================================================="
W "  ETAT DE SECURITE"
W ("  " + $env:COMPUTERNAME + " / " + $env:USERNAME + "   " + (Get-Date -Format "dd/MM/yyyy HH:mm"))
W ("  Mode administrateur : " + $(if ($adm) { "oui" } else { "non" }))
W "=========================================================="

# ---------- 1. Antivirus installes ----------
T "ANTIVIRUS PRESENTS SUR LA MACHINE"
$av = @(Get-CimInstance -Namespace root\SecurityCenter2 -ClassName AntiVirusProduct)
if ($av.Count -eq 0) { W "Aucun antivirus declare. Situation anormale." }
else {
  foreach ($a in $av) { W ("   - " + $a.displayName) }
  W ""
  if ($av.Count -eq 1) {
    W "[ok] Un seul antivirus. C'est ce qu'il faut."
    W "     N'en installez pas d'autre : deux antivirus se scannent"
    W "     l'un l'autre et divisent la vitesse de la machine."
  } else {
    W ("[!] " + $av.Count + " antivirus en meme temps.")
    W "    Ils se genent mutuellement. En garder UN SEUL."
  }
}

# ---------- 2. Etat de Defender ----------
T "ETAT DE WINDOWS DEFENDER"
$s = Get-MpComputerStatus -ErrorAction SilentlyContinue
if (-not $s) {
  W "Etat illisible."
  if (-not $adm) { W "La fenetre n'est pas en mode administrateur." }
} else {
  W ("Protection en temps reel  : " + $(if ($s.RealTimeProtectionEnabled) { "active" } else { "DESACTIVEE" }))
  W ("Protection dans le cloud  : " + $(if ($s.AMServiceEnabled) { "active" } else { "inactive" }))
  W ("Definitions antivirus     : version " + $s.AntivirusSignatureVersion)
  $age = ((Get-Date) - $s.AntivirusSignatureLastUpdated).TotalDays
  W ("Derniere mise a jour      : " + $s.AntivirusSignatureLastUpdated.ToString("dd/MM/yyyy HH:mm") + "   (il y a {0:N1} jours)" -f $age)
  if ($age -gt 3) { W "   [!] Definitions anciennes. Lancer Windows Update." }
  if ($s.QuickScanEndTime) { W ("Dernier examen rapide     : " + $s.QuickScanEndTime.ToString("dd/MM/yyyy HH:mm")) }
  else { W "Dernier examen rapide     : jamais enregistre" }
  if ($s.FullScanEndTime) { W ("Dernier examen complet    : " + $s.FullScanEndTime.ToString("dd/MM/yyyy HH:mm")) }
  else { W "Dernier examen complet    : jamais enregistre" }

  $p = Get-MpPreference -ErrorAction SilentlyContinue
  W ""
  # La protection contre les logiciels indesirables est fournie avec
  # Windows mais desactivee d'origine. Elle vise les barres d'outils,
  # les nettoyeurs de registre et les publiciels, ce qui encombre le
  # plus souvent un PC familial.
  $pua = switch ("$($p.PUAProtection)") { "1" { "active" } "2" { "en observation seulement" } default { "DESACTIVEE" } }
  W ("Protection contre les logiciels indesirables : " + $pua)
  if ("$($p.PUAProtection)" -ne "1") {
    W "   Cette protection est livree avec Windows mais coupee par"
    W "   defaut. Elle bloque les barres d'outils, les faux"
    W "   nettoyeurs et les publiciels, qui encombrent un PC bien"
    W "   plus souvent que les vrais virus. Elle ne coute rien en"
    W "   performance : c'est le meme moteur qui travaille."
  }
}

# ---------- 3. Menaces detectees ----------
T "MENACES DETECTEES PAR LE PASSE"
$m = @(Get-MpThreatDetection -ErrorAction SilentlyContinue | Sort-Object InitialDetectionTime -Descending | Select-Object -First 15)
if ($m.Count -eq 0) { W "Aucune detection enregistree dans l'historique de Defender." }
else {
  foreach ($x in $m) {
    $nom = (Get-MpThreat -ThreatID $x.ThreatID -ErrorAction SilentlyContinue).ThreatName
    W ("   " + $x.InitialDetectionTime.ToString("dd/MM/yyyy") + "   " + $nom + "   action : " + $x.ThreatStatusID)
  }
}

# ---------- 4. Extensions de navigateur ----------
T "EXTENSIONS DE NAVIGATEUR"
W "Une extension a acces a tout ce que vous voyez et tapez dans le"
W "navigateur. C'est la porte d'entree la plus frequente aujourd'hui,"
W "loin devant le virus classique."
W ""
foreach ($n in @(
  @("Chrome", (Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Default\Extensions")),
  @("Edge",   (Join-Path $env:LOCALAPPDATA "Microsoft\Edge\User Data\Default\Extensions")))) {
  if (-not (Test-Path -LiteralPath $n[1])) { continue }
  W ("--- " + $n[0])
  foreach ($d in @(Get-ChildItem -LiteralPath $n[1] -Directory -ErrorAction SilentlyContinue)) {
    $v = @(Get-ChildItem -LiteralPath $d.FullName -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1)
    if ($v.Count -eq 0) { continue }
    $nom = NomExtension $v[0].FullName
    if (-not $nom) { $nom = "(illisible)" }
    W ("    " + $nom)
    W ("       identifiant " + $d.Name)
  }
  W ""
}
W "Verification : dans Chrome, menu a trois points, Extensions,"
W "Gerer les extensions. Tout ce qui n'est pas reconnu se supprime."
W "Chercher l'identifiant sur internet en cas de doute."

# ---------- 5. Logiciels non maintenus ----------
T "LOGICIELS QUI NE RECOIVENT PLUS DE CORRECTIFS"
W "Un logiciel abandonne par son editeur est un risque plus concret"
W "qu'un virus hypothetique : les failles connues n'y sont jamais"
W "corrigees."
W ""
$vieux = @(
  @("OpenOffice",        "Derniere version en 2015. LibreOffice le remplace, ouvre les memes fichiers, et reste mis a jour."),
  @("Adobe Flash",       "Abandonne en 2020, a desinstaller sans hesiter."),
  @("Java 6",            "Tres ancien, a desinstaller si aucun logiciel ne l'exige."),
  @("Java 7",            "Tres ancien, a desinstaller si aucun logiciel ne l'exige."),
  @("QuickTime",         "Abandonne sur Windows depuis 2016."),
  @("Adobe Reader X",    "Version depassee, le lecteur PDF de Windows suffit."),
  @("Internet Explorer", "Ne doit plus servir a naviguer.")
)
$paths = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
           'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')
$inst = @(Get-ItemProperty $paths -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName })
$trouve = $false
foreach ($v in $vieux) {
  foreach ($i in $inst) {
    if ($i.DisplayName -like ("*" + $v[0] + "*")) {
      $trouve = $true
      W ("[!] " + $i.DisplayName)
      W ("    " + $v[1])
      break
    }
  }
}
if (-not $trouve) { W "[ok] Aucun logiciel connu pour etre abandonne." }

# ---------- 6. Actions ----------
Write-Host ""
Write-Host "  QUE VOULEZ-VOUS FAIRE ?" -ForegroundColor Cyan
Write-Host ""
Write-Host "   1  Activer la protection contre les logiciels indesirables" -ForegroundColor White
Write-Host "      Reglage integre a Windows, sans cout en performance."
Write-Host ""
Write-Host "   2  Lancer un examen rapide de Defender" -ForegroundColor White
Write-Host "      Quelques minutes. Verifie la memoire et les endroits"
Write-Host "      ou se logent les infections."
Write-Host ""
Write-Host "   3  Lancer un examen complet" -ForegroundColor White
Write-Host "      Plusieurs heures sur un disque mecanique. A lancer le"
Write-Host "      soir, et la machine restera lente pendant ce temps."
Write-Host ""
Write-Host "   4  Les deux premiers" -ForegroundColor White
Write-Host ""
Write-Host "   N  Ne rien faire" -ForegroundColor White
Write-Host ""
$c = (Read-Host "  Votre choix (1 / 2 / 3 / 4 / N)").Trim().ToUpper()
W ""
W ("Choix : " + $c)

if ($c -eq "1" -or $c -eq "4") {
  if (-not $adm) { W "Sans droits administrateur ce reglage est impossible." }
  else {
    Set-MpPreference -PUAProtection Enabled -ErrorAction SilentlyContinue
    $v = "$((Get-MpPreference).PUAProtection)"
    if ($v -eq "1") { W "Protection contre les logiciels indesirables : ACTIVEE." }
    else { W "Echec de l'activation." }
  }
}
if ($c -eq "2" -or $c -eq "4") {
  W "Examen rapide en cours, laissez la fenetre ouverte..."
  Write-Host "  Examen rapide en cours..." -ForegroundColor Yellow
  Start-MpScan -ScanType QuickScan -ErrorAction SilentlyContinue
  $r = @(Get-MpThreatDetection -ErrorAction SilentlyContinue | Where-Object { $_.InitialDetectionTime -gt (Get-Date).AddMinutes(-30) })
  if ($r.Count -eq 0) { W "Examen termine, rien trouve." }
  else { W ("Examen termine, " + $r.Count + " detection(s). Voir l'application Securite Windows.") }
}
if ($c -eq "3") {
  W "Examen complet lance en arriere-plan."
  Start-Process powershell -ArgumentList "-NoProfile","-Command","Start-MpScan -ScanType FullScan" -WindowStyle Hidden
  W "Il continuera apres la fermeture de cette fenetre. Suivre son"
  W "avancement dans l'application Securite Windows."
}

$out = Join-Path $bureau ("Securite-" + (Get-Date -Format "yyyy-MM-dd-HHmm") + ".txt")
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
