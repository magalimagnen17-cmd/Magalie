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
$adm = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
       ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
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
$bureauCopie = CheminBureau
$proc = @(Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue)
if ($proc.Count -gt 0) {
  $mo = [math]::Round(($proc | Measure-Object WorkingSet64 -Sum).Sum/1MB,0)
  W ("OneDrive tourne : " + $proc.Count + " processus, " + $mo + " Mo de memoire")
} else {
  W "OneDrive n'est pas en cours d'execution."
}

# ---------- Installation ----------
# La UninstallString du registre fait foi : selon l'installation,
# OneDrive est pose par utilisateur ou pour toute la machine, et le
# desinstalleur n'est alors ni au meme endroit ni lancable pareil.
$candidats = @()
$portee = "inconnue"
foreach ($base in @(
    @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe", "utilisateur"),
    @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe", "machine"),
    @("HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe", "machine"))) {
  $u = (Get-ItemProperty -Path $base[0] -ErrorAction SilentlyContinue).UninstallString
  if ($u) {
    $portee = $base[1]
    $candidats += New-Object PSObject -Property @{ Ligne=$u; Source=("registre " + $base[1]) }
  }
}
foreach ($c in @(
    (Join-Path $env:SystemRoot "SysWOW64\OneDriveSetup.exe"),
    (Join-Path $env:SystemRoot "System32\OneDriveSetup.exe"),
    (Join-Path $env:LOCALAPPDATA "Microsoft\OneDrive\OneDriveSetup.exe"),
    (Join-Path $env:ProgramFiles "Microsoft OneDrive\OneDriveSetup.exe"),
    (Join-Path ${env:ProgramFiles(x86)} "Microsoft OneDrive\OneDriveSetup.exe"))) {
  if ($c -and (Test-Path -LiteralPath $c)) {
    $candidats += New-Object PSObject -Property @{ Ligne=('"' + $c + '" /uninstall'); Source="chemin standard" }
  }
}
# Installations rangees dans un sous-dossier de version
foreach ($d in @(Get-ChildItem (Join-Path $env:LOCALAPPDATA "Microsoft\OneDrive") -Directory -ErrorAction SilentlyContinue)) {
  $c = Join-Path $d.FullName "OneDriveSetup.exe"
  if (Test-Path -LiteralPath $c) {
    $candidats += New-Object PSObject -Property @{ Ligne=('"' + $c + '" /uninstall'); Source=("version " + $d.Name) }
  }
}
$setup = $null
if ($candidats.Count -gt 0) { $setup = $candidats[0].Ligne }
$exe = Join-Path $env:LOCALAPPDATA "Microsoft\OneDrive\OneDrive.exe"
if (Test-Path -LiteralPath $exe) {
  W ("Installe : " + $exe)
  W ("Version  : " + (Get-Item -LiteralPath $exe).VersionInfo.FileVersion)
} else {
  W "Aucun OneDrive.exe trouve dans le profil utilisateur."
}
W ("Portee de l'installation : " + $portee)
if ($candidats.Count -gt 0) {
  W ("Desinstalleurs trouves : " + $candidats.Count)
  foreach ($c in $candidats) { W ("   [" + $c.Source + "] " + $c.Ligne) }
} else {
  W "Aucun programme de desinstallation trouve."
}
if ($portee -eq "machine" -and -not $adm) {
  W ""
  W "[!] OneDrive est installe POUR TOUTE LA MACHINE et cette fenetre"
  W "    n'est pas en mode administrateur. La desinstallation va"
  W "    echouer en silence. Le script proposera de relancer en"
  W "    administrateur au moment voulu."
}
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
$pro = @()
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
  # "OneDrive - <Organisation>" est un espace professionnel Microsoft 365,
  # pas le OneDrive personnel. Les consequences ne sont pas les memes.
  $nom = Split-Path $d -Leaf
  if ($nom -match "^OneDrive\s*-\s*(.+)$") {
    W ("   ESPACE PROFESSIONNEL : " + $matches[1])
    $pro += New-Object PSObject -Property @{ Chemin=$d; Orga=$matches[1]; N=$nd; O=$od }
  }
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

