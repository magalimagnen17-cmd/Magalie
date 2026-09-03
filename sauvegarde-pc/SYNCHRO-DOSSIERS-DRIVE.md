# Sauvegarder les dossiers avec Drive pour ordinateur

Oui, c'est la bonne méthode, et c'est mieux qu'un script de copie.
Drive pour ordinateur sait surveiller des dossiers du PC en continu :
Bureau, Documents, Images, ou n'importe quel autre. Tout ce qui y entre
part vers le cloud sans qu'on y pense, la copie reprend seule après une
coupure de connexion ou un redémarrage, et il n'y a aucun script à
maintenir.

Trois conditions avant de l'activer. Elles ne sont pas théoriques,
ce sont les trois façons dont cette configuration se plante en
pratique. Le rapport d'inventaire répond aux trois.

---

## Condition 1 : la place disponible

Le contenu sauvegardé consomme le quota du compte Google. Compte
gratuit, 15 Go partagés entre Drive, Gmail et Google Photos, donc
toujours moins de 15 Go réellement libres. À relever sur
drive.google.com, en bas à gauche.

Si le volume mesuré dépasse : trier et n'envoyer que l'essentiel,
passer à 200 Go pour environ 2 euros par mois, ou faire les photos et
vidéos par disque externe et ne garder que les documents dans Drive.

## Condition 2 : aucun dossier déjà géré par OneDrive

C'est le piège le plus courant sur un PC Windows récent. Si le Bureau
ou Documents a été redirigé vers OneDrive, et qu'on ajoute le même
dossier à la sauvegarde Google Drive, les deux services se disputent
les mêmes fichiers. Résultat : des doublons `document (2).docx`, des
conflits permanents, et un PC qui rame en arrière-plan.

Un dossier, un seul service. L'inventaire signale explicitement les
dossiers concernés par un `[!] CONFLIT ONEDRIVE`.

## Condition 3 : la boîte Outlook traitée à part

Un fichier `.pst` reste verrouillé tant qu'Outlook est ouvert : la
synchronisation ne peut pas le lire, et elle échoue en silence. Pire,
un `.pst` pèse plusieurs Go et change à chaque mail reçu, donc en
synchronisation continue il repart en entier bien trop souvent, et
sature la connexion pour rien.

Le bon traitement : fermer Outlook, copier le `.pst` une fois dans
Drive à la main, et ne pas inclure son dossier dans la surveillance
continue. À refaire de temps en temps, pas en permanence.

---

## La marche à suivre

1. Clic sur l'icône Drive dans la barre des tâches, en bas à droite,
   puis sur la roue dentée, puis **Préférences**.
2. Onglet **Mon ordinateur**, cliquer sur **Ajouter un dossier**.
3. Choisir Documents. Dans la fenêtre qui s'ouvre, cocher
   **Synchroniser avec Google Drive**.
4. Laisser **Importer dans Google Photos** décoché. Cette option
   envoie les images une seconde fois, dans Photos, et elles comptent
   une seconde fois dans les 15 Go.
5. Répéter pour Images, puis pour le Bureau, en sautant tout dossier
   marqué en conflit OneDrive par l'inventaire.
6. Cliquer sur **Enregistrer**.

Les fichiers arrivent dans Drive sous **Ordinateurs**, puis le nom de
la machine. C'est normal qu'ils n'apparaissent pas dans « Mon Drive » :
ce sont deux espaces distincts.

## Pendant la première synchronisation

C'est la seule phase longue. Le débit qui compte est le débit
**montant**, souvent dix fois plus faible que le descendant sur une
ligne domestique. Le rapport d'inventaire donne une estimation de
durée pour trois hypothèses de débit.

Deux réglages pendant ce temps : mettre la mise en veille sur Jamais
(Paramètres, Système, Alimentation), et laisser le PC branché. Sinon
la synchronisation s'arrête à chaque veille et repart au ralenti.

Pour savoir où elle en est : cliquer sur l'icône Drive. Elle affiche
la progression, puis « Synchronisation terminée ». Elle signale aussi
les fichiers qu'elle n'a pas réussi à envoyer, et c'est cette liste
qu'il faut lire, pas seulement le message de fin.

## La vérification qui compte

Une fois « Synchronisation terminée » affiché, ouvrir drive.google.com,
aller dans **Ordinateurs**, puis le nom du PC, et vérifier que les
dossiers attendus sont bien là avec leur contenu. Ouvrir deux ou trois
fichiers au hasard, dont un gros.

Une sauvegarde qu'on n'a jamais vérifiée n'est pas une sauvegarde,
c'est une intention.

---

## Ce que cette méthode ne fait pas

Elle synchronise, elle n'archive pas. Un fichier supprimé sur le PC
part aussi du Drive. Google le garde 30 jours dans la corbeille, ce
qui donne un filet de sécurité, mais un filet à durée limitée : une
suppression passée inaperçue pendant deux mois est définitive.

Le même raisonnement vaut pour une corruption ou un rançongiciel : la
version abîmée écrase la bonne dans le cloud. L'historique des versions
de Drive permet de revenir en arrière fichier par fichier, ce qui est
utile pour un accident isolé, pas pour un sinistre général.

D'où la règle, qui n'a rien de théorique quand on parle d'un PC ancien :
deux copies, à deux endroits, dont une qui ne suit pas les
suppressions. Drive pour le quotidien et l'accès de n'importe où, un
disque externe branché de temps en temps pour la copie qui ne bouge
plus. Un disque de 1 To coûte une cinquantaine d'euros, c'est le
meilleur rapport tranquillité sur prix de toute cette opération.
