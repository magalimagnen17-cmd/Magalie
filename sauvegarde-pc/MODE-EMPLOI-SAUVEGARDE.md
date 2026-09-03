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

## Étape 2 : la copie, une fois les volumes connus

Drive pour ordinateur est installé sur la machine. C'est la bonne
configuration, et elle change tout par rapport au Drive ouvert dans un
navigateur : Drive apparaît comme un lecteur dans l'Explorateur, en
général `G:`. Une copie de dossier suffit, elle reprend toute seule
après une coupure, et un script peut la piloter proprement.

Le script d'inventaire vérifie ce point en premier : application
lancée ou non, lettre réellement attribuée au lecteur (ce n'est pas
toujours `G:`), présence des dossiers `Mon Drive` et `Drive partagés`.

Deux réglages à vérifier dans Drive avant de lancer une copie, sur ce
PC en particulier.

**Streaming plutôt que miroir.** Dans les préférences de Drive, un
dossier peut être « mis en miroir » (les fichiers existent en double,
sur le disque et dans le cloud) ou « diffusé en streaming » (ils ne
descendent qu'à l'ouverture). Sur une machine dont le disque est déjà
serré, le miroir peut la saturer. Le streaming est le bon choix ici.

**Le quota du compte.** Un compte Google gratuit offre 15 Go partagés
entre Drive, Gmail et Google Photos. La place réellement libre est
donc toujours inférieure à 15 Go, et elle ne se lit pas depuis le PC :
il faut la relever sur drive.google.com, en bas à gauche. Si le volume
à sauvegarder dépasse, trois options : trier et n'envoyer que
l'essentiel, passer à 200 Go pour environ 2 euros par mois, ou copier
sur un disque dur externe.

Une fois ces deux chiffres connus, le volume utile d'un côté et la
place disponible de l'autre, je fournis le script de copie. Il
travaillera par lots, avec reprise après coupure et journal de ce qui
est passé, plutôt qu'un glisser-déposer géant qu'une mise en veille
suffit à interrompre.

Un mot sur la nature de l'opération : une synchronisation n'est pas
une sauvegarde. Ce qui est supprimé sur le PC disparaît aussi du
Drive synchronisé. La vraie sécurité, c'est deux copies à deux
endroits, dont une qui ne suit pas les suppressions. D'où l'intérêt
du disque externe en complément, même quand tout tient dans Drive.

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
