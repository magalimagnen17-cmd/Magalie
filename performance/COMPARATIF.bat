@echo off
title Comparatif de performance avant / apres
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
set "PS1=%TEMP%\Comparatif-Performance.ps1"
set "PWSH=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PWSH%" set "PWSH=powershell.exe"
more +34 "%~f0" > "%PS1%"
if not exist "%PS1%" goto ERR
findstr /c:"COMPARATIF DE PERFORMANCE AVANT / APRES" "%PS1%" >nul || goto ERR
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
#  COMPARATIF DE PERFORMANCE AVANT / APRES
#  Trois sources, de la plus objective a la plus volatile :
#  1. l'historique des demarrages, enregistre par Windows
#     lui-meme depuis des semaines, donc non rejouable ;
#  2. la comparaison des rapports de diagnostic trouves
#     sur le Bureau ;
#  3. une mesure de vitesse disque et processeur du moment.
#  Le seul fichier ecrit est un fichier de test temporaire,
#  supprime aussitot. Rien d'autre n'est modifie.
# ==========================================================

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference    = "SilentlyContinue"

$L = New-Object System.Collections.ArrayList
function W($t){ [void]$L.Add([string]$t) }
function T($t){ [void]$L.Add(""); [void]$L.Add("=== $t ===") }
function CheminBureau {
  $reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
  $b = (Get-ItemProperty -Path $reg -Name "Desktop" -ErrorAction SilentlyContinue).Desktop
  if ($b) { $b = [Environment]::ExpandEnvironmentVariables($b) }
  foreach ($c in @($b, [Environment]::GetFolderPath("Desktop"), (Join-Path $env:USERPROFILE "Desktop"))) {
    if ($c -and (Test-Path -LiteralPath $c)) { return $c }
  }
  return $env:TEMP
}
function Num($t){
  if (-not $t) { return $null }
  return [double]($t -replace ",",".")
}

# Lit un rapport Diagnostic-PC et en extrait les indicateurs.
# Fonctionne sur l'ancien format comme sur le nouveau : les deux
# partagent les memes libelles de section.
function LireRapport($chemin){
  $r = New-Object PSObject -Property @{
    Fichier=(Split-Path $chemin -Leaf); Date=(Get-Item -LiteralPath $chemin).LastWriteTime
    Windows=$null; Uptime=$null; RamTotale=$null; RamUtil=$null; Cpu=$null
    Disque=$null; CLibre=$null; CTotal=$null; CPct=$null
    Demarrage=0; Logiciels=0; Antivirus=0; Erreurs=0; Alim=$null }
  $section = ""
  foreach ($l in (Get-Content -LiteralPath $chemin -Encoding UTF8)) {
    if ($l -match "^--- (\d+)\.")                      { $section = $matches[1]; continue }
    if ($l -match "^Windows\s+:\s*(.+)$")              { $r.Windows = $matches[1].Trim() }
    if ($l -match "^Allume depuis\s+:\s*([\d,\.]+) j") { $r.Uptime = Num $matches[1] }
    if ($l -match "^RAM totale\s+:\s*([\d,\.]+)")      { $r.RamTotale = Num $matches[1] }
    if ($l -match "^RAM utilisee\s+:\s*(\d+)")         { $r.RamUtil = [int]$matches[1] }
    if ($l -match "^Charge actuelle\s+:\s*(\d+)")      { $r.Cpu = [int]$matches[1] }
    if ($l -match "Type\s+:\s*(\S+)\s+<<<")            { $r.Disque = $matches[1] }
    if ($l -match "^\s+C: ([\d,\.]+) Go libres sur ([\d,\.]+) Go\s+\((\d+)") {
      $r.CLibre = Num $matches[1]; $r.CTotal = Num $matches[2]; $r.CPct = [int]$matches[3] }
    if ($l -match "GUID.*:\s*\((.+)\)")                { $r.Alim = $matches[1] }
    if ($section -eq "5"  -and $l -match "^\s+- ")     { $r.Demarrage++ }
    if ($section -eq "8"  -and $l -match "^\s+- ")     { $r.Antivirus++ }
    if ($section -eq "10" -and $l -match "^\s+- ")     { $r.Logiciels++ }
    if ($section -eq "12" -and $l -match "^\s+(\d+) x ") { $r.Erreurs += [int]$matches[1] }
  }
  return $r
}

