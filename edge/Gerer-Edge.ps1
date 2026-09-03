# ==========================================================
#  EDGE : SAUVEGARDER, NEUTRALISER OU DESINSTALLER
#  ATTENTION : ce script MODIFIE la machine si vous le
#  demandez. Il commence par un constat en lecture seule et
#  par la sauvegarde des favoris, avant toute autre chose.
#  Il ne touche jamais a WebView2, dont d'autres logiciels
#  ont besoin pour fonctionner.
# ==========================================================

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference    = "SilentlyContinue"

$L = New-Object System.Collections.ArrayList
function W($t){ [void]$L.Add([string]$t); Write-Host $t }
function CheminBureau {
  $reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
  $b = (Get-ItemProperty -Path $reg -Name "Desktop" -ErrorAction SilentlyContinue).Desktop
  if ($b) { $b = [Environment]::ExpandEnvironmentVariables($b) }
  foreach ($c in @($b, [Environment]::GetFolderPath("Desktop"), (Join-Path $env:USERPROFILE "Desktop"))) {
    if ($c -and (Test-Path -LiteralPath $c)) { return $c }
  }
  return $env:TEMP
}
function EchapHtml($t){
  if ($t -eq $null) { return "" }
  return ($t -replace "&","&amp;" -replace "<","&lt;" -replace ">","&gt;" -replace '"',"&quot;")
}

# Convertit l'arborescence des favoris en fichier .html au format
# historique Netscape : c'est le seul format que tous les navigateurs
# savent reimporter. Le fichier brut de Edge, lui, ne se reimporte pas.
function NoeudVersHtml($noeud, $niveau){
  $ind = "    " * $niveau
  $s = ""
  foreach ($n in $noeud) {
    if ($n.type -eq "folder") {
      $s += $ind + "<DT><H3>" + (EchapHtml $n.name) + "</H3>`r`n"
      $s += $ind + "<DL><p>`r`n"
      if ($n.children) { $s += NoeudVersHtml $n.children ($niveau + 1) }
      $s += $ind + "</DL><p>`r`n"
    } elseif ($n.type -eq "url") {
      $s += $ind + '<DT><A HREF="' + (EchapHtml $n.url) + '">' + (EchapHtml $n.name) + "</A>`r`n"
    }
  }
  return $s
}
function CompteUrls($noeud){
  $n = 0
  foreach ($x in $noeud) {
    if ($x.type -eq "url") { $n++ }
    elseif ($x.children) { $n += CompteUrls $x.children }
  }
  return $n
}

try {

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  MICROSOFT EDGE" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Etape 1 : constat et sauvegarde des favoris." -ForegroundColor Yellow
Write-Host "  Rien ne sera modifie avant votre confirmation." -ForegroundColor Yellow
Write-Host ""

$bureau = CheminBureau
$adm = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
       ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

W "=========================================================="
W "  EDGE : CONSTAT"
W ("  " + $env:COMPUTERNAME + " / " + $env:USERNAME + "   " + (Get-Date -Format "dd/MM/yyyy HH:mm"))
W ("  Mode administrateur : " + $(if ($adm) { "oui" } else { "non" }))
W "=========================================================="
W ""

# ---------- Windows ----------
$dv = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').DisplayVersion
$os = Get-CimInstance Win32_OperatingSystem
W ("Windows : " + $os.Caption + "   version " + $dv + "   build " + $os.BuildNumber)
$region = (Get-ItemProperty 'HKCU:\Control Panel\International\Geo' -ErrorAction SilentlyContinue).Name
W ("Region declaree : " + $region)
W ""

# ---------- Edge ----------
$edgeExe = @(
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
  "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if ($edgeExe) {
  $ver = (Get-Item -LiteralPath $edgeExe).VersionInfo.ProductVersion
  W ("Edge installe : version " + $ver)
  W ("   " + $edgeExe)
} else {
  W "Edge ne semble pas installe sur cette machine."
}
$procEdge = @(Get-Process -Name "msedge" -ErrorAction SilentlyContinue)
if ($procEdge.Count -gt 0) {
  $mo = [math]::Round(($procEdge | Measure-Object WorkingSet64 -Sum).Sum/1MB,0)
  W ("Edge tourne en ce moment : " + $procEdge.Count + " processus, " + $mo + " Mo")
} else {
  W "Edge n'est pas en cours d'execution."
}
W ""

# ---------- WebView2, a ne surtout pas toucher ----------
$wv = @()
foreach ($p in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')) {
  $wv += @(Get-ItemProperty $p -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*WebView2*" })
}
if ($wv.Count -gt 0) {
  W "[!] WebView2 est installe sur cette machine."
  foreach ($w in ($wv | Select-Object -Unique DisplayName)) { W ("    " + $w.DisplayName) }
  W "    C'est un composant SEPARE d'Edge, utilise par d'autres"
  W "    logiciels pour afficher des pages web dans leurs fenetres."
  W "    Ce script n'y touche pas, et il ne faut pas y toucher :"
  W "    le supprimer casse des applications qui n'ont rien a voir"
  W "    avec le navigateur."
} else {
  W "WebView2 non detecte."
}
W ""

# ---------- Navigateur par defaut ----------
$prog = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice' -ErrorAction SilentlyContinue).ProgId
W ("Navigateur par defaut pour https : " + $(if ($prog) { $prog } else { "non lisible" }))
if ($prog -like "*Edge*" -or $prog -like "*MSEdge*") {
  W "[!] Edge est le navigateur PAR DEFAUT."
  W "    A changer avant toute suppression, sinon les liens des"
  W "    mails et des documents n'ouvriront plus rien."
  W "    Parametres, Applications, Applications par defaut, Chrome."
}
W ""

# ---------- Sauvegarde des favoris ----------
W "--- SAUVEGARDE DES FAVORIS EDGE ---"
$profils = @(Get-ChildItem (Join-Path $env:LOCALAPPDATA "Microsoft\Edge\User Data") -Directory -ErrorAction SilentlyContinue |
             Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "Bookmarks") })
