# La synchronisation, concrètement

Les chiffres sont connus, donc la décision est simple : **on ne
synchronise pas Images maintenant**. Documents, Bureau et les
documents de la Ligue partent d'abord, ils tiennent largement.

| Ce qui part maintenant | Volume |
|---|---|
| Documents | 6,88 Go |
| Bureau | 129 Mo |
| OneDrive - Ligue de Football de Normandie | 379 Mo |
| **Total** | **7,4 Go** sur 13,20 Go disponibles |

Images fait 12,30 Go à lui seul : il ne rentre pas dans les 5,8 Go qui
resteront. On s'en occupe après le tri.

---

## 1. Le dossier de la Ligue, en premier

C'est le plus urgent : depuis la désinstallation de OneDrive, ces 477
fichiers n'existent plus qu'à un seul endroit, le disque de ce PC.

Pas besoin de synchronisation pour celui-là, c'est une archive qui ne
bougera plus. Un simple copier-coller suffit :

1. Ouvrir l'Explorateur de fichiers.
2. Aller dans `C:\Users\fctot`.
3. Clic droit sur `OneDrive - LIGUE DE FOOTBALL DE NORMANDIE`, Copier.
4. Aller dans `G:\Mon Drive`, clic droit, Coller.
5. Attendre que les petites icônes vertes apparaissent sur les fichiers.

379 Mo, quelques minutes.

## 2. La veille, avant de lancer le gros morceau

`VEILLE.bat`, option 1. La machine ne s'endormira plus, l'écran
continuera de s'éteindre. C'est la cause d'échec numéro un d'une
synchronisation de plusieurs heures : le PC s'endort la nuit et repart
au ralenti le lendemain.

Laisser le PC branché sur le secteur.

Une fois la sauvegarde finie, relancer `VEILLE.bat` et prendre
l'option 2. Une machine qui ne dort jamais chauffe et use sa batterie
pour rien.

## 3. La synchronisation de Documents et du Bureau

1. Clic sur l'icône Drive, en bas à droite près de l'heure.
2. Roue dentée, puis **Préférences**.
3. Onglet **Mon ordinateur**, bouton **Ajouter un dossier**.

   Ce bouton est mal nommé par Google : **il ne crée aucun dossier**.
   Il veut dire « ajouter un dossier existant à la liste de ceux que
   Drive surveille ». Une fenêtre de l'Explorateur Windows s'ouvre
   pour que vous désigniez lequel.

4. Naviguer jusqu'à `C:\Users\fctot\Documents`, celui qui existe
   déjà, le sélectionner, valider par **Sélectionner un dossier**.
   Rien n'est créé ni déplacé sur le PC : Documents reste où il est.
5. Dans la fenêtre suivante : cocher **Synchroniser avec Google
   Drive**, et laisser **Importer dans Google Photos** décoché.
6. Recommencer avec `C:\Users\fctot\Desktop`.
7. **Enregistrer**.

Ce qui se crée, c'est de l'autre côté : dans le Drive en ligne, une
rubrique **Ordinateurs** apparaît avec le nom de la machine, et les
fichiers arrivent là.

Ne pas ajouter Images. C'est volontaire.

## 4. Pendant que ça tourne

L'icône Drive affiche la progression. Le débit qui compte est le débit
montant, souvent dix fois plus faible que le descendant : comptez de
deux heures à une journée pour 7,4 Go selon la ligne.

Ce n'est pas la peine de rester devant. En revanche, avant d'éteindre,
vérifier que l'icône affiche bien « Synchronisation terminée » et non
un nombre de fichiers restants.

## 5. La vérification, qui n'est pas optionnelle

Une fois terminé, ouvrir drive.google.com, aller dans **Ordinateurs**,
puis le nom du PC. Les dossiers doivent y être avec leur contenu.
Ouvrir deux ou trois fichiers au hasard, dont un gros.

Une sauvegarde qu'on n'a jamais vérifiée n'est pas une sauvegarde.

## 6. Ensuite seulement, Images

Lancer `TRI-ET-DOUBLONS.bat` quand vous voulez, il travaille en
lecture seule et ne gêne pas la synchronisation en cours. Son rapport
dira si les doublons et les vidéos suffisent à faire entrer les
12,30 Go d'Images dans la place restante, ou s'il faut un disque
externe ou un forfait Google One.
