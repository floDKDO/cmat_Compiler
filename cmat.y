%{

#include "tds.h"

extern int yylex();
void yyerror(const char* msg);

%}

%define parse.error verbose //indique le type d'erreur de syntaxe

%token INCR DECR INTERV_OP LOGICAL_AND LOGICAL_OR
%token PLUS_ASSIGN MINUS_ASSIGN MULT_ASSIGN DIV_ASSIGN MOD_ASSIGN AND_ASSIGN XOR_ASSIGN OR_ASSIGN
%token LE GE EQ NE 
%token INT FLOAT MATRIX
%token IF ELSE FOR RETURN  
%token MAIN PRINTF PRINT PRINTMAT WHILE
%token IDENT C_INT C_FLOAT C_STR

%right '=' PLUS_ASSIGN MINUS_ASSIGN MULT_ASSIGN DIV_ASSIGN MOD_ASSIGN AND_ASSIGN XOR_ASSIGN OR_ASSIGN
%left LOGICAL_OR
%left LOGICAL_AND
%left '|'
%left '^'
%left '&'
%left EQ NE
%left '<' '>'
%left LE GE 
%left '+' '-'
%left '*' '/' '%'
%left UNARY INTERV_OP
%right INCR DECR

%start programme

%% //grammaire temporaire

//Créer une liste de declaration_fonction si on ajoute les fonction en dehors du main
programme : main
;

main : INT MAIN '(' ')' corps
;

corps : '{' liste_instruction '}' | '{' '}'
;

liste_instruction : liste_instruction instruction 
		   | instruction
;

instruction : declaration_variable ';' 
	    | declaration_fonction
	    | liste_operation ';'
            | condition
            | boucle
	    | RETURN C_INT ';'
;

condition : IF '(' expression ')' corps 
        | IF '(' expression ')' corps ELSE corps
;

boucle : boucle_for | boucle_while
;

/*Vrai boucle for, mais pas celle qui est demandé
boucle_for : FOR '(' initial_declaration ';' liste_operation ';' liste_operation ')' corps
;

initial_declaration : declaration_variable | liste_operation
;*/

// Boucle for moins poussée
boucle_for : FOR '(' type IDENT '=' expression ';' expression ';' incr_et_decr ')' corps
;

boucle_while : WHILE '(' expression ')' corps
;


declaration_variable : type liste_variable_declaree
;

liste_variable_declaree : liste_variable_declaree ',' variable_declaree | variable_declaree
;

variable_declaree : IDENT
                | IDENT '=' expression
                | IDENT intervalle_dimention
                | IDENT intervalle_dimention '=' valeur_tableau
;


liste_operation : liste_operation ',' operation
		| operation
;

operation : expression
	| IDENT assign operation
	| IDENT intervalle_dimention assign operation
;

declaration_fonction : type IDENT '(' liste_parametre ')' corps
                        | type IDENT '(' ')' corps
;
		 
appel_fonction : IDENT '(' liste_argument ')'
                | IDENT '(' ')'
		| PRINTF '(' C_STR ')'
		| PRINT '(' constante ')'
                | PRINT '(' IDENT ')'
		| PRINTMAT '(' IDENT ')'
;
            
liste_parametre : liste_parametre ',' parametre | parametre
;

liste_argument : liste_argument ',' argument | argument
;

parametre : type IDENT
;

argument :  IDENT assign expression | expression
; 

expression : valeur 
            | expression '+' expression
            | expression '-' expression
            | expression '*' expression
            | expression '/' expression
            | expression '%' expression
            | expression '^' expression
            | expression '&' expression
            | expression '|' expression
            | expression '>' expression
            | expression '<' expression
            | expression LE expression
            | expression GE expression
            | expression EQ expression
            | expression NE expression
            | expression LOGICAL_AND expression
            | expression LOGICAL_OR expression
            | '-' expression %prec UNARY
            | '+' expression %prec UNARY
            | '!' expression %prec UNARY
            | '~' expression %prec UNARY
            | '*' expression %prec UNARY
            | '&' expression %prec UNARY
            | '(' expression ')'
;

       
intervalle_dimention : intervalle_dimention '[' liste_rangee ']' | '[' liste_rangee ']'
;

liste_rangee : liste_rangee ';' rangee | rangee
;

rangee : '*' | expression INTERV_OP expression | expression
;

valeur_tableau : valeur_vecteur 
		| '{' liste_tableau '}'
;
		
liste_tableau : liste_tableau ',' valeur_tableau 
		| valeur_tableau
;
		
valeur_vecteur : '{' liste_nombre '}'
;

liste_nombre : liste_entiers | liste_flottants
;

liste_flottants : liste_flottants ',' C_FLOAT | C_FLOAT
;

liste_entiers : liste_entiers ',' C_INT | C_INT
;

incr_et_decr : IDENT INCR | IDENT DECR | INCR IDENT | DECR IDENT 
;

type : INT | FLOAT | MATRIX
;

valeur : IDENT | constante | IDENT intervalle_dimention | incr_et_decr | appel_fonction
;

constante : C_INT | C_FLOAT 
;

assign : '=' | PLUS_ASSIGN | MINUS_ASSIGN | MULT_ASSIGN | DIV_ASSIGN | MOD_ASSIGN | AND_ASSIGN | XOR_ASSIGN | OR_ASSIGN
;
            
%%  

void yyerror(const char* msg)
{
	fprintf(stderr, "%s\n", msg);
}
