%{
    
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
    
typedef struct symbole {
    char nom;
    struct symbole* suivant;
} symbole;

void initTS();
int addTableSymb(char symb);
symbole* getTableSymb(int index);
void printTS();
void freeTS();

symbole* TS;

extern int yylex();
void yyerror(const char* msg);

void initTS(){
    TS = (symbole*) malloc(sizeof(symbole*));
    TS->suivant = TS;
};

void printTS(){
    for (symbole *iterator = TS ; iterator->suivant != iterator ; iterator = iterator->suivant){
        //printf("%c : %d\n", iterator->nom, iterator->set);
    }
}

int addTableSymb(char name) {
    
    int i = 0;
    symbole *iterator;
    for (iterator = TS ; iterator->suivant != iterator ; iterator = iterator->suivant){
        if (iterator->nom == name) {
            return i;
        }
        i++;
    }

    iterator->nom = name;
    //iterator->set = 0;
    symbole *symb = (symbole*) malloc(sizeof(symbole*));
    symb->suivant = symb;
    iterator->suivant = symb;
    return i;
}

symbole* getTableSymb(int index){
    int i = 0;
    symbole *iterator = TS;
    while (iterator->suivant != iterator && i < index){
        iterator = iterator->suivant;
        i++;
    }
    if (i == index){
        return iterator;
    }
    fprintf(stderr, "Table des Sybloles : index trop grand\n");
}

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

start : %empty

// TODO : grammaires

%%  

void yyerror(const char* msg)
{
	fprintf(stderr, "%s\n", msg);
}
