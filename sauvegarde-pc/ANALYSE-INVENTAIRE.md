# Analyse de l'inventaire du 03/09/2026

Machine `LAPTOP-PKSQ4QAM`, session `fctot`.

## Le chiffre qui décide

| | |
|---|---|
| À sauvegarder | **20,19 Go** |
| Disponible dans Drive | **13,20 Go** |
| **Écart** | **7 Go de trop** |

Le compte Google consomme déjà 1,8 Go des 15 Go, Gmail compris. Le
disque dur du PC, lui, n'est pas en cause : 331 Go libres sur 421.
Le problème est le quota Drive, rien d'autre.

Bonne nouvelle par ailleurs : aucun point bloquant. Pas de conflit
OneDrive, pas de boîte Outlook à traiter, pas de chemin trop long.
La synchronisation peut être configurée dès que la question du volume
est réglée.

## Où est le poids

| Dossier | Volume | Fichiers |
|---|---|---|
| Images | 12,30 Go | 2 532 |
| Documents | 6,88 Go | 1 183 |
| Téléchargements | 719 Mo | 86 |
| Musique | 185 Mo | 58 |
| Bureau | 129 Mo | 18 |
| Vidéos | vide | 2 |

Images pèse à lui seul 61 % du total. Et dans les 20 plus gros
fichiers, **15 sont des `.MOV`**, tous rangés dans Images. Ce sont des
vidéos d'iPhone importées avec les photos : le dossier Vidéos est vide
parce que tout est arrivé dans Images.

## Trois gisements de place, sans rien perdre

**1. Les installeurs, environ 800 Mo.** Téléchargements ne contient
pratiquement que des programmes d'installation : `GoogleDriveSetup.exe`
265 Mo, `OJ4630_198.exe` 163 Mo (pilote d'imprimante HP), OpenOffice
126 Mo, `OneDriveSetup.exe` 125 Mo. Tous re-téléchargeables en deux
clics. Sur le Bureau, le dossier `OpenOffice 4.1.2 (fr) Installation
Files` ajoute 116 Mo de la même nature. Rien de tout cela n'a sa place
dans une sauvegarde.

**2. Les doublons, volume à mesurer.** Un signal net dans le rapport :
`IMG_6881.MOV`, 116 Mo, apparaît deux fois, dans `Pictures\giulia` et
dans `Pictures\JOY`. Quand un fichier de cette taille se retrouve dans
deux dossiers, c'est en général qu'un import s'est fait deux fois, et
il y en a rarement un seul. C'est de la place récupérable sans perdre
la moindre photo.

**3. Les vidéos.** Si les `.MOV` d'Images représentent 6 à 8 Go, les
sortir de Drive et les mettre sur un disque externe suffit à faire
tenir tout le reste dans le quota gratuit.

Le script `TRI-ET-DOUBLONS.bat` chiffre ces trois gisements et dit
lesquels suffisent.

## Le plan, dans cet ordre

**Aujourd'hui, sans rien attendre : sauvegarder ce qui rentre.**
Documents et Bureau font 7 Go, ils tiennent largement dans les 13,20 Go
disponibles. C'est le contenu le plus irremplaçable et le plus léger,
donc il part en premier. Configurer la synchronisation sur ces deux
dossiers, laisser tourner.

**Pendant ce temps : lancer le tri.** `TRI-ET-DOUBLONS.bat` travaille
en lecture seule pendant que la synchro tourne, il ne gêne rien.

**Ensuite : décider pour les 12,30 Go d'Images**, avec les chiffres
en main. Soit installeurs et doublons suffisent à faire de la place,
soit les vidéos partent sur un disque externe, soit un forfait Google
One de 100 ou 200 Go règle la question pour quelques euros par mois.

Une règle à ne pas contourner : **rien ne se supprime avant que la
sauvegarde soit faite et vérifiée.** Les installeurs sont la seule
exception, ils n'ont aucune valeur.

## Deux points annexes

**Les comptes `defaultuser0`, `defaultuser100000` et
`defaultuser100001`** ne sont pas des comptes de personnes. Ce sont
des profils techniques créés par Windows à l'installation et lors des
mises à jour. Rien à y récupérer, ce n'est pas une piste.

**Les favoris : c'est Chrome qu'il faut exporter.** Ses favoris ont
été modifiés le 02/09/2026, ceux d'Edge datent du 03/05/2024. Le
navigateur réellement utilisé est Chrome.