if ($profils.Count -eq 0) {
  W "Aucun fichier de favoris Edge trouve. Rien a sauvegarder."
} else {
  $dest = Join-Path $bureau ("Favoris-Edge-" + (Get-Date -Format "yyyy-MM-dd-HHmm"))
  New-Item -ItemType Directory -Path $dest -Force | Out-Null
  foreach ($p in $profils) {
    $src = Join-Path $p.FullName "Bookmarks"
    Copy-Item -LiteralPath $src -Destination (Join-Path $dest ($p.Name + "-Bookmarks.json")) -Force -ErrorAction SilentlyContinue
    try {
      $j = Get-Content -LiteralPath $src -Raw -Encoding UTF8 | ConvertFrom-Json
      $html = "<!DOCTYPE NETSCAPE-Bookmark-file-1>`r`n"
      $html += '<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">' + "`r`n"
      $html += "<TITLE>Favoris Edge</TITLE>`r`n<H1>Favoris Edge</H1>`r`n<DL><p>`r`n"
      $n = 0
      foreach ($racine in @("bookmark_bar","other","synced")) {
        $r = $j.roots.$racine
        if ($r -and $r.children) {
          $html += "    <DT><H3>" + (EchapHtml $r.name) + "</H3>`r`n    <DL><p>`r`n"
          $html += NoeudVersHtml $r.children 2
          $html += "    </DL><p>`r`n"
          $n += CompteUrls $r.children
        }
      }
      $html += "</DL><p>`r`n"
      $fh = Join-Path $dest ($p.Name + "-favoris.html")
      $html | Out-File -FilePath $fh -Encoding UTF8
      W ("Profil " + $p.Name + " : " + $n + " favoris exportes")
      W ("   " + $fh)
    } catch {
      W ("Profil " + $p.Name + " : copie brute faite, conversion html impossible")
    }
  }
  W ""
  W "Le fichier .html se reimporte dans Chrome : menu, Favoris,"
  W "Importer les favoris, Fichier HTML de favoris."
  W "A faire AVANT de supprimer quoi que ce soit."
}
W ""

# ---------- Ce qu'il faut savoir ----------
W "----------------------------------------------------------"
W "CE QU'IL FAUT SAVOIR AVANT DE CHOISIR"
W ""
W "Edge n'est pas un logiciel comme les autres : Windows s'en"
W "sert pour afficher certaines de ses propres pages. Depuis"
W "2024, la reglementation europeenne oblige Microsoft a le"
W "rendre desinstallable, mais uniquement sur un Windows a jour"
W "et declare dans une region europeenne. Les deux valeurs sont"
W "affichees plus haut."
W ""
W "Si le bouton Desinstaller est grisee dans Parametres, forcer"
W "la suppression par des commandes internes est possible mais"
W "casse regulierement Windows Update, et Edge revient a la"
W "mise a jour suivante. Ce script ne le fera pas."
W ""
W "En pratique, un Edge qui ne demarre plus tout seul et qui ne"
W "precharge plus rien ne coute quasiment rien a la machine."
W "C'est ce que fait l'option N, sans aucun risque."
W "----------------------------------------------------------"
W ""

