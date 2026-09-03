# Sauvegarde du contenu du PC vers Google Drive

Objectif : mettre à l'abri ce qui a de la valeur sur le PC, avant tout
autre chose. Le nettoyage a rendu la machine utilisable, mais un PC
ancien reste un PC ancien : la sauvegarde n'est pas une option.

La règle de conduite est simple. **On ne copie rien avant de savoir ce
qu'on copie.** D'où l'étape 1.

---

## Étape 1 : l'inventaire (à faire maintenant, 2 à 10 minutes)

Le script est en **lecture seule**. Il ne copie rien, ne déplace rien,
ne supprime rien. Il mesure.

### Méthode principale : `INVENTAIRE.bat`

Un seul fichier, rien à taper, rien à coller.

1. Copier `INVENTAIRE.bat` sur le Bureau du PC de Magali.
2. Double-cliquer dessus.
3. Si Windows affiche « Windows a protégé votre ordinateur », cliquer
   sur **Informations complémentaires** puis **Exécuter quand même**.
   C'est l'avertissement standard pour tout fichier venu d'internet.
4. Une fenêtre noire s'ouvre et affiche l'avancement, étape par étape.
   Ne pas la fermer avant le message vert TERMINE.
5. `Inventaire-Sauvegarde.txt` s'ouvre dans le Bloc-notes. Envoyer
   son contenu.

Le `.bat` contient le script PowerShell à la suite du code de
lancement : il l'extrait dans le dossier temporaire, l'exécute avec
la politique d'exécution contournée pour cette fois uniquement, et
laisse la fenêtre ouverte quoi qu'il arrive. Aucun réglage Windows
n'est modifié au passage.

### Si le `.bat` ne fonctionne pas

`A-COLLER-INVENTAIRE.txt` contient la même mesure en version courte,
sur **une seule ligne** à coller dans PowerShell. Une seule ligne,
c'est délibéré : un bloc sur plusieurs lignes collé dans la console
la laisse en attente sur `>>` au lieu de s'exécuter, et donne
l'impression que rien ne se passe. C'était le problème du premier
essai.

### Si rien de tout cela ne passe, la méthode manuelle

Elle donne l'essentiel en trois minutes, sans aucun script.

1. Ouvrir l'Explorateur de fichiers, aller dans `C:\Utilisateurs\<nom>`.
2. Sélectionner les dossiers Bureau, Documents, Images, Vidéos,
   Musique et Téléchargements ensemble.
3. Clic droit, **Propriétés**. La taille totale et le nombre de
   fichiers s'affichent, le calcul prend une minute ou deux.
4. Répéter dossier par dossier pour savoir lequel pèse le plus.
5. Relever aussi l'espace libre du disque `C:` (clic droit sur le
   lecteur, Propriétés) et la place restante sur drive.google.com,
   affichée en bas à gauche.

Ces trois chiffres suffisent pour décider de la suite.

### Ce que l'inventaire va trancher

| Question | Pourquoi c'est décisif |
|---|---|
| Combien pèsent Documents, Images, Vidéos | Décide si Drive gratuit suffit ou non |
| Les dossiers sont-ils déjà dans OneDrive | Une partie est peut-être déjà sauvegardée sans qu'on le sache |
| Y a-t-il un `.pst` Outlook | C'est le fichier le plus souvent oublié, et le plus douloureux à perdre |
| Quels sont les 20 plus gros fichiers | Quelques vidéos font souvent 80 % du volume |
| Y a-t-il d'autres comptes Windows | Un ancien compte contient souvent encore des documents |

---

## Étape 2 : la synchronisation des dossiers par Drive

Drive pour ordinateur est installé, et il sait surveiller des dossiers
du PC en continu. C'est la meilleure méthode disponible ici, meilleure
qu'un script de copie : rien à maintenir, reprise automatique après
coupure, et la sauvegarde reste à jour toute seule ensuite.

La marche à suivre détaillée est dans `SYNCHRO-DOSSIERS-DRIVE.md`.

Trois conditions à vérifier avant de l'activer, toutes les trois
tranchées par le rapport d'inventaire :

1. **La place.** 15 Go partagés entre Drive, Gmail et Photos sur un
   compte gratuit, donc toujours moins de 15 Go réels.
2. **Aucun conflit OneDrive.** Un dossier déjà synchronisé par OneDrive
   ne doit pas être repris par Drive, sinon les deux se disputent les
   mêmes fichiers et fabriquent des doublons sans fin. L'inventaire
   marque ces dossiers d'un `[!] CONFLIT ONEDRIVE`.
3. **La boîte Outlook à part.** Un `.pst` verrouillé par Outlook ouvert
   ne se copie pas, et en synchronisation continue il repart en entier
   à chaque mail. À sauvegarder une fois, Outlook fermé, hors du
   dossier surveillé.

---

## Étape 3 : ce qu'un script ne peut pas faire, et qui se fait à la main

**Les mots de passe du navigateur.** Ils sont chiffrés par Windows avec
la session de Magali. Aucun script ne les lit, et c'est une bonne chose.
L'export se fait depuis le navigateur, par la personne connectée :

- Chrome : menu ⋮ > Mots de passe et saisie automatique > Gestionnaire
  de mots de passe > Paramètres > Exporter les mots de passe
- Edge : menu … > Paramètres > Profils > Mots de passe > … > Exporter

Le fichier produit est un `.csv` **en clair**. À traiter comme un
trousseau de clés : on l'envoie dans Drive, et on le supprime du Bureau
juste après. Idéalement, on ne l'exporte pas du tout si les mots de
passe sont déjà synchronisés sur le compte Google ou Microsoft.

**Les favoris.** Même chemin, menu Favoris > Gérer les favoris >
Exporter. Le script d'inventaire dit simplement quels navigateurs sont
présents et depuis quand les favoris n'ont pas bougé.

---

## Ce qu'on ne sauvegarde pas, et pourquoi

`AppData` représente souvent plusieurs Go de réglages et de caches
d'applications. Ce dossier ne se restaure pas sur un autre PC : les
logiciels le recréent à l'installation. Le copier multiplie le volume
et le temps de transfert sans rien apporter. Le script le mesure et
l'affiche à part, pour que la décision soit prise en connaissance de
cause, pas par défaut.

Idem pour le fichier `.ost` d'Outlook : c'est un cache local d'une boîte
mail qui existe déjà sur le serveur. Le `.pst`, lui, est une archive
locale qui n'existe nulle part ailleurs. Un seul des deux mérite d'être
sauvegardé.