if ($pro.Count -gt 0) {
  W "[!] UN COMPTE PROFESSIONNEL EST SYNCHRONISE SUR CE PC."
  foreach ($x in $pro) {
    W ("        " + $x.Orga + " : " + $x.N + " fichiers, " + (Go $x.O))
    W ("        " + $x.Chemin)
  }
  W ""
  W "        Desinstaller OneDrive coupe cette synchronisation. Les"
  W "        fichiers restent sur le disque, mais ce qui n'a pas"
  W "        encore ete envoye ne partira jamais vers l'organisation."
  W "        Or c'est justement le probleme : une synchronisation qui"
  W "        tourne en rond est une synchronisation qui n'aboutit pas."
  W ""
  W "        Avant de desinstaller, faire une copie de ce dossier."
  W "        Le script la propose."
  W ""
  W "        Et si la boucle vient de ce compte, session expiree ou"
  W "        acces retire par l'organisation, dissocier le compte"
  W "        (option L) suffit et laisse OneDrive en place."
  W ""
}

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
Write-Host "   L  Dissocier un compte, sans rien desinstaller" -ForegroundColor White
Write-Host "      Arrete la synchronisation d'un compte precis et laisse"
Write-Host "      ses fichiers sur le disque. La bonne reponse quand la"
Write-Host "      boucle vient d'un compte professionnel dont l'acces a"
Write-Host "      expire. Le script affiche les clics exacts."
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
$choix = (Read-Host "  Votre choix (R / L / D / N)").Trim().ToUpper()
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

