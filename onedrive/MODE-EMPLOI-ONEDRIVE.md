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

---

## Cas rencontré sur cette machine, le 03/09/2026

Le premier passage n'a rien désinstallé : le rapport se termine par
`Choix : D` puis `Desinstallation annulee`. La demande de confirmation
n'attendait que le mot `OUI` exactement, et toute autre saisie annulait
sans le dire clairement. Corrigé : `O`, `OUI`, `OK`, `Y` et `YES` sont
désormais acceptés, l'invite est explicite, et une réponse non reconnue
est affichée telle qu'elle a été saisie.

Le constat a surtout révélé quelque chose de plus important.

**Deux espaces OneDrive coexistent sur ce PC :**

| Dossier | Contenu |
|---|---|
| `C:\Users\fctot\OneDrive` | **vide**, 0 fichier |
| `C:\Users\fctot\OneDrive - LIGUE DE FOOTBALL DE NORMANDIE` | **477 fichiers, 379 Mo** |

Le OneDrive personnel ne sert à rien. Celui qui travaille est un espace
**professionnel Microsoft 365**, rattaché à une organisation.

Cela change deux choses.

D'abord, c'est probablement la cause de la boucle. Un OneDrive
d'organisation qui tourne en rond, c'est en général un accès qui n'est
plus valide : mot de passe changé, session expirée, licence ou compte
retiré par l'organisation. OneDrive réessaie indéfiniment sans jamais
afficher clairement pourquoi.

Ensuite, cela rend la désinstallation plus délicate qu'elle n'en avait
l'air. Les 477 fichiers sont bien physiquement sur le disque, donc rien
ne disparaît. Mais **ce qui n'a pas encore été envoyé vers
l'organisation ne partira jamais** si on désinstalle. Et une
synchronisation qui tourne en rond est précisément une synchronisation
qui n'aboutit pas : il est donc possible que des modifications récentes
n'aient jamais atteint le cloud.

D'où deux ajouts au script.

**L'option L, dissocier un compte.** Elle arrête la synchronisation
d'un compte précis, laisse ses fichiers sur le disque, ne supprime rien
en ligne, et laisse OneDrive installé. C'est la bonne réponse quand la
boucle vient d'un compte professionnel devenu invalide, et c'est
réversible d'une reconnexion.

**La copie de sécurité avant désinstallation.** Si un espace
professionnel est détecté, le script propose de le copier sur le Bureau
avant de désinstaller, et vérifie que le nombre de fichiers copiés
correspond. Une copie incomplète est signalée, et dans ce cas il ne
faut pas désinstaller.

## Résultat, 03/09/2026 19:57

Désinstallation effectuée, code de retour 0. Lancement automatique
retiré, 2 tâches planifiées supprimées, icône masquée dans
l'Explorateur.

Un défaut d'affichage a été corrigé au passage : le compte rendu
attribuait 477 fichiers au dossier `C:\Users\fctot\OneDrive`, qui est
vide. Le compteur global était réutilisé pour chaque ligne au lieu du
compte propre à chaque dossier. Seuls les chiffres affichés étaient
faux, aucun fichier n'a été touché.

### Ce qu'il reste à faire

**Redémarrer**, pour que l'Explorateur prenne en compte la
disparition. Relancer ensuite `ONEDRIVE.bat` et choisir `N` : le
constat seul confirme que OneDrive n'est pas revenu.

**Traiter les 477 fichiers de la Ligue de Football de Normandie.**
Ils sont toujours sur le disque, dans
`C:\Users\fctot\OneDrive - LIGUE DE FOOTBALL DE NORMANDIE`, mais plus
rien ne les synchronise. Ce dossier est désormais une copie locale
isolée, sans filet.

379 Mo tiennent sans difficulté dans les 13,20 Go disponibles du Drive.
Le plus simple, sans aucun script : ouvrir l'Explorateur, glisser le
dossier dans `G:\Mon Drive`, attendre que l'icône passe au vert.

**Le dossier `C:\Users\fctot\OneDrive`**, vide, peut être supprimé.
Rien ne s'y trouve.
