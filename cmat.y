%{

#include "tds.h"

extern int yylex();
void yyerror(const char* msg);

%}

%define parse.error verbose //indique le type d'erreur de syntaxe

%token INCR DECR INTERV LOGICAL_AND LOGICAL_OR
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
%left UNARY INTERV
%right INCR DECR

%start programme

%% //grammaire temporaire

programme : INT MAIN '(' ')' corps
;

corps : '{' liste_instruction '}' | '{' '}'
;

liste_instruction : liste_instruction instruction 
		   | instruction
;

instruction : declaration_variable ';' 
	    | assignation_variable ';'
	    | declaration_fonction
	    | appel_fonction ';'
	    | RETURN C_INT ';'
;

assignation_variable : liste_variable
;

declaration_variable : type liste_variable
;

liste_variable : liste_variable ',' element_variable
		| element_variable
;

element_variable : IDENT 
		| IDENT assign expression
		| IDENT assign IDENT liste_intervalle
		| incr_et_decr
		| IDENT liste_dimension
                | IDENT liste_dimension '=' valeur_tableau
                | IDENT liste_dimension '=' expression
;

declaration_fonction : type IDENT '(' liste_parametre ')' corps
;
		 
appel_fonction : IDENT '(' liste_argument ')'
		| PRINTF '(' C_STR ')'
		| PRINT '(' constante ')'
		| PRINTMAT '(' IDENT ')'
;
            
liste_parametre : liste_parametre ',' parametre | parametre
;

liste_argument : liste_argument ',' argument | argument
;

parametre : type IDENT | %empty
;

argument :  IDENT assign expression | expression | %empty
; 

expression : valeur 
            | incr_et_decr
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
   

liste_intervalle : liste_intervalle intervalle | intervalle
;
       
intervalle : '[' '*' ']' | '[' INTERV ']' | '[' INTERV ';' C_INT ']' | '[' C_INT ';' C_INT ']' | '[' '*' ';' '*' ']'
;

liste_dimension : liste_dimension dimension | dimension
;

dimension : '[' C_INT ']'
;

valeur_tableau : valeur_vecteur 
		| '{' liste_vecteur '}'
;
		
liste_vecteur : liste_vecteur ',' valeur_vecteur 
		| valeur_vecteur
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

valeur : IDENT | constante | IDENT liste_dimension
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