# ---------- Dissociation ----------
elseif ($choix -eq "L") {
  W ""
  W "--- DISSOCIER UN COMPTE ---"
  W "Cette operation se fait dans l'interface de OneDrive, il n'y a"
  W "pas de commande fiable pour l'automatiser. Les clics exacts :"
  W ""
  W "1. Clic sur l'icone OneDrive, en bas a droite, pres de l'heure."
  W "   S'il y en a deux, celle du compte professionnel porte un"
  W "   petit logo d'entreprise."
  W "2. Roue dentee, puis Parametres."
  W "3. Onglet Compte."
  W "4. Sous le compte concerne : Supprimer le lien vers ce PC."
  W "5. Confirmer."
  W ""
  W "Ce qui se passe ensuite : la synchronisation s'arrete, les"
  W "fichiers deja telecharges restent sur le disque, et rien n'est"
  W "supprime en ligne. C'est reversible, il suffit de se reconnecter."
  if ($pro.Count -gt 0) {
    W ""
    W "Le compte a dissocier ici est vraisemblablement :"
    foreach ($x in $pro) { W ("   " + $x.Orga) }
  }
  W ""
  W "Ouverture des parametres de OneDrive."
  if (Test-Path -LiteralPath $exe) {
    Start-Process -FilePath $exe -ArgumentList "/settings" -ErrorAction SilentlyContinue
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
    Write-Host "  Confirmer la desinstallation de OneDrive ?" -ForegroundColor Yellow
    $c2 = (Read-Host "  Tapez OUI puis Entree").Trim().ToUpper()
    if (@("OUI","O","OK","YES","Y") -notcontains $c2) {
      W ("Reponse '" + $c2 + "' non reconnue, desinstallation annulee.")
      $choix = "N"
    }
  }

  if ($choix -eq "D" -and $pro.Count -gt 0) {
    Write-Host ""
    Write-Host "  Copier d'abord les dossiers professionnels sur le" -ForegroundColor Yellow
    Write-Host "  Bureau, par securite ? (O/N)" -ForegroundColor Yellow
    if ((Read-Host "  ").Trim().ToUpper() -eq "O") {
      foreach ($x in $pro) {
        $cible = Join-Path $bureauCopie ("Copie-" + ($x.Orga -replace '[\\/:*?"<>|]','-') + "-" + (Get-Date -Format "yyyy-MM-dd"))
        W ("Copie de " + $x.Chemin)
        W ("   vers   " + $cible)
        try {
          Copy-Item -LiteralPath $x.Chemin -Destination $cible -Recurse -Force -ErrorAction Stop
          $n2 = @(Get-ChildItem -LiteralPath $cible -Recurse -File -Force -ErrorAction SilentlyContinue).Count
          W ("   " + $n2 + " fichiers copies sur " + $x.N + " attendus")
          if ($n2 -lt $x.N) { W "   [!] Copie incomplete, ne pas desinstaller en l'etat." }
        } catch {
          W ("   [!] Echec de la copie : " + $_.Exception.Message)
          W "   Ne pas desinstaller tant que la copie n'est pas faite."
        }
      }
    }
  }

  if ($choix -eq "D") {
    W ""
    W "--- DESINSTALLATION ---"

    W "1. Arret du processus"
    Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 3

    if ($portee -eq "machine" -and -not $adm) {
      W "2. Elevation necessaire"
      W "   OneDrive est installe pour toute la machine : sans droits"
      W "   administrateur la desinstallation echoue en silence."
      Write-Host ""
      Write-Host "  Relancer ce script en administrateur ? (O/N)" -ForegroundColor Yellow
      Write-Host "  Repondez Oui a la fenetre bleue, avec LE MEME compte" -ForegroundColor Yellow
      Write-Host "  Windows, sinon le script travaillerait sur un autre profil." -ForegroundColor Yellow
      if ((Read-Host "  ").Trim().ToUpper() -eq "O") {
        Start-Process powershell.exe -Verb RunAs -ArgumentList @(
          "-NoProfile","-ExecutionPolicy","Bypass","-File","`"$PSCommandPath`"") -ErrorAction SilentlyContinue
        W "   Relance en administrateur demandee. Reprenez dans la"
        W "   nouvelle fenetre."
        Write-Host ""
        Write-Host "  Appuyez sur Entree pour fermer celle-ci." -ForegroundColor Cyan
        Read-Host
        exit
      }
      W "   Poursuite sans elevation, l'echec est probable."
    }

    W "2. Desinstallation"
    # On essaie chaque desinstalleur trouve, jusqu'a ce qu'OneDrive
    # ait reellement disparu du disque. Un code de retour a zero ne
    # prouve rien : seule l'absence du fichier prouve quelque chose.
    $reussi = $false
    foreach ($c in $candidats) {
      if ($reussi) { break }
      W ("   essai : " + $c.Source)
      # Le processus se relance tout seul : on le retue juste avant.
      Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue | Stop-Process -Force
      Start-Sleep -Seconds 2
      # Separer l'executable de ses arguments dans la UninstallString
      $ligne = $c.Ligne.Trim()
      if ($ligne.StartsWith('"')) {
        $fin = $ligne.IndexOf('"', 1)
        $prog = $ligne.Substring(1, $fin - 1)
        $arguments = $ligne.Substring($fin + 1).Trim()
      } else {
        $i = $ligne.IndexOf(" /")
        if ($i -lt 0) { $prog = $ligne; $arguments = "" }
        else { $prog = $ligne.Substring(0, $i); $arguments = $ligne.Substring($i).Trim() }
      }
      if ($arguments -notmatch "uninstall") { $arguments = ($arguments + " /uninstall").Trim() }
      if (-not (Test-Path -LiteralPath $prog)) { W ("     introuvable : " + $prog); continue }
      try {
        $p = Start-Process -FilePath $prog -ArgumentList $arguments -PassThru -Wait -ErrorAction Stop
        W ("     code de retour : " + $p.ExitCode)
      } catch {
        W ("     echec du lancement : " + $_.Exception.Message)
        continue
      }
      Start-Sleep -Seconds 5
      if (-not (Test-Path -LiteralPath $exe)) { $reussi = $true; W "     OneDrive.exe a disparu, desinstallation effective" }
      else { W "     OneDrive.exe est toujours la" }
    }

    if (-not $reussi) {
      W "   Aucun desinstalleur n'a abouti. Tentative par winget."
      $wg = Get-Command winget.exe -ErrorAction SilentlyContinue
      if ($wg) {
        $p = Start-Process -FilePath $wg.Source -ArgumentList @(
          "uninstall","--id","Microsoft.OneDrive","--silent",
          "--accept-source-agreements") -PassThru -Wait -ErrorAction SilentlyContinue
        if ($p) { W ("   winget termine, code " + $p.ExitCode) }
        Start-Sleep -Seconds 5
        if (-not (Test-Path -LiteralPath $exe)) { $reussi = $true; W "   desinstallation effective" }
      } else {
        W "   winget n'est pas disponible sur cette machine."
      }
    }

    if (-not $reussi) {
      W ""
      W "   [ECHEC] OneDrive est toujours installe."
      W "   Voie manuelle : Parametres, Applications, Applications"
      W "   installees, chercher OneDrive, les trois points,"
      W "   Desinstaller. La fenetre va s'ouvrir."
      W "   Envoyez ce compte rendu, il contient la liste exacte des"
      W "   desinstalleurs trouves et les codes de retour."
      Start-Process "ms-settings:appsfeatures" -ErrorAction SilentlyContinue
    }

    W ""
    if (-not $reussi) {
      W "Nettoyage des reliquats saute : OneDrive est encore installe,"
      W "retirer son lancement automatique maintenant n'aurait pour"
      W "effet que de le rendre plus difficile a diagnostiquer."
    } else {

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
