# Où on en est, 03/09/2026 au soir

## Fait

**La machine.** Nettoyée, et nettement plus rapide. Le kit de diagnostic
est dans `diagnostic-pc/`, avec `DIAGNOSTIC-PC.bat` qui produit
désormais un rapport horodaté et une synthèse en tête, pour comparer
avant et après.

**OneDrive.** Désinstallé, code de retour 0. Lancement automatique
retiré, tâches planifiées supprimées, icône masquée. Le dossier de
données n'a pas été touché.

**Le dossier de la Ligue de Football de Normandie.** 477 fichiers,
379 Mo, copiés dans `G:\Mon Drive`. C'était le plus urgent : depuis la
désinstallation de OneDrive, plus rien ne les synchronisait.

**L'inventaire.** 20,19 Go à sauvegarder pour 13,20 Go disponibles.
Analyse complète dans `sauvegarde-pc/ANALYSE-INVENTAIRE.md`.

## En cours

**La synchronisation de Documents et du Bureau**, 7 Go. Elle a besoin
de plusieurs heures, et le PC doit rester allumé et branché.

## À faire en priorité demain matin

**1. Vérifier que Documents est complet.** C'est le point le plus
important. Sur drive.google.com, rubrique **Ordinateurs**, nom de la
machine. Si le quota a saturé pendant la nuit, Drive s'est arrêté en
route et la sauvegarde est partielle.

**2. Retirer Images de la synchronisation** si ce n'est pas déjà fait.
Google pré-coche Bureau, Documents et Images dans son assistant : les
12,30 Go de photos partent sans qu'on les ait demandés, saturent le
quota et bloquent le reste.

**3. Remettre la veille**, `VEILLE.bat` option 2.

**4. Vérifier la copie de la Ligue** : 477 fichiers des deux côtés,
et le dossier visible sur drive.google.com avant de supprimer quoi que
ce soit en local.

## Ensuite, la question des 12,30 Go de photos

`TRI-ET-DOUBLONS.bat`, à lancer quand le disque est tranquille et non
pendant la synchronisation : il lit le contenu des fichiers pour
détecter les doublons, exactement comme Drive les lit pour les
envoyer, et les deux se gênent.

Il chiffrera trois gisements : les installeurs, environ 800 Mo sans
valeur, les doublons averés (`IMG_6881.MOV` existe en double dans deux
sous-dossiers de Pictures), et les vidéos `.MOV`, qui occupent
l'essentiel du poids.

Trois issues possibles, à trancher avec ces chiffres : le tri suffit,
un forfait Google One, ou un disque externe pour les vidéos.

Point vérifié ce soir : il n'existe **aucune** règle exemptant les
photos de moins de 5 Mo du quota. La seule exemption est historique,
pour les fichiers importés en haute qualité avant le 1er juin 2021.
La qualité « Économiseur d'espace » de Google Photos ne dispense pas
du quota, elle compresse, ce qui est différent.

## En attente, sans urgence

**Edge.** Rien n'a été supprimé. Le constat a montré deux choses :
Edge est encore le navigateur par défaut, ce qui doit être changé avant
toute suppression, et un seul favori existait, exporté sur le Bureau.
`EDGE.bat` propose l'option N, neutraliser, qui donne le même confort
sans exposer Windows Update.
