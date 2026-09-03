# Microsoft Edge

`EDGE.bat`, à poser sur le Bureau et double-cliquer.

Edge n'est pas OneDrive. Deux différences comptent avant de décider.

## Différence 1 : Edge est en partie un composant de Windows

Windows s'en sert pour afficher certaines de ses propres pages. Depuis
2024, la réglementation européenne oblige Microsoft à le rendre
désinstallable, mais uniquement sur un Windows à jour et déclaré dans
une région européenne. Le script affiche les deux valeurs, version de
Windows et région, avant de proposer quoi que ce soit.

Quand le bouton Désinstaller est grisé dans les Paramètres, il existe
des commandes internes pour forcer la suppression. Elles cassent
régulièrement Windows Update, et Edge revient à la mise à jour
suivante. Ce script ne les utilise pas, et je ne les recommande pas.

## Différence 2 : WebView2 doit rester

WebView2 porte le moteur d'Edge, mais c'est un composant séparé, et
d'autres logiciels s'en servent pour afficher des pages web dans leurs
propres fenêtres. Le supprimer casse des applications qui n'ont rien à
voir avec le navigateur. Le script le détecte, l'affiche, et n'y touche
jamais.

## Ce que le script fait avant tout choix

Il exporte les favoris Edge sur le Bureau, dans deux formats : la copie
brute du fichier, et un `.html` réimportable dans Chrome par le menu
Favoris, Importer les favoris, Fichier HTML de favoris.

Les favoris d'Edge de cette machine n'ont pas bougé depuis mai 2024,
mais ils existent, et rien ne dit qu'ils sont tous dans Chrome. Une
minute d'export évite de découvrir le contraire trop tard.

Il vérifie aussi si Edge est le navigateur **par défaut**. Si c'est le
cas, il faut basculer sur Chrome avant toute suppression, sinon les
liens des mails et des documents n'ouvriront plus rien.

## Les trois options

**N, neutraliser. C'est ce que je recommande.** Coupe le préchargement
au démarrage de Windows, l'exécution en arrière-plan et le lancement
automatique. Edge reste installé, utilisable, et surtout mis à jour,
mais il ne consomme plus rien tant qu'on ne l'ouvre pas. Réversible :
le compte rendu indique la clé exacte à supprimer pour revenir en
arrière.

Les tâches de **mise à jour** d'Edge sont volontairement laissées en
place. Un navigateur installé mais plus mis à jour est un trou de
sécurité, même s'il ne sert jamais.

**D, désinstallation officielle.** Ouvre la liste des applications
installées de Windows. Si le bouton Désinstaller est actif, la
suppression se fait proprement de là. S'il est grisé, la réponse est
l'option N.

**R**, ne rien faire, garder le constat et les favoris exportés.

## Le fond du sujet

Sur cette machine, la lenteur ne venait pas d'Edge. Un Edge qui ne
démarre plus tout seul et ne précharge plus rien coûte quasiment rien.
Le gain de la désinstallation par rapport à la neutralisation se compte
en quelques centaines de méga-octets de disque, sur un disque qui a
331 Go de libre.

C'est votre machine et votre décision. Mais si le but est qu'elle aille
vite, l'option N donne le même résultat sans exposer Windows Update.
