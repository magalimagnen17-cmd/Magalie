# Comparatif de performance avant et après

`COMPARATIF.bat`, à double-cliquer. Il demande les droits
administrateur : le journal de performance de Windows ne se lit pas
autrement. Répondre Oui.

Le seul fichier écrit est un fichier de test de 100 Mo dans le dossier
temporaire, supprimé immédiatement après la mesure. Rien d'autre n'est
touché.

## Trois sources, de la plus solide à la plus fragile

**1. L'historique des démarrages.** C'est la meilleure mesure dont on
dispose, et elle existait avant qu'on touche à quoi que ce soit :
Windows chronomètre chacun de ses démarrages et garde la trace des
dernières semaines. Impossible d'influencer une mesure prise dans le
passé. Le rapport liste chaque démarrage avec sa durée jusqu'au bureau
utilisable, puis compare la moyenne des premiers à celle des derniers.

C'est aussi la mesure qui correspond à ce que l'on ressent : le temps
d'attente devant la machine le matin.

**2. La comparaison des rapports de diagnostic.** Le script cherche
tous les `Diagnostic-PC*.txt` sur le Bureau, prend le plus ancien et le
plus récent, et compare ce qui a changé durablement : programmes au
démarrage, logiciels installés, antivirus déclarés, espace libre,
erreurs système.

Il sépare volontairement ces chiffres de ceux qui ne veulent rien dire
d'une fois sur l'autre. La charge processeur et la mémoire utilisée
dépendent de ce qui tournait à la seconde de la mesure : les afficher
comme un résultat serait de la décoration, pas de la mesure. Ils
figurent dans le rapport, mais dans une rubrique séparée qui dit ce
qu'ils valent.

S'il n'y a qu'un seul rapport sur le Bureau, le script le dit et
n'invente pas de comparaison. Il faut alors lancer `DIAGNOSTIC-PC.bat`
pour produire le rapport d'après.

**3. Une mesure de vitesse du moment.** Écriture et lecture de 100 Mo,
et une charge processeur calibrée. Avec les repères qui permettent de
situer le résultat : un disque mécanique lit entre 80 et 120 Mo/s, un
SSD SATA entre 400 et 550, un SSD NVMe au-delà de 1500.

## Ce que le comparatif ne pourra pas montrer

Le nettoyage agit sur ce qui se lance, pas sur ce qui est monté dans la
machine. Le type de disque et la quantité de mémoire vive ne bougent
pas, et ce sont les deux plafonds réels d'un PC ancien. Le rapport les
rappelle en fin de section pour que la comparaison reste honnête : on
mesure ce qu'un nettoyage peut faire, pas ce qu'il ne peut pas.

---

## Résultat du 03/09/2026, et deux corrections

Le premier passage a produit deux conclusions fausses, corrigées depuis.

**La comparaison portait sur les mauvaises dates.** Le script découpait
l'historique en tiers et comparait les démarrages de 2024 à ceux de
2026. Cela mesure le vieillissement de la machine sur deux ans, pas
l'effet du nettoyage. La coupure se fait désormais à la date de
l'intervention, déduite du premier rapport de diagnostic présent sur le
Bureau, et le script raisonne sur la médiane plutôt que sur la moyenne :
un démarrage isolé à 341 secondes, un jour de grosse mise à jour
Windows, ne doit pas emporter le résultat.

Sur les vrais chiffres :

| | Durée jusqu'au bureau |
|---|---|
| 02/09 12:08, dernier démarrage avant nettoyage | 143,7 s |
| 03/09 00:00, premier après | 92,4 s |
| 03/09 18:59, deuxième après | 57,0 s |

86 secondes gagnées, et le meilleur démarrage depuis avril 2024. La
médiane de tous les démarrages antérieurs est cependant de 79 s : le
2 septembre était une mauvaise journée. Et deux mesures ne font pas une
tendance. Le script le dit maintenant explicitement tant qu'il y a moins
de trois démarrages après l'intervention.

**La mesure de lecture disque était faussée.** Le script relisait le
fichier qu'il venait d'écrire, donc Windows le servait depuis son cache
mémoire : 680 Mo/s mesuraient la RAM, pas le disque. La lecture se fait
désormais sur des fichiers système déjà présents, et le rapport
avertit que même ainsi le chiffre peut rester optimiste.

L'écriture, elle, était juste : **50 Mo/s**, valeur de disque
mécanique. C'est l'écriture qu'il faut regarder, elle force le passage
physique sur le disque. Le type de disque est désormais lu directement
auprès de Windows par `Get-PhysicalDisk`, qui le déclare sans
chronomètre et sans interprétation.
