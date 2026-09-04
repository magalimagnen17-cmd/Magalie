# Remplacer OpenOffice par LibreOffice

`LIBREOFFICE.bat`, à double-cliquer, droits administrateur demandés.
Comptez 15 à 40 minutes : environ 350 Mo à télécharger, puis une
installation sur un disque mécanique.

**Fermez Word, Excel et OpenOffice avant de lancer.**

## L'ordre des opérations, qui n'est pas anodin

1. Copie de vos réglages OpenOffice sur le Bureau
2. Installation de LibreOffice
3. Vérification qu'il est réellement installé
4. Désinstallation d'OpenOffice, **et seulement si l'étape 3 est bonne**

Le sens de cet ordre : si le téléchargement échoue ou si l'installation
se passe mal, OpenOffice est toujours là. À aucun moment la machine ne
se retrouve sans suite bureautique. Le script refuse explicitement de
désinstaller quoi que ce soit tant qu'il n'a pas vu LibreOffice en
place.

## Vos documents ne sont pas touchés

Ni déplacés, ni convertis, ni modifiés. Le format `.odt` est le même
pour les deux logiciels, ils viennent de la même souche : LibreOffice
est né d'OpenOffice en 2010. Les `.doc`, `.xls` et `.docx` de Microsoft
s'ouvrent aussi.

Le script compte vos documents bureautiques avant de commencer, pour
que vous voyiez ce qui est en jeu. Ils sont par ailleurs déjà dans
Drive depuis la synchronisation d'hier.

## Ce qui est sauvegardé, et pourquoi

Le dossier `%APPDATA%\OpenOffice\4\user` est copié sur le Bureau. Il
contient le dictionnaire personnel, les modèles de documents et les
corrections automatiques : tout ce qui a été personnalisé au fil des
années et qui ne se trouve dans aucun document.

LibreOffice ne les reprend pas automatiquement. La copie permet de les
récupérer si quelque chose manque à l'usage, ce qui n'arrive
généralement qu'au bout de quelques jours, quand un mot du
dictionnaire personnel n'est plus reconnu.

## D'où vient le logiciel

Le script passe par `winget`, le gestionnaire de paquets intégré à
Windows 10 depuis la version 1809. Il télécharge LibreOffice
directement chez son éditeur, The Document Foundation, avec
vérification d'intégrité du fichier. Aucun site tiers, aucun
téléchargeur intermédiaire, ce qui est précisément le genre d'endroit
où l'on récupère des barres d'outils.

Si `winget` est absent, le script ouvre la page officielle et vous
laissez faire l'installation à la main, puis vous le relancez : il
reprendra à l'étape suivante.

## Le point à vérifier après

En partant, OpenOffice libère les extensions qu'il s'était attribuées.
Windows peut alors ne plus savoir quoi faire d'un `.odt`.

La vérification prend dix secondes : double-cliquez sur un document.
S'il s'ouvre dans LibreOffice, c'est réglé. Sinon, clic droit, Ouvrir
avec, Choisir une autre application, LibreOffice Writer, et cocher
Toujours utiliser cette application.

## À l'usage

LibreOffice ressemble beaucoup à OpenOffice, les menus sont presque au
même endroit. Il est aussi nettement plus rapide sur les gros
documents, ce qui ne se refuse pas sur cette machine.

Si l'interface apparaît en anglais, elle se change dans Outils,
Options, Paramètres linguistiques, Langues.
