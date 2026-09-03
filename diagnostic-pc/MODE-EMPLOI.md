# Kit de diagnostic PC lent

Objectif : collecter en 2 minutes tout ce qui explique la lenteur d'un poste,
sans rien modifier sur la machine. Le script est en **lecture seule**.

---

## Windows, methode simple : `DIAGNOSTIC-PC.bat`

Un seul fichier, rien a taper.

1. Copier `DIAGNOSTIC-PC.bat` sur le Bureau du PC.
2. Double-cliquer dessus.
3. Si Windows affiche « Windows a protege votre ordinateur », cliquer
   sur **Informations complementaires** puis **Executer quand meme**.
4. Repondre **Oui** a la fenetre bleue de Windows : le test a besoin
   des droits administrateur pour lire le type de disque et la liste
   complete des programmes au demarrage. Sans ces droits le rapport
   sort quand meme, mais incomplet, et il le signale.
5. La fenetre affiche l'avancement en 12 etapes. Ne pas la fermer
   avant le message vert TERMINE.
6. Un fichier `Diagnostic-PC-AAAA-MM-JJ-HHMM.txt` s'ouvre dans le
   Bloc-notes. Envoyer son contenu.

Le rapport est **horodate**, donc l'ancien n'est jamais ecrase. C'est
voulu : le seul moyen de mesurer ce que le nettoyage a apporte, c'est
de comparer deux rapports pris a deux moments.

En tete de chaque rapport, une **synthese** reprend les huit chiffres
qui bougent : jours depuis le dernier demarrage, charge CPU, RAM totale
et utilisee, type de disque, espace libre sur `C:`, nombre de
programmes au demarrage, nombre d'antivirus declares, nombre de
logiciels installes, erreurs systeme sur 7 jours. C'est cette synthese
qu'on lit en premier, cote a cote avec celle d'avant.

Le meme geste marche pour `DIAGNOSTIC-RESEAU.bat` si la connexion est
en cause. Celui-la n'a pas besoin des droits administrateur et fait un
vrai test de debit, comptez une minute de plus.

### Variante en ligne de commande

1. Copier `Diagnostic-PC.ps1` sur le Bureau.
2. Clic droit sur le bouton Demarrer, choisir **Terminal (admin)**.
3. Coller puis Entree :

```
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\Diagnostic-PC.ps1"
```

Ne pas coller le contenu du `.ps1` directement dans la console : un
bloc a accolades sur plusieurs lignes met PowerShell en attente sur
`>>` au lieu de l'executer, et donne l'impression que rien ne se passe.

## macOS

Ouvrir l'application **Terminal** (Spotlight, taper "Terminal") et coller ce bloc :

```bash
{
echo "=== MODELE ==="; system_profiler SPHardwareDataType | head -20
echo; echo "=== macOS ==="; sw_vers
echo; echo "=== MEMOIRE ==="; vm_stat | head -8; echo "Pression memoire :"; memory_pressure | tail -3
echo; echo "=== STOCKAGE ==="; df -h /
echo; echo "=== TOP CPU ==="; ps aux | sort -nrk 3 | head -12 | awk '{printf "%-25s CPU %s%%  MEM %s%%\n",$11,$3,$4}'
echo; echo "=== TOP MEMOIRE ==="; ps aux | sort -nrk 4 | head -12 | awk '{printf "%-25s MEM %s%%\n",$11,$4}'
echo; echo "=== DEMARRAGE ==="; ls ~/Library/LaunchAgents /Library/LaunchAgents 2>/dev/null
echo; echo "=== BATTERIE ==="; system_profiler SPPowerDataType | grep -A4 "Health"
} > ~/Desktop/Diagnostic-Mac.txt; open ~/Desktop/Diagnostic-Mac.txt
```

Un fichier `Diagnostic-Mac.txt` apparaît sur le Bureau.

---

## Ce que le rapport permet de trancher

| Ce qu'on lit | Verdict |
|---|---|
| MediaType = HDD | Cause n°1. Un SSD change tout, plus que n'importe quel réglage. |
| RAM totale ≤ 4 Go | Cause n°2. Windows 10/11 étouffe sous 4 Go. |
| Disque C: < 10 % libre | Windows ralentit fortement quand le système manque d'espace. |
| 15+ programmes au démarrage | Session longue à ouvrir, machine occupée en permanence. |
| 2 antivirus listés | Ils se scannent l'un l'autre. Ralentissement massif. |
| Mode alimentation "Économie d'énergie" | Le CPU est bridé volontairement. |
| Beaucoup d'erreurs disk / Ntfs | Disque en fin de vie, ne rien optimiser avant de sauvegarder. |
| Allumé depuis 30+ jours | Un simple redémarrage récupère souvent beaucoup. |
