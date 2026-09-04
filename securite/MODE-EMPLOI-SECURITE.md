# Antivirus et malwares

`SECURITE.bat`, à double-cliquer, droits administrateur demandés. Il
constate d'abord, puis propose deux actions, chacune avec
confirmation. Il n'installe rien.

## La réponse courte : ne rien installer

Le diagnostic du 04/09 est clair : **un seul antivirus déclaré,
Windows Defender**, et il tourne. C'est l'état souhaitable, pas un
manque.

Ajouter Avast, AVG, McAfee ou Norton sur cette machine serait une
erreur. Deux antivirus se surveillent mutuellement et divisent la
vitesse. Sur un AMD E2-7110 avec un disque mécanique, c'est
exactement ce qui la rendrait à nouveau inutilisable. Les versions
gratuites ajoutent en prime des extensions de navigateur, des
notifications et des propositions d'achat, c'est-à-dire précisément
ce qu'on vient de retirer.

Defender ne gagne pas tous les comparatifs, mais il est intégré, mis à
jour par Windows Update, sans publicité, et il ne coûte presque rien
en ressources. Sur un PC familial, c'est le bon choix.

## Les trois choses à faire, et une seule concerne les virus

**1. Activer la protection contre les logiciels indésirables.** Elle
est livrée avec Windows et désactivée d'origine. Elle vise les barres
d'outils, les faux nettoyeurs de registre, les publiciels : ce qui
encombre un PC familial bien plus souvent qu'un vrai virus. C'est le
même moteur qui travaille, donc aucun coût en performance. Option 1 du
script.

**2. Regarder les extensions de navigateur.** Une extension voit tout
ce que vous affichez et tapez dans le navigateur. C'est aujourd'hui la
porte d'entrée la plus fréquente, loin devant le virus classique. Le
rapport en signalait 4 sur Chrome et 2 sur Edge. Le script affiche leur
vrai nom, pas seulement leur identifiant, et tout ce qui n'est pas
reconnu doit partir.

**3. Remplacer OpenOffice.** C'est le seul vrai risque de sécurité
identifié sur la machine, et ce n'est pas un virus. La version
installée date de 2015 et son éditeur ne publie plus de correctifs :
les failles connues n'y seront jamais corrigées, et une suite
bureautique ouvre par définition des fichiers venus de l'extérieur.
LibreOffice ouvre les mêmes documents, ressemble à s'y méprendre, et
reste maintenu. Le remplacement est gratuit et sans perte.

## Sur les examens

L'examen rapide prend quelques minutes et vérifie la mémoire et les
endroits où se logent réellement les infections. Il suffit dans la
plupart des cas.

L'examen complet lit tous les fichiers du disque. Sur un disque
mécanique qui écrit à 50 Mo/s, comptez plusieurs heures, et la machine
sera lente pendant ce temps. À lancer le soir, pas avant de s'en
servir.

## Faut-il Malwarebytes ?

Un passage unique de la version gratuite est défendable si un doute
persiste : il repère des programmes indésirables que Defender laisse
passer. Deux précautions dans ce cas. L'installation active 14 jours
de version payante avec surveillance permanente, qu'il faut couper
tout de suite dans ses réglages, sinon on retombe dans le problème des
deux antivirus. Et une fois le scan fait et le résultat lu, on le
désinstalle.

Rien dans le diagnostic actuel ne justifie ce détour. Aucun processus
suspect, aucune détection dans l'historique de Defender, et une liste
de logiciels installés qui ne contient que des choses attendues.
