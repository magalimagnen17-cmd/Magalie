# ==========================================================
#  REMPLACER OPENOFFICE PAR LIBREOFFICE
#  ATTENTION : ce script MODIFIE la machine.
#  Ordre volontaire : on sauvegarde le profil, on installe
#  LibreOffice, on verifie qu'il est bien la, et SEULEMENT
#  ENSUITE on desinstalle OpenOffice. A aucun moment la
#  machine ne se retrouve sans suite bureautique.
#  Aucun document n'est touche : les .odt et .doc restent
#  ou ils sont et s'ouvrent dans LibreOffice.
# ==========================================================

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference    = "SilentlyContinue"

$L = New-Object System.Collections.ArrayList
function W($t){ [void]$L.Add([string]$t); Write-Host $t }
function T($t){ [void]$L.Add(""); [void]$L.Add("=== $t ==="); Write-Host ""; Write-Host "=== $t ===" -ForegroundColor Cyan }
function Go($o){
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
function Installes {
  $p = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
         'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')
  return @(Get-ItemProperty $p -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName })
}

try {

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  REMPLACER OPENOFFICE PAR LIBREOFFICE" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$adm = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
       ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$bureau = CheminBureau

W ""
W "=========================================================="
W "  REMPLACEMENT OPENOFFICE VERS LIBREOFFICE"
W ("  " + $env:COMPUTERNAME + " / " + $env:USERNAME + "   " + (Get-Date -Format "dd/MM/yyyy HH:mm"))
W "=========================================================="

if (-not $adm) {
  W ""
  W "[STOP] Cette fenetre n'est pas en mode administrateur."
  W "       Installer et desinstaller un logiciel l'exige."
  W "       Fermez, refaites un double-clic, et repondez Oui."
  Write-Host ""
  Write-Host "  Appuyez sur Entree pour fermer." -ForegroundColor Cyan
  Read-Host
  exit
}

# ---------- 1. Constat ----------
T "CE QUI EST INSTALLE"
$inst = Installes
$oo = @($inst | Where-Object { $_.DisplayName -like "*OpenOffice*" })
$lo = @($inst | Where-Object { $_.DisplayName -like "*LibreOffice*" })

if ($oo.Count -eq 0) { W "OpenOffice n'est pas installe sur cette machine." }
else { foreach ($x in $oo) { W ("OpenOffice trouve : " + $x.DisplayName + "   version " + $x.DisplayVersion) } }
if ($lo.Count -gt 0) { foreach ($x in $lo) { W ("LibreOffice deja present : " + $x.DisplayName + "   version " + $x.DisplayVersion) } }
else { W "LibreOffice n'est pas encore installe." }

# Les documents ne sont jamais touches, mais les compter rassure
# et donne une idee de ce qui est en jeu.
$exts = @(".odt",".ods",".odp",".odg",".doc",".docx",".xls",".xlsx",".ppt",".pptx",".rtf")
$docs = 0
foreach ($d in @("Documents","Desktop","Downloads")) {
  $c = Join-Path $env:USERPROFILE $d
  if (Test-Path -LiteralPath $c) {
    $docs += @(Get-ChildItem -LiteralPath $c -Recurse -File -Force -ErrorAction SilentlyContinue |
               Where-Object { $exts -contains $_.Extension.ToLower() }).Count
  }
}
W ""
W ("Documents bureautiques trouves : " + $docs)
W "Ils ne seront ni deplaces, ni convertis, ni modifies."
W "Le format .odt est le meme pour les deux logiciels, et"
W "LibreOffice ouvre aussi les .doc et .xls de Microsoft."

# ---------- 2. winget ----------
T "OUTIL D'INSTALLATION"
$wg = Get-Command winget.exe -ErrorAction SilentlyContinue
if ($wg) {
  W ("winget disponible : " + $wg.Source)
  W "LibreOffice sera telecharge directement chez son editeur,"
  W "The Document Foundation, avec verification d'integrite."
} else {
  W "winget n'est pas disponible sur cette machine."
  W "L'installation devra se faire a la main depuis"
  W "https://fr.libreoffice.org/download/telecharger-libreoffice/"
}

if ($oo.Count -eq 0 -and $lo.Count -gt 0) {
  W ""
  W "Rien a faire : LibreOffice est la, OpenOffice n'y est plus."
  Write-Host ""
  Write-Host "  Appuyez sur Entree pour fermer." -ForegroundColor Cyan
  Read-Host
  exit
}

# ---------- 3. Confirmation ----------
Write-Host ""
Write-Host "  CE QUI VA SE PASSER, DANS CET ORDRE :" -ForegroundColor Cyan
Write-Host "   1. Copie de vos reglages OpenOffice sur le Bureau"
Write-Host "      (dictionnaire personnel, modeles, corrections)"
Write-Host "   2. Installation de LibreOffice"
Write-Host "   3. Verification qu'il est bien installe"
Write-Host "   4. Desinstallation d'OpenOffice, seulement si 3 est bon"
Write-Host ""
Write-Host "  Comptez 15 a 40 minutes : environ 350 Mo a telecharger," -ForegroundColor Yellow
Write-Host "  puis une installation sur un disque mecanique." -ForegroundColor Yellow
Write-Host "  Fermez Word, Excel et OpenOffice avant de continuer." -ForegroundColor Yellow
Write-Host ""
$c = (Read-Host "  Tapez OUI pour lancer").Trim().ToUpper()
if (@("OUI","O","OK","Y","YES") -notcontains $c) {
  W ""; W ("Reponse '" + $c + "' : rien n'a ete fait.")
  Write-Host ""; Write-Host "  Appuyez sur Entree pour fermer." -ForegroundColor Cyan; Read-Host; exit
}

# ---------- 4. Sauvegarde du profil ----------
T "1. SAUVEGARDE DES REGLAGES OPENOFFICE"
$profil = Join-Path $env:APPDATA "OpenOffice\4\user"
if (Test-Path -LiteralPath $profil) {
  $dest = Join-Path $bureau ("Reglages-OpenOffice-" + (Get-Date -Format "yyyy-MM-dd"))
  try {
    Copy-Item -LiteralPath $profil -Destination $dest -Recurse -Force -ErrorAction Stop
    $n = @(Get-ChildItem -LiteralPath $dest -Recurse -File -Force -ErrorAction SilentlyContinue)
    W ("Copie faite : " + $dest)
    W ("   " + $n.Count + " fichiers, " + (Go (($n | Measure-Object Length -Sum).Sum)))
    W "   On y trouve le dictionnaire personnel, les modeles de"
    W "   documents et les corrections automatiques. LibreOffice ne"
    W "   les reprend pas tout seul, mais ils sont recuperables"
    W "   depuis ce dossier si quelque chose manque a l'usage."
  } catch { W ("Copie impossible : " + $_.Exception.Message) }
} else {
  W "Aucun profil OpenOffice trouve, rien a sauvegarder."
}

# ---------- 5. Installation de LibreOffice ----------
T "2. INSTALLATION DE LIBREOFFICE"
$ok = $false
if ($lo.Count -gt 0) {
  W "LibreOffice est deja installe, etape sautee."
  $ok = $true
} elseif ($wg) {
  W "Telechargement et installation en cours."
  W "C'est la partie longue. Ne fermez pas la fenetre."
  Write-Host ""
  Write-Host "  Patientez, cela peut durer une demi-heure..." -ForegroundColor Yellow
  & $wg.Source install --id TheDocumentFoundation.LibreOffice --exact `
      --accept-package-agreements --accept-source-agreements --silent 2>&1 |
      ForEach-Object { Write-Host ("   " + $_) -ForegroundColor DarkGray }
  W ("winget a rendu le code " + $LASTEXITCODE)
} else {
  W "Ouverture de la page de telechargement officielle."
  W "Telecharger la version 64 bits, l'installer, puis relancer"
  W "ce script : il reprendra a l'etape suivante."
  Start-Process "https://fr.libreoffice.org/download/telecharger-libreoffice/"
}

# ---------- 6. Verification ----------
T "3. VERIFICATION"
Start-Sleep -Seconds 3
$lo2 = @(Installes | Where-Object { $_.DisplayName -like "*LibreOffice*" })
$exe = @(
  "$env:ProgramFiles\LibreOffice\program\soffice.exe",
  "${env:ProgramFiles(x86)}\LibreOffice\program\soffice.exe"
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

if ($lo2.Count -gt 0 -or $exe) {
  $ok = $true
  foreach ($x in $lo2) { W ("Installe : " + $x.DisplayName + "   version " + $x.DisplayVersion) }
  if ($exe) { W ("Programme : " + $exe) }
  W "[ok] LibreOffice est en place."
} else {
  W "[!] LibreOffice n'a pas ete detecte apres l'installation."
  W "    OpenOffice ne sera PAS desinstalle : la machine garde"
  W "    une suite bureautique qui fonctionne."
}

# ---------- 7. Desinstallation d'OpenOffice ----------
T "4. DESINSTALLATION D'OPENOFFICE"
if (-not $ok) {
  W "Etape annulee, LibreOffice n'etant pas installe."
} elseif ($oo.Count -eq 0) {
  W "OpenOffice n'etait pas installe, rien a faire."
} else {
  foreach ($x in $oo) {
    W ("Desinstallation de " + $x.DisplayName)
    $u = $x.UninstallString
    if (-not $u) { W "   pas de commande de desinstallation, a faire a la main"; continue }
    # Une chaine MsiExec /I doit devenir /X pour desinstaller.
    if ($u -match "\{[0-9A-Fa-f\-]{36}\}") {
      $guid = $matches[0]
      W ("   msiexec /x " + $guid)
      $p = Start-Process "msiexec.exe" -ArgumentList "/x", $guid, "/qb", "/norestart" -PassThru -Wait
      W ("   code de retour " + $p.ExitCode)
    } else {
      W ("   commande : " + $u)
      W "   a lancer a la main depuis Parametres, Applications"
    }
  }
  Start-Sleep -Seconds 3
  $reste = @(Installes | Where-Object { $_.DisplayName -like "*OpenOffice*" })
  if ($reste.Count -eq 0) { W "[ok] OpenOffice a bien ete retire." }
  else { W "[!] OpenOffice est toujours la. A retirer par Parametres, Applications." }
}

# ---------- 8. Associations ----------
T "POUR FINIR : LES ASSOCIATIONS DE FICHIERS"
W "En partant, OpenOffice libere les extensions qu'il s'etait"
W "attribuees. Windows peut alors ne plus savoir quoi ouvrir quand"
W "on double-clique sur un .odt ou un .doc."
W ""
W "La verification prend dix secondes : double-cliquez sur un"
W "document. S'il s'ouvre dans LibreOffice, tout va bien."
W ""
W "Sinon : clic droit sur le document, Ouvrir avec, Choisir une"
W "autre application, LibreOffice Writer, et cocher Toujours"
W "utiliser cette application."
W ""
W "Les extensions concernees : .odt .ods .odp pour les documents"
W "LibreOffice, .doc .docx .xls .xlsx .ppt .pptx pour ceux de"
W "Microsoft."
W ""
W "Un mot sur l'usage : LibreOffice ressemble beaucoup a"
W "OpenOffice, les menus sont presque au meme endroit. Les"
W "documents existants s'ouvrent sans conversion ni perte."

$out = Join-Path $bureau ("LibreOffice-" + (Get-Date -Format "yyyy-MM-dd-HHmm") + ".txt")
try { ($L -join "`r`n") | Out-File -FilePath $out -Encoding UTF8 -ErrorAction Stop
      Write-Host ""
      Write-Host ("  Compte rendu : " + $out) -ForegroundColor Green } catch { }

} catch {
  Write-Host ""
  Write-Host "  ERREUR :" -ForegroundColor Red
  Write-Host ("  " + $_.Exception.Message) -ForegroundColor Red
  Write-Host ("  Ligne " + $_.InvocationInfo.ScriptLineNumber) -ForegroundColor Red
  Write-Host "  Recopiez ces lignes et envoyez-les." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  Appuyez sur Entree pour fermer cette fenetre." -ForegroundColor Cyan
Read-Host
