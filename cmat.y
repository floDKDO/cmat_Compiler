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

%% //grammaire temporaire

start : type element_fonction;



declaration : type liste_element

liste_element : liste_element ',' element | element

element : element_variable | element_fonction;

element_variable : IDENT 
            | IDENT '=' valeur 
            | IDENT liste_dimension
            | IDENT liste_dimension '=' valeur_tableau;


element_fonction : IDENT '(' ')'
            | IDENT '(' liste_argument ')'
            | IDENT '(' ')' corps
            | MAIN '(' ')' corps
            | IDENT '(' liste_argument ')' corps;


type : INT | FLOAT | MATRIX;

liste_dimension : liste_dimension dimension | dimension;
dimension : '[' C_INT ']';

liste_argument : liste_argument ',' argument | argument;
argument : type IDENT | type IDENT '=' constante;
constante : C_INT | C_FLOAT;

valeur_tableau : liste_vecteur | '{' valeur_tableau '}';
liste_vecteur : liste_vecteur ',' valeur_vecteur | valeur_vecteur;
valeur_vecteur : '{' liste_nombre '}';

liste_nombre : liste_entiers | liste_flottants
liste_flottants : liste_flottants ',' C_FLOAT | C_FLOAT;
liste_entiers : liste_entiers ',' C_INT | C_INT;

corps : '{' liste_instruction '}';

affectation : IDENT '=' expression;

expression : valeur
            | expression op expression
            | '-' expression
            | expression INCR
            | expression DECR
            ;

op : '+' | '-' | '*' | '/'

valeur : IDENT
        | constante
        | IDENT '[' valeur INTERV valeur ']'
        | appel_fonction;

appel_fonction : IDENT '(' ')'
                | IDENT '('  ')';

liste_instruction : liste_instruction ';' instruction | instruction;

instruction : declaration | affectation | appel_fonction;

%%  

void yyerror(const char* msg)
{
	fprintf(stderr, "%s\n", msg);
}
