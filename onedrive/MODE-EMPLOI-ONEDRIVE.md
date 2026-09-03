# OneDrive qui tourne en rond

`ONEDRIVE.bat`, à poser sur le Bureau et double-cliquer. Pas besoin des
droits administrateur : OneDrive s'installe par utilisateur, et le
script agit sur le profil de la session ouverte, pas sur la machine
entière. Il affiche d'ailleurs le profil traité en tête, à vérifier.

Contrairement aux autres outils de ce dossier, **celui-ci modifie la
machine** si vous le lui demandez. Il commence toujours par un constat
en lecture seule, affiche ce qu'il a trouvé, et ne fait rien avant
confirmation.

## Ce qu'il propose

**R, réinitialiser.** Vide le cache de synchronisation et relance
OneDrive proprement. C'est ce qui débloque la plupart des synchros qui
tournent en rond, rien n'est désinstallé, et c'est réversible. Deux
minutes. À essayer en premier si le but est juste que ça s'arrête de
tourner.

**D, désinstaller.** Arrête OneDrive, lance la désinstallation
officielle, retire le lancement automatique, supprime les tâches
planifiées et masque l'icône dans l'Explorateur. **Le dossier de
données et son contenu sont conservés**, le script ne les touche
jamais. Les fichiers restent aussi disponibles sur onedrive.com, et
OneDrive se réinstalle en deux clics si besoin.

**N**, ne rien faire, garder seulement le constat.

## Les deux garde-fous

Le script refuse de vous laisser désinstaller à l'aveugle dans deux
situations, et il le signale par un `[STOP]`.

**Des dossiers personnels rangés dans OneDrive.** Si le Bureau ou
Documents a été redirigé vers OneDrive, les désinstaller sans
précaution rend ces dossiers introuvables à leur place habituelle.
Il faut d'abord les ramener dans `C:\Utilisateurs\<nom>`.

Sur cette machine, l'inventaire du 03/09 a déjà répondu : aucun
dossier personnel n'est dans OneDrive, ils sont tous dans
`C:\Users\fctot`. Ce garde-fou ne devrait donc pas se déclencher, mais
il revérifie au moment de l'action plutôt que de se fier à une mesure
d'il y a une heure.

**Des fichiers qui n'existent que dans le cloud.** OneDrive sait
afficher des fichiers dont le contenu n'est pas sur le disque, pour
économiser de la place. Ils ont l'air normaux dans l'Explorateur, mais
désinstaller les rend inutilisables. Le script les compte en lisant
leur attribut système, pas en le supposant. S'il en trouve, la marche
à suivre est affichée : clic droit sur le dossier OneDrive, « Toujours
conserver sur cet appareil », attendre le téléchargement, puis
recommencer.

Passer outre un `[STOP]` reste possible, mais demande de taper
`JE CONFIRME` en toutes lettres.

## Après la désinstallation

Redémarrer le PC pour que l'Explorateur prenne en compte le
changement.

Un compte rendu horodaté est déposé sur le Bureau, avec le détail de
ce qui a été fait et de ce qui a été laissé intact.

Si OneDrive revient après une grosse mise à jour de Windows, ce qui
arrive, la même manipulation le renvoie. Il existe une clé de stratégie
pour l'empêcher définitivement de revenir, mais elle touche à la
configuration système de la machine entière : autant la poser
sciemment, en connaissance de cause, que l'inclure dans un script de
désinstallation.
