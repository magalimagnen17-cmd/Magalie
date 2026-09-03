#!/usr/bin/env python3
"""
Emballe un script PowerShell dans un fichier .bat autonome, a double-cliquer.

Le .bat porte le .ps1 a sa suite. Au lancement il l'extrait vers %TEMP%
avec `more +N`, verifie l'extraction, puis l'execute en ExecutionPolicy
Bypass. Aucun reglage de la machine n'est modifie.

    python3 outils/emballer.py <script.ps1> <sortie.bat> "<titre>" [--admin]

--admin ajoute une elevation UAC automatique : si la fenetre n'est pas
administrateur, le .bat se relance lui-meme via Start-Process -Verb RunAs.

N (le nombre de lignes d'en-tete a sauter) est calcule ici, jamais a la
main : c'est le seul point ou une erreur casse silencieusement tout.
"""
import io
import sys


def emballer(chemin_ps1, chemin_bat, titre, admin=False):
    ps1 = io.open(chemin_ps1, encoding="ascii").read()
    nom_tmp = chemin_ps1.replace("\\", "/").split("/")[-1]

    entete = [
        "@echo off",
        "title %s" % titre,
        "setlocal",
        "REM ==========================================================",
        "REM  A DOUBLE-CLIQUER. Rien a taper, rien a coller.",
        "REM  Ce fichier porte le script PowerShell a sa suite.",
        "REM  Il l extrait dans le dossier temporaire puis l execute.",
        "REM  Aucun reglage de la machine n est modifie.",
        "REM ==========================================================",
    ]

    if admin:
        entete += [
            "net session >nul 2>&1",
            "if not errorlevel 1 goto ADMIN",
            "echo.",
            "echo   Ce test a besoin des droits administrateur.",
            "echo   Repondez Oui a la fenetre bleue de Windows.",
            "echo.",
            "powershell -NoProfile -Command \"Start-Process -FilePath '%~f0' -Verb RunAs\"",
            "exit /b 0",
            ":ADMIN",
        ]

    entete += [
        'set "PS1=%%TEMP%%\\%s"' % nom_tmp,
        'set "PWSH=%SystemRoot%\\System32\\WindowsPowerShell\\v1.0\\powershell.exe"',
        'if not exist "%PWSH%" set "PWSH=powershell.exe"',
        'more +@@N@@ "%~f0" > "%PS1%"',
        'if not exist "%PS1%" goto ERR',
        'findstr /c:"@@MARQUEUR@@" "%PS1%" >nul || goto ERR',
        '"%PWSH%" -NoProfile -ExecutionPolicy Bypass -File "%PS1%"',
        "if errorlevel 1 goto ERR",
        "exit /b 0",
        ":ERR",
        "echo.",
        "echo   Le lancement a echoue.",
        "echo   Recopiez le message ci-dessus et envoyez-le.",
        "echo.",
        "pause",
        "exit /b 1",
    ]

    # Marqueur de controle : la premiere ligne de commentaire du .ps1.
    # Si `more` a mal extrait, findstr ne la trouve pas et on s'arrete net
    # au lieu de lancer un script tronque.
    marqueur = ""
    for ligne in ps1.splitlines():
        texte = ligne.strip("# =-").strip()
        if ligne.startswith("#") and sum(c.isalpha() for c in texte) >= 8 and '"' not in texte:
            marqueur = texte
            break
    if not marqueur:
        raise SystemExit("Aucune ligne de commentaire utilisable comme marqueur.")

    n = len(entete)
    entete = [l.replace("@@N@@", str(n)).replace("@@MARQUEUR@@", marqueur) for l in entete]

    contenu = "\r\n".join(entete) + "\r\n" + ps1.replace("\n", "\r\n")
    io.open(chemin_bat, "w", encoding="ascii", newline="").write(contenu)

    # Verification : la ligne n (0-based) doit etre la premiere du .ps1
    lignes = contenu.split("\r\n")
    attendu = ps1.split("\n")[0]
    if lignes[n] != attendu:
        raise SystemExit("Decalage d extraction : corrige le calcul de N.")
    return n, marqueur


if __name__ == "__main__":
    if len(sys.argv) < 4:
        raise SystemExit(__doc__)
    admin = "--admin" in sys.argv
    n, m = emballer(sys.argv[1], sys.argv[2], sys.argv[3], admin)
    print("%s -> %s  (more +%d, marqueur %r%s)"
          % (sys.argv[1], sys.argv[2], n, m, ", admin" if admin else ""))
