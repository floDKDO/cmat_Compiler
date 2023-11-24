# Projet-Compilation

## Utilisation du makefile
- *make* crée un exécutable nommé "cmat" : pour exécuter le programme, taper "./cmat"
- *make clean* supprime tous les fichiers créés par lex et bison, les .o, l'exécutable "./cmat" et les fichiers générés par *make doc*
- *make doc* crée deux fichiers utiles :
  - "cmat.output" qui contient la liste des symboles terminaux et non terminaux, la grammaire et les états
  - "cmat.pdf" qui crée le diagramme des états de manière graphique
  
## Exécution du programme
- *./cmat* lance le programme, on peut taper dans la console l'entrée voulue
- *./cmat < tests/test_x* lance le programme avec comme entrée le fichier "test_x" se trouvant dans le dossier "tests" 
