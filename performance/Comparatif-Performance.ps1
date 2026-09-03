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
  # La coupure se fait a la date de l'intervention, pas en decoupant
  # l'historique en tiers : comparer 2024 a 2026 mesurerait le
  # vieillissement de la machine, pas l'effet du nettoyage.
  $charniere = $null
  $dg = @(Get-ChildItem -LiteralPath $bureau -Filter "Diagnostic-PC*.txt" -File -ErrorAction SilentlyContinue |
          Sort-Object LastWriteTime)
  if ($dg.Count -gt 0) {
    $charniere = $dg[0].LastWriteTime
    W ("Date de reference : " + $charniere.ToString("dd/MM/yyyy HH:mm"))
    W ("d'apres le premier rapport de diagnostic, " + $dg[0].Name + ",")
    W "genere juste avant l'intervention."
  } else {
    Write-Host ""
    Write-Host "  A quelle date la machine a-t-elle ete nettoyee ?" -ForegroundColor Yellow
    Write-Host "  Format JJ/MM/AAAA, ou Entree pour prendre hier." -ForegroundColor Yellow
    $rep = (Read-Host "  ").Trim()
    if ($rep) { $charniere = [datetime]::ParseExact($rep, "dd/MM/yyyy", $null) }
    if (-not $charniere) { $charniere = (Get-Date).AddDays(-1).Date }
    W ("Date de reference saisie : " + $charniere.ToString("dd/MM/yyyy"))
  }
  W ""

  $avant = @($boots | Where-Object { $_.Date -lt $charniere })
  $apres = @($boots | Where-Object { $_.Date -ge $charniere })

  function Mediane($v){
    $t = @($v | Sort-Object)
    if ($t.Count -eq 0) { return $null }
    if ($t.Count % 2 -eq 1) { return $t[[math]::Floor($t.Count/2)] }
    return ($t[$t.Count/2 - 1] + $t[$t.Count/2]) / 2
  }

  if ($apres.Count -eq 0) {
    W "Aucun demarrage enregistre depuis cette date."
    W "Redemarrer la machine deux ou trois fois donnera de quoi comparer."
  } elseif ($avant.Count -eq 0) {
    W "Aucun demarrage enregistre avant cette date, comparaison impossible."
  } else {
    $medA = Mediane ($avant | ForEach-Object { $_.Bureau })
    $medP = Mediane ($apres | ForEach-Object { $_.Bureau })
    $dernierAvant = ($avant | Select-Object -Last 1).Bureau
    $dernierApres = ($apres | Select-Object -Last 1).Bureau

    W ("Avant : " + $avant.Count + " demarrages, mediane {0:N1} s" -f $medA)
    W ("Apres : " + $apres.Count + " demarrages, mediane {0:N1} s" -f $medP)
    W ""
    W ("Dernier demarrage avant l'intervention : {0:N1} s" -f $dernierAvant)
    W ("Dernier demarrage apres                : {0:N1} s" -f $dernierApres)
    W ""
    # La mediane resiste aux valeurs extremes, frequentes ici : une
    # mise a jour de Windows peut tripler un demarrage isole.
    if ($medA -gt 0) {
      $g = [math]::Round(($medA - $medP) / $medA * 100, 0)
      if ($g -gt 5)      { W ("-> Mediane amelioree de " + $g + " %, soit {0:N0} secondes." -f ($medA - $medP)) }
      elseif ($g -lt -5) { W ("-> Mediane degradee de " + [math]::Abs($g) + " %.") }
      else               { W "-> Mediane stable." }
    }
    $best = ($boots | Sort-Object Bureau | Select-Object -First 1)
    W ("Meilleur demarrage de tout l'historique : {0:N1} s, le {1}" -f $best.Bureau, $best.Date.ToString("dd/MM/yyyy"))
    W ""
    if ($apres.Count -lt 3) {
      W ("Reserve : " + $apres.Count + " demarrage(s) seulement depuis l'intervention.")
      W "Deux mesures ne font pas une tendance. Le premier redemarrage"
      W "apres un nettoyage est d'ailleurs toujours le plus lent, le"
      W "temps que Windows reconstruise ses caches. Redemarrer encore"
      W "deux ou trois fois donnera un resultat solide."
    }
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
# Get-PhysicalDisk dit le type de disque de facon fiable. Le
# chronometre qui suit ne sert qu'a confirmer un ordre de grandeur.
$pd = @(Get-PhysicalDisk -ErrorAction SilentlyContinue)
if ($pd.Count -gt 0) {
  foreach ($d in $pd) { W ("Disque declare par Windows : " + $d.FriendlyName + "   type " + $d.MediaType + "   sante " + $d.HealthStatus) }
} else {
  W "Type de disque illisible (droits administrateur necessaires)."
}
W ""

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

  # Relire le fichier qu'on vient d'ecrire mesurerait le cache memoire
  # de Windows, pas le disque : on lit un fichier deja present, assez
  # gros et non touche recemment.
  $lec = $null
  $cible = @(Get-ChildItem -LiteralPath "$env:SystemRoot\System32" -File -Filter "*.dll" -ErrorAction SilentlyContinue |
             Where-Object { $_.Length -gt 8MB } | Sort-Object Length -Descending | Select-Object -First 3)
  if ($cible.Count -gt 0) {
    $octets = 0
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    foreach ($c in $cible) {
      $fs = [System.IO.File]::OpenRead($c.FullName)
      $buf = New-Object byte[] (4MB)
      while ($fs.Read($buf, 0, $buf.Length) -gt 0) { }
      $fs.Close()
      $octets += $c.Length
    }
    $sw.Stop()
    $lec = ($octets/1MB) / $sw.Elapsed.TotalSeconds
    W ("Lecture  de {0,3:N0} Mo : {1,6:N0} Mo/s" -f ($octets/1MB), $lec)
    W "   (mesure sur des fichiers systeme deja presents ; si Windows"
    W "    les avait deja en memoire, ce chiffre est optimiste)"
  }
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
W ""
W "L'ecriture est la mesure la plus fiable des deux : elle force"
W "l'ecriture physique sur le disque, alors qu'une lecture peut"
W "toujours etre servie par la memoire. Une ecriture sous 100 Mo/s"
W "est le signe d'un disque mecanique, ou d'un SSD en fin de vie."
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
