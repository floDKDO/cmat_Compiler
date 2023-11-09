%{
    
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
    
typedef struct symbole {
    char* nom;
    struct symbole* suivant;
} symbole;

void initTS();
int addTableSymb(char* symb);
symbole* getTableSymb(int index);
void printTS();
void freeTS();

symbole* TS;

extern int yylex();
void yyerror(const char* msg);

//Initialisation de la table des symboles avec le cas d'arrêt
void initTS(){
    TS = (symbole*) malloc(sizeof(symbole*));
    TS->suivant = TS;
};

//Affichage de chaque symbole
void printTS(){
    for (symbole *iterator = TS ; iterator->suivant != iterator ; iterator = iterator->suivant){
        printf("%s\n", iterator->nom);
    }
}

//Ajout d'un symbole sans doublon avec l'indice dans la liste en retour
int addTableSymb(char* name) {
    
    //On recherche si le nom existe déjà
    int i = 0;
    symbole *iterator;
    for (iterator = TS ; iterator->suivant != iterator ; iterator = iterator->suivant){
        if (strcmp(iterator->nom, name) == 0) {
            return i;
        }
        i++;
    }

    //Sinon on l'ajoute
    iterator->nom = name;
    symbole *symb = (symbole*) malloc(sizeof(symbole*));
    symb->suivant = symb;
    iterator->suivant = symb;
    return i;
}

//Recherche d'un symbole à partir de son indice
symbole* getTableSymb(int index){
    int i = 0;
    symbole *iterator = TS;
    //On avance dans la liste jusqu'à index ou fin de liste
    while (iterator->suivant != iterator && i < index){
        iterator = iterator->suivant;
        i++;
    }
    //On vérifie dans quel cas d'arrêt du while on est
    if (i == index){
        return iterator;
    }
    //Symbole non trouvé
    fprintf(stderr, "Table des Sybloles : index trop grand\n");
}

//Ne surtout pas oublier de libérer les symboles
void freeTS(){
    symbole* pre_iterator = TS;
    symbole* iterator = pre_iterator->suivant;

    while (iterator->suivant != iterator){
        free(pre_iterator);
        pre_iterator = iterator;
        iterator = iterator->suivant;
    }
    free(pre_iterator);
}

%}

%token INCR DECR INTERV
%token INT FLOAT MATRIX
%token IF ELSE FOR RETURN  
%token MAIN PRINTF PRINT PRINTMAT WHILE
%token IDENT C_INT C_FLOAT C_STR

%start start

%%

start : %empty //grammaire temporaire
;

// TODO : faire les grammaires

%%  

void yyerror(const char* msg)
{
	fprintf(stderr, "%s\n", msg);
}