Write-Host ""
Write-Host "  QUE VOULEZ-VOUS FAIRE ?" -ForegroundColor Cyan
Write-Host ""
Write-Host "   N  Neutraliser Edge (recommande, reversible)" -ForegroundColor White
Write-Host "      Coupe le demarrage automatique, le prechargement au"
Write-Host "      lancement de Windows et l'execution en arriere-plan."
Write-Host "      Edge reste installe et utilisable si besoin."
Write-Host ""
Write-Host "   D  Ouvrir la desinstallation officielle" -ForegroundColor White
Write-Host "      Ouvre la fenetre Windows des applications installees."
Write-Host "      Si le bouton Desinstaller est actif, la suppression"
Write-Host "      se fait proprement de la."
Write-Host ""
Write-Host "   R  Ne rien faire, garder le constat et les favoris" -ForegroundColor White
Write-Host ""
$choix = (Read-Host "  Votre choix (N / D / R)").Trim().ToUpper()
W ""
W ("Choix : " + $choix)

if ($choix -eq "N") {
  W ""
  W "--- NEUTRALISATION ---"
  $racine = if ($adm) { "HKLM:\SOFTWARE\Policies\Microsoft\Edge" } else { "HKCU:\SOFTWARE\Policies\Microsoft\Edge" }
  if (-not (Test-Path $racine)) { New-Item -Path $racine -Force | Out-Null }
  Set-ItemProperty -Path $racine -Name "StartupBoostEnabled"    -Value 0 -Type DWord
  Set-ItemProperty -Path $racine -Name "BackgroundModeEnabled"  -Value 0 -Type DWord
  W ("1. Prechargement au demarrage et execution en arriere-plan")
  W ("   desactives dans " + $racine)
  if (-not $adm) {
    W "   (pose pour cet utilisateur : la fenetre n'est pas en mode"
    W "    administrateur. C'est suffisant dans la majorite des cas.)"
  }

  Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "MicrosoftEdgeAutoLaunch*" -ErrorAction SilentlyContinue
  Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" | Get-Member -MemberType NoteProperty |
    Where-Object { $_.Name -like "*Edge*" } | ForEach-Object {
      Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $_.Name -ErrorAction SilentlyContinue
      W ("2. Lancement automatique supprime : " + $_.Name)
    }

  # On compte ce qui a reellement bascule, pas ce qu'on a essaye :
  # sans droits administrateur la desactivation echoue en silence.
  $n = 0
  Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like "*Edge*" -and $_.TaskName -notlike "*Update*" } | ForEach-Object {
    $r = Disable-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath -ErrorAction SilentlyContinue
    if ($r -and $r.State -eq "Disabled") { $n++ }
  }
  W ("3. " + $n + " tache(s) planifiee(s) Edge desactivee(s)")
  if ($n -eq 0 -and -not $adm) { W "   (sans droits administrateur c'est normal, et sans gravite)" }
  W ""
  W "Les taches de MISE A JOUR d'Edge sont volontairement laissees"
  W "en place : un navigateur installe mais plus mis a jour est un"
  W "trou de securite, meme s'il ne sert jamais."
  W ""
  W "Pour revenir en arriere : supprimer la cle"
  W ("   " + $racine)
  W "avec l'editeur de registre, et redemarrer."
}

elseif ($choix -eq "D") {
  W ""
  W "--- DESINSTALLATION OFFICIELLE ---"
  W "Ouverture de la liste des applications installees."
  W ""
  W "Chercher 'Microsoft Edge' dans la liste, cliquer sur les trois"
  W "points, puis Desinstaller."
  W ""
  W "Si le bouton est grise, la desinstallation n'est pas autorisee"
  W "sur cette configuration. Ne pas insister par d'autres moyens :"
  W "revenir sur l'option N, qui donne le meme confort sans risque."
  Start-Process "ms-settings:appsfeatures" -ErrorAction SilentlyContinue
  W ""
  W "Rappel : les favoris viennent d'etre exportes sur le Bureau."
}

else { W ""; W "Aucune modification effectuee. Les favoris sont exportes." }

$out = Join-Path $bureau ("Edge-" + (Get-Date -Format "yyyy-MM-dd-HHmm") + ".txt")
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
