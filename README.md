# Projet-Compilation

##Utilisation du makefile
- *make* crée un exécutable nommé "cmat" : pour exécuter le programme, taper "./cmat"
- *make clean* supprimme tous les fichiers créés par lex et bison, les .o, l'exécutable "./cmat" et les fichiers générés par *make doc*
- *make doc* crée deux fichiers utiles :
  - "cmat.output" qui contient la liste des symboles terminaux et non terminaux, la grammaire et les états
  - "cmat.pdf" qui crée le diagramme des états de manière graphique
