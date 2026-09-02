# Kit de diagnostic PC lent

Objectif : collecter en 2 minutes tout ce qui explique la lenteur d'un poste,
sans rien modifier sur la machine. Le script est en **lecture seule**.

---

## Windows

1. Copier le fichier `Diagnostic-PC.ps1` sur le Bureau du PC.
2. Clic droit sur le bouton Démarrer, choisir **Terminal (admin)** ou
   **Windows PowerShell (admin)**.
3. Coller la commande suivante puis Entrée :

```
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\Diagnostic-PC.ps1"
```

4. Un fichier `Diagnostic-PC.txt` apparaît sur le Bureau et s'ouvre dans le Bloc-notes.
5. Envoyer le contenu de ce fichier.

### Variante sans fichier à copier

Ouvrir PowerShell en admin et coller directement le contenu du `.ps1`.

---

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