function Ecart($avant, $apres, $unite, $mieuxSiBas){
  if ($avant -eq $null -or $apres -eq $null) { return "" }
  $d = $apres - $avant
  if ([math]::Abs($d) -lt 0.05) { return "identique" }
  $signe = if ($d -gt 0) { "+" } else { "" }
  $sens = ""
  if ($mieuxSiBas -ne $null) {
    if (($d -lt 0 -and $mieuxSiBas) -or ($d -gt 0 -and -not $mieuxSiBas)) { $sens = "  mieux" }
    else { $sens = "  moins bien" }
  }
  return ("{0}{1:N1} {2}{3}" -f $signe, $d, $unite, $sens)
}

try {

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  COMPARATIF DE PERFORMANCE AVANT / APRES" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$bureau = CheminBureau
$adm = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
       ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

W "=========================================================="
W "  COMPARATIF DE PERFORMANCE"
W ("  " + $env:COMPUTERNAME + " / " + $env:USERNAME + "   " + (Get-Date -Format "dd/MM/yyyy HH:mm"))
W "=========================================================="

# ---------- 1. Historique des demarrages ----------
Write-Host "  1/3  Historique des demarrages de Windows..." -ForegroundColor Gray
T "DUREE DES DEMARRAGES, MESUREE PAR WINDOWS"
W "Windows chronometre chacun de ses demarrages et garde l'historique."
W "C'est la mesure la plus honnete qui soit ici : elle a ete prise"
W "avant que quiconque songe a nettoyer la machine, elle ne peut pas"
W "avoir ete influencee, et elle mesure ce que l'on ressent vraiment."
W ""
$ev = @(Get-WinEvent -FilterHashtable @{
          LogName='Microsoft-Windows-Diagnostics-Performance/Operational'; Id=100
        } -MaxEvents 60 -ErrorAction SilentlyContinue)
if ($ev.Count -eq 0) {
  W "Historique illisible."
  if (-not $adm) { W "La fenetre n'est pas en mode administrateur : ce journal l'exige." }
  else { W "Le journal de diagnostic de performance est peut-etre desactive sur ce poste." }
} else {
  $boots = @()
  foreach ($e in $ev) {
    $x = [xml]$e.ToXml()
    $d = $x.Event.EventData.Data
    $bt = ($d | Where-Object { $_.Name -eq 'BootTime' }).'#text'
    $mp = ($d | Where-Object { $_.Name -eq 'MainPathBootTime' }).'#text'
    if ($bt) {
      $boots += New-Object PSObject -Property @{
        Date=$e.TimeCreated; Total=[int]$bt/1000; Bureau=[int]$mp/1000 }
    }
  }
  $boots = @($boots | Sort-Object Date)
  W ("{0,-20} {1,12} {2,12}" -f "Demarrage", "Jusqu'au", "Total")
  W ("{0,-20} {1,12} {2,12}" -f "", "bureau", "")
  W ("-" * 46)
  foreach ($b in $boots) {
    W ("{0,-20} {1,9:N1} s {2,9:N1} s" -f $b.Date.ToString("dd/MM/yyyy HH:mm"), $b.Bureau, $b.Total)
  }
  W ""
  if ($boots.Count -ge 4) {
    $n = [math]::Max(2, [math]::Floor($boots.Count / 3))
    $vieux = $boots | Select-Object -First $n
    $neufs = $boots | Select-Object -Last $n
    $mv = ($vieux | Measure-Object Bureau -Average).Average
    $mn = ($neufs | Measure-Object Bureau -Average).Average
    W ("Moyenne des " + $n + " premiers demarrages enregistres : {0:N1} s" -f $mv)
    W ("Moyenne des " + $n + " derniers                        : {0:N1} s" -f $mn)
    if ($mv -gt 0) {
      $g = [math]::Round(($mv - $mn) / $mv * 100, 0)
      W ""
      if ($g -gt 5)      { W ("-> Demarrage plus rapide de " + $g + " %, soit {0:N0} secondes gagnees." -f ($mv - $mn)) }
      elseif ($g -lt -5) { W ("-> Demarrage plus lent de " + [math]::Abs($g) + " %.") }
      else               { W "-> Pas d'ecart significatif sur le temps de demarrage." }
    }
  } else {
    W "Trop peu de demarrages enregistres pour degager une tendance."
    W "Redemarrer deux ou trois fois donnera de quoi comparer."
  }
}

# ---------- 2. Rapports de diagnostic ----------
Write-Host "  2/3  Rapports de diagnostic..." -ForegroundColor Gray
T "COMPARAISON DES RAPPORTS DE DIAGNOSTIC"
$fics = @(Get-ChildItem -LiteralPath $bureau -Filter "Diagnostic-PC*.txt" -File -ErrorAction SilentlyContinue |
          Sort-Object LastWriteTime)
if ($fics.Count -lt 2) {
  W ("Un seul rapport trouve sur le Bureau (" + $fics.Count + ").")
  W "Il en faut deux pour comparer : lancer DIAGNOSTIC-PC.bat"
  W "maintenant produira le rapport d'apres. Le rapport d'avant est"
  W "celui qui a ete genere avant le nettoyage."
  foreach ($f in $fics) { W ("   " + $f.LastWriteTime.ToString("dd/MM/yyyy HH:mm") + "   " + $f.Name) }
} else {
  $a = LireRapport $fics[0].FullName
  $b = LireRapport $fics[-1].FullName
  W ("Avant : " + $a.Fichier + "   (" + $a.Date.ToString("dd/MM/yyyy HH:mm") + ")")
  W ("Apres : " + $b.Fichier + "   (" + $b.Date.ToString("dd/MM/yyyy HH:mm") + ")")
  W ""
  W "--- Ce qui a change durablement ---"
  W ("{0,-34} {1,12} {2,12}   {3}" -f "", "avant", "apres", "ecart")
  W ("{0,-34} {1,12} {2,12}   {3}" -f "Programmes au demarrage", $a.Demarrage, $b.Demarrage, (Ecart $a.Demarrage $b.Demarrage "" $true))
  W ("{0,-34} {1,12} {2,12}   {3}" -f "Logiciels installes",     $a.Logiciels, $b.Logiciels, (Ecart $a.Logiciels $b.Logiciels "" $true))
  W ("{0,-34} {1,12} {2,12}   {3}" -f "Antivirus declares",      $a.Antivirus, $b.Antivirus, (Ecart $a.Antivirus $b.Antivirus "" $true))
  W ("{0,-34} {1,12} {2,12}   {3}" -f "Espace libre sur C: (Go)", $a.CLibre, $b.CLibre, (Ecart $a.CLibre $b.CLibre "Go" $false))
  W ("{0,-34} {1,12} {2,12}   {3}" -f "Erreurs systeme sur 7 jours", $a.Erreurs, $b.Erreurs, (Ecart $a.Erreurs $b.Erreurs "" $true))
  W ""
  W "--- Ce qui ne se compare pas ---"
  W "Ces valeurs dependent de ce qui tournait a l'instant de la mesure."
  W "Elles sont donnees pour information, pas comme un resultat."
  W ("{0,-34} {1,12} {2,12}" -f "Charge processeur (%)", $a.Cpu, $b.Cpu)
  W ("{0,-34} {1,12} {2,12}" -f "Memoire utilisee (%)",  $a.RamUtil, $b.RamUtil)
  W ("{0,-34} {1,12} {2,12}" -f "Allume depuis (jours)", $a.Uptime, $b.Uptime)
  W ""
  W "--- Ce qui n'a pas bouge, et ne bougera pas ---"
  W ("Type de disque : " + $(if ($b.Disque) { $b.Disque } else { "inconnu" }))
  W ("Memoire vive   : " + $(if ($b.RamTotale) { "$($b.RamTotale) Go" } else { "inconnue" }))
  W "Ce sont les deux limites materielles de la machine. Aucun"
  W "nettoyage ne les change."
}

# ---------- 3. Mesures du moment ----------
Write-Host "  3/3  Mesure de vitesse (disque et processeur)..." -ForegroundColor Gray
T "VITESSE MESUREE MAINTENANT"
$test = Join-Path $env:TEMP ("perf-" + [guid]::NewGuid().ToString("N") + ".tmp")
$bloc = New-Object byte[] (4MB)
(New-Object Random).NextBytes($bloc)
$nbBlocs = 25   # 100 Mo

try {
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  $fs = [System.IO.File]::Create($test)
  for ($i = 0; $i -lt $nbBlocs; $i++) { $fs.Write($bloc, 0, $bloc.Length) }
  $fs.Flush($true)
  $fs.Close()
  $sw.Stop()
  $ecr = 100 / $sw.Elapsed.TotalSeconds
  W ("Ecriture de 100 Mo : {0,6:N0} Mo/s" -f $ecr)

  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  $fs = [System.IO.File]::OpenRead($test)
  $buf = New-Object byte[] (4MB)
  while ($fs.Read($buf, 0, $buf.Length) -gt 0) { }
  $fs.Close()
  $sw.Stop()
  $lec = 100 / $sw.Elapsed.TotalSeconds
  W ("Lecture  de 100 Mo : {0,6:N0} Mo/s" -f $lec)
} catch {
  W ("Mesure disque impossible : " + $_.Exception.Message)
  $ecr = $null; $lec = $null
} finally {
  Remove-Item -LiteralPath $test -Force -ErrorAction SilentlyContinue
}

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$md5 = [System.Security.Cryptography.MD5]::Create()
for ($i = 0; $i -lt 40; $i++) { $null = $md5.ComputeHash($bloc) }
$sw.Stop()
$cpu = 160 / $sw.Elapsed.TotalSeconds
W ("Calcul processeur  : {0,6:N0} Mo/s traites" -f $cpu)
W ""
W "Reperes pour le disque, en lecture :"
W "   disque mecanique (HDD)   :   80 a 120 Mo/s"
W "   SSD sur port SATA        :  400 a 550 Mo/s"
W "   SSD NVMe                 : 1500 Mo/s et au-dela"
if ($lec) {
  W ""
  if ($lec -lt 200)      { W "-> Mesure typique d'un disque mecanique. C'est le premier"
                           W "   facteur de lenteur d'un PC, et le seul que le nettoyage"
                           W "   ne peut pas corriger. Un SSD change tout, bien plus que"
                           W "   n'importe quel reglage." }
  elseif ($lec -lt 700)  { W "-> Mesure typique d'un SSD SATA. Le disque n'est pas le"
                           W "   facteur limitant de cette machine." }
  else                   { W "-> Mesure typique d'un SSD NVMe. Le disque est rapide." }
}

# ---------- Sortie ----------
$out = Join-Path $bureau ("Comparatif-Performance-" + (Get-Date -Format "yyyy-MM-dd-HHmm") + ".txt")
$texte = $L -join "`r`n"
$ecrit = $false
foreach ($cible in @($out, (Join-Path $env:TEMP "Comparatif-Performance.txt"))) {
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
