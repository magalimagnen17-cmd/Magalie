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


---

# Mise à jour du 04/09/2026 au matin

## Décision prise sur les photos

Les fichiers originaux restent sur le disque du PC, et on sauvegarde
dans Drive ce qui tient dans le gratuit. Pas de forfait, pas de disque
externe pour l'instant.

## Ce que l'analyse de recouvrement a montré

Le ménage ne libère presque rien : **96 Mo**, et 425 Mo d'Images sont
déjà à l'abri via Documents. Les dossiers `Nouveau dossier` de
Documents, qu'on soupçonnait d'être des copies des photos, contiennent
en réalité **du contenu qui n'existe que là** : 2,32 Go pour le (2),
1,26 Go pour le premier, 951 Mo pour le (3). Il ne faut donc surtout
pas les supprimer.

Un seul dossier est réellement redondant : `Images\anniversaire
valentin`, dont 87 % existe ailleurs, avec 8 fichiers uniques listés
dans le rapport.

Bilan : il manque 5,98 Go pour tout sauvegarder, et aucun nettoyage ne
comblera cet écart.

## La méthode retenue : séparer les photos des vidéos

Drive synchronise des dossiers entiers, pas des types de fichiers.
Pour ne sauvegarder que les photos, il faut donc que les vidéos soient
ailleurs.

Or le dossier **Vidéos de Windows est vide**, alors que 13 Go de `.MOV`
venus du téléphone sont rangés dans Images. `SEPARER.bat` les remet à
leur place en conservant l'arborescence : `Images\giulia\x.MOV` devient
`Videos\giulia\x.MOV`.

Le script mesure d'abord, ne déplace rien sans confirmation, n'écrase
jamais un fichier de même nom, et écrit sur le Bureau un journal
listant chaque ancien et nouveau chemin pour pouvoir revenir en
arrière.

Images allégé de ses vidéos devrait tenir dans les 5,82 Go restants.
Le rapport donne un cumul dossier par dossier pour trancher au cas où
il faudrait descendre plus finement.

## Le risque assumé, et il est réel

Les vidéos resteront sur ce seul disque, sauvegardées nulle part. Ce
sont des anniversaires, un baptême, des vacances. Le disque est un
WDC WD5000LPCX, mécanique, et un disque mécanique finit toujours par
s'arrêter.

Une clé USB de 32 Go, moins de dix euros, suffirait à les mettre à
l'abri. C'est la seule dépense qui vaut vraiment la peine d'être
reconsidérée.
