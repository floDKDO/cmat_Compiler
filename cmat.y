%{

#include "tds.h"

extern int yylex();
void yyerror(const char* msg);

int syntaxe_error = 0;

%}

%define parse.error verbose //indique le type d'erreur de syntaxe


%union 
{
        enum u_type {INT_TYPE, FLOAT_TYPE, MATRIX_TYPE, TABLEAU_TYPE, UNKNOWN_TYPE, ERROR_TYPE} type;
        struct u_tab {
                enum u_type type_tab;
                int nDim;
        } tableau;
}

%token INCR DECR INTERV_OP LOGICAL_AND LOGICAL_OR
%token PLUS_ASSIGN MINUS_ASSIGN MULT_ASSIGN DIV_ASSIGN MOD_ASSIGN AND_ASSIGN XOR_ASSIGN OR_ASSIGN
%token LE GE EQ NE 
%token INT FLOAT MATRIX
%token IF ELSE FOR RETURN  
%token MAIN PRINTF PRINT PRINTMAT WHILE
%token IDENT C_INT C_FLOAT C_STR

%type <type> type expression constante valeur variable_declaree
%type <tableau> intervalle_dimension valeur_tableau liste_tableau liste_nombre rangee liste_rangee

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
programme : main {return syntaxe_error;}
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

variable_declaree : IDENT {$$ = UNKNOWN_TYPE;}
                | IDENT '=' expression {$$ = $3;}
                | IDENT intervalle_dimension {
                        if ($2.type_tab != TABLEAU_TYPE) {
                                yyerror("Mauvaise déclaration");
                                $$ = ERROR_TYPE; 
                        } else {
                                $$ = TABLEAU_TYPE; //Tableau ou matrix
                        }}
                | IDENT intervalle_dimension '=' valeur_tableau {
                        if ($2.nDim < $4.nDim) {
                                yyerror("Trop de dimension déclaré");
                                $$ = ERROR_TYPE;
                        } else {
                                $$ = $4.type_tab;
                        }}
;


liste_operation : liste_operation ',' operation
		| operation
;

operation : expression
	| IDENT assign operation
	| IDENT intervalle_dimension assign operation
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

expression : valeur {$$ = $1;}
            | expression '+' expression {
                if ($1 == ERROR_TYPE || $3 == ERROR_TYPE) {
                        $$ = ERROR_TYPE;
                } else if ($1 == TABLEAU_TYPE || $3 == TABLEAU_TYPE) {
                        yyerror("+ avec un tableau");
                        $$ = ERROR_TYPE;
                } else if ($1 == MATRIX_TYPE || $3 == MATRIX_TYPE) {
                        $$ = MATRIX_TYPE;
                } else if ($1 == FLOAT_TYPE || $3 == FLOAT_TYPE) {
                        $$ = FLOAT_TYPE;
                } else if ($1 == INT_TYPE || $3 == INT_TYPE) {
                        $$ = INT_TYPE;
                }}
            | expression '-' expression {
                if ($1 == ERROR_TYPE || $3 == ERROR_TYPE) {
                        $$ = ERROR_TYPE;
                } else if ($1 == TABLEAU_TYPE || $3 == TABLEAU_TYPE) {
                        yyerror("- avec un tableau");
                        $$ = ERROR_TYPE;
                } else if ($1 == MATRIX_TYPE || $3 == MATRIX_TYPE) {
                        $$ = MATRIX_TYPE;
                } else if ($1 == FLOAT_TYPE || $3 == FLOAT_TYPE) {
                        $$ = FLOAT_TYPE;
                } else if ($1 == INT_TYPE || $3 == INT_TYPE) {
                        $$ = INT_TYPE;
                }}
            | expression '*' expression {
                if ($1 == ERROR_TYPE || $3 == ERROR_TYPE) {
                        $$ = ERROR_TYPE;
                } else if ($1 == TABLEAU_TYPE || $3 == TABLEAU_TYPE) {
                        yyerror("* avec un tableau");
                        $$ = ERROR_TYPE;
                } else if ($1 == MATRIX_TYPE || $3 == MATRIX_TYPE) {
                        $$ = MATRIX_TYPE;
                } else if ($1 == FLOAT_TYPE || $3 == FLOAT_TYPE) {
                        $$ = FLOAT_TYPE;
                } else if ($1 == INT_TYPE || $3 == INT_TYPE) {
                        $$ = INT_TYPE;
                }}
            | expression '/' expression {
                if ($1 == ERROR_TYPE || $3 == ERROR_TYPE) {
                        $$ = ERROR_TYPE;
                } else if ($1 == TABLEAU_TYPE || $3 == TABLEAU_TYPE) {
                        yyerror("/ avec un tableau");
                        $$ = ERROR_TYPE;
                } else if ($1 == MATRIX_TYPE || $3 == MATRIX_TYPE) {
                        $$ = MATRIX_TYPE;
                } else if ($1 == FLOAT_TYPE || $3 == FLOAT_TYPE) {
                        $$ = FLOAT_TYPE;
                } else if ($1 == INT_TYPE || $3 == INT_TYPE) {
                        $$ = INT_TYPE;
                }}
            | expression '%' expression {
                if ($1 == ERROR_TYPE || $3 == ERROR_TYPE) {
                        $$ = ERROR_TYPE;
                } else if ($1 != INT_TYPE || $3 != INT_TYPE) {
                        yyerror("\% avec des non entiers"); 
                        $$ = ERROR_TYPE;
                } else {
                        $$ = INT_TYPE;
                }}
            | expression '^' expression {
                if ($1 == ERROR_TYPE || $3 == ERROR_TYPE) {
                        $$ = ERROR_TYPE;
                } else if ($1 != INT_TYPE || $3 != INT_TYPE) {
                        yyerror("^ avec des non entiers"); 
                        $$ = ERROR_TYPE;
                } else {
                        $$ = INT_TYPE;
                }}
            | expression '&' expression {
                if ($1 == ERROR_TYPE || $3 == ERROR_TYPE) {
                        $$ = ERROR_TYPE;
                } else if ($1 != INT_TYPE || $3 != INT_TYPE) {
                        yyerror("& avec des non entiers"); 
                        $$ = ERROR_TYPE;
                } else {
                        $$ = INT_TYPE;
                }}
            | expression '|' expression {
                if ($1 == ERROR_TYPE || $3 == ERROR_TYPE) {
                        $$ = ERROR_TYPE;
                } else if ($1 != INT_TYPE || $3 != INT_TYPE) {
                        yyerror("| avec des non entiers"); 
                        $$ = ERROR_TYPE;
                } else {
                        $$ = INT_TYPE;
                }}
            | expression '>' expression {
                if ($1 == ERROR_TYPE || $3 == ERROR_TYPE) {
                        $$ = ERROR_TYPE;
                } else if ($1 == MATRIX_TYPE || $3 == MATRIX_TYPE) {
                        yyerror("> avec des matrices");
                        $$ = ERROR_TYPE;
                } else if ($1 == TABLEAU_TYPE || $3 == TABLEAU_TYPE) {
                        yyerror("> avec des tableaux");
                        $$ = ERROR_TYPE;
                } else {
                        $$ = INT_TYPE;
                }}
            | expression '<' expression {
                if ($1 == ERROR_TYPE || $3 == ERROR_TYPE) {
                        $$ = ERROR_TYPE;
                } else if ($1 == MATRIX_TYPE || $3 == MATRIX_TYPE) {
                        yyerror("< avec des matrices");
                        $$ = ERROR_TYPE;
                } else if ($1 == TABLEAU_TYPE || $3 == TABLEAU_TYPE) {
                        yyerror("< avec des tableaux");
                        $$ = ERROR_TYPE;
                } else {
                        $$ = INT_TYPE;
                }}
            | expression LE expression {
                if ($1 == ERROR_TYPE || $3 == ERROR_TYPE) {
                        $$ = ERROR_TYPE;
                } else if ($1 == MATRIX_TYPE || $3 == MATRIX_TYPE) {
                        yyerror("<= avec des matrices");
                        $$ = ERROR_TYPE;
                } else if ($1 == TABLEAU_TYPE || $3 == TABLEAU_TYPE) {
                        yyerror("<= avec des tableaux");
                        $$ = ERROR_TYPE;
                } else {
                        $$ = INT_TYPE;
                }}
            | expression GE expression {
                if ($1 == ERROR_TYPE || $3 == ERROR_TYPE) {
                        $$ = ERROR_TYPE;
                } else if ($1 == MATRIX_TYPE || $3 == MATRIX_TYPE) {
                        yyerror(">= avec des matrices");
                        $$ = ERROR_TYPE;
                } else if ($1 == TABLEAU_TYPE || $3 == TABLEAU_TYPE) {
                        yyerror(">= avec des tableaux");
                        $$ = ERROR_TYPE;
                } else {
                        $$ = INT_TYPE;
                }}
            | expression EQ expression {
                if ($1 == ERROR_TYPE || $3 == ERROR_TYPE) {
                        $$ = ERROR_TYPE;
                } else if ($1 == MATRIX_TYPE || $3 == MATRIX_TYPE) {
                        yyerror("== avec des matrices");
                        $$ = ERROR_TYPE;
                } else if ($1 == TABLEAU_TYPE || $3 == TABLEAU_TYPE) {
                        yyerror("== avec des tableaux");
                        $$ = ERROR_TYPE;
                } else {
                        $$ = INT_TYPE;
                }}
            | expression NE expression {
                if ($1 == ERROR_TYPE || $3 == ERROR_TYPE) {
                        $$ = ERROR_TYPE;
                } else if ($1 == MATRIX_TYPE || $3 == MATRIX_TYPE) {
                        yyerror("!= avec des matrices");
                        $$ = ERROR_TYPE;
                } else if ($1 == TABLEAU_TYPE || $3 == TABLEAU_TYPE) {
                        yyerror("!= avec des tableaux");
                        $$ = ERROR_TYPE;
                } else {
                        $$ = INT_TYPE;
                }}
            | expression LOGICAL_AND expression {
                if ($1 == ERROR_TYPE || $3 == ERROR_TYPE) {
                        $$ = ERROR_TYPE;
                } else if ($1 == MATRIX_TYPE || $3 == MATRIX_TYPE) {
                        yyerror("&& avec des matrices");
                        $$ = ERROR_TYPE;
                } else if ($1 == TABLEAU_TYPE || $3 == TABLEAU_TYPE) {
                        yyerror("&& avec des tableaux");
                        $$ = ERROR_TYPE;
                } else {
                        $$ = INT_TYPE;
                }}
            | expression LOGICAL_OR expression {
                if ($1 == ERROR_TYPE || $3 == ERROR_TYPE) {
                        $$ = ERROR_TYPE;
                } else if ($1 == MATRIX_TYPE || $3 == MATRIX_TYPE) {
                        yyerror("|| avec des matrices");
                        $$ = ERROR_TYPE;
                } else if ($1 == TABLEAU_TYPE || $3 == TABLEAU_TYPE) {
                        yyerror("|| avec des tableaux");
                        $$ = ERROR_TYPE;
                } else {
                        $$ = INT_TYPE;
                }}
            | '-' expression %prec UNARY {
                if ($2 == TABLEAU_TYPE) {
                        yyerror("- avec un tableau");
                        $$ = ERROR_TYPE;
                } else {
                        $$ = $2;
                }}
            | '+' expression %prec UNARY {
                if ($2 == TABLEAU_TYPE) {
                        yyerror("+ avec un tableau");
                        $$ = ERROR_TYPE;
                } else {
                        $$ = $2;
                }}
            | '!' expression %prec UNARY {
                if ($2 == ERROR_TYPE) {
                        $$ = ERROR_TYPE;
                } else if ($2 == MATRIX_TYPE) {
                        yyerror("! avec une matrix");
                        $$ = ERROR_TYPE;
                } else if ($2 == TABLEAU_TYPE) {
                        yyerror("! avec un tableau");
                        $$ = ERROR_TYPE;
                } else {
                        $$ = INT_TYPE;
                }}
            | '~' expression %prec UNARY {
                if ($2 == ERROR_TYPE) {
                        $$ = ERROR_TYPE;
                } else if ($2 == FLOAT_TYPE) {
                        yyerror("~ avec un float");
                        $$ = ERROR_TYPE;
                } else if ($2 == TABLEAU_TYPE) {
                        yyerror("~ avec un tableau");
                        $$ = ERROR_TYPE;
                } else {
                        $$ = $2;
                }}
            /*| '*' expression %prec UNARY    //On fait les pointeurs ?
            | '&' expression %prec UNARY*/
            | '(' expression ')' {$$ = $2;}
;

       
intervalle_dimension : intervalle_dimension '[' liste_rangee ']' { $$.nDim = $1.nDim + 1;
                        if ($1.type_tab == ERROR_TYPE || $3.type_tab == ERROR_TYPE) {
                                $$.type_tab = ERROR_TYPE;
                        } else if ($1.type_tab == MATRIX_TYPE || $3.type_tab == MATRIX_TYPE) {
                                if ($$.nDim > 2) {
                                        yyerror("Matrice à plus de 2 dimensions");
                                        $$.type_tab = ERROR_TYPE;
                                } else {
                                        $$.type_tab = MATRIX_TYPE; //Matrix exclusivement
                                }
                        } else {
                                $$.type_tab = TABLEAU_TYPE; //Tableau ou matrix
                        }}
                        | '[' liste_rangee ']' {$$.type_tab = $2.type_tab; $$.nDim = 1;}
;

liste_rangee : liste_rangee ';' rangee { $$.nDim = $1.nDim + 1;
                if ($1.type_tab == ERROR_TYPE || $3.type_tab == ERROR_TYPE) {
                        $$.type_tab = ERROR_TYPE;
                } else if ($1.type_tab == MATRIX_TYPE || $3.type_tab == MATRIX_TYPE) {
                        $$.type_tab = MATRIX_TYPE; //Matrix exclusivement
                } else {
                        $$.type_tab = TABLEAU_TYPE; //Tableau ou matrix
                }}
                | rangee {$$ = $1; $$.nDim = 1;}
;

rangee : '*' {$$.type_tab = MATRIX_TYPE; /*Matrix exclusivement*/} 
        | expression INTERV_OP expression { 
        if ($1 != INT_TYPE || $3 != INT_TYPE) {
                yyerror("Dimension non entière");
                $$.type_tab = ERROR_TYPE;
        } else {
                $$.type_tab = MATRIX_TYPE; //Matrix exclusivement
        }}
        | expression {if ($1 != INT_TYPE) {
                yyerror("Dimension non entière");
                $$.type_tab = ERROR_TYPE;
        } else {
                $$.type_tab = TABLEAU_TYPE; //Tableau ou matrix
        }}
;

valeur_tableau : '{' liste_nombre '}' {$$ = $2; $$.nDim = 1;}
		| '{' liste_tableau '}' {$$ = $2; $$.nDim = $2.nDim + 1;}
;
		
liste_tableau : liste_tableau ',' valeur_tableau {$$.nDim = ($1.nDim >= $3.nDim ? $1.nDim : $3.nDim);
                if ($1.type_tab == ERROR_TYPE || $3.type_tab == ERROR_TYPE) {
                        $$.type_tab = ERROR_TYPE;
                } else if ($1.type_tab != $3.type_tab) {
                        yyerror("Tableau de plusieurs types différents");
                        $$.type_tab = ERROR_TYPE;
                } else {
                        $$.type_tab = $1.type_tab;
                }}
		| valeur_tableau {$$ = $1;}
;

liste_nombre : liste_entiers {$$.type_tab = INT_TYPE;} | liste_flottants {$$.type_tab = FLOAT_TYPE;}
;

liste_flottants : liste_flottants ',' C_FLOAT | C_FLOAT
;

liste_entiers : liste_entiers ',' C_INT | C_INT 
;

incr_et_decr : IDENT INCR | IDENT DECR | INCR IDENT | DECR IDENT 
;

type : INT {$$ = INT_TYPE;} | FLOAT {$$ = FLOAT_TYPE;} | MATRIX {$$ = MATRIX_TYPE;}
;

valeur : IDENT {$$ = INT_TYPE;} //TODO
        | constante {$$ = $1;}
        | IDENT intervalle_dimension {$$ = INT_TYPE;} //TODO
        | incr_et_decr {$$ = INT_TYPE;}
        | appel_fonction {$$ = INT_TYPE;} //TODO
;

constante : C_INT {$$ = INT_TYPE;} | C_FLOAT {$$ = FLOAT_TYPE;}
;

assign : '=' | PLUS_ASSIGN | MINUS_ASSIGN | MULT_ASSIGN | DIV_ASSIGN | MOD_ASSIGN | AND_ASSIGN | XOR_ASSIGN | OR_ASSIGN
;
            
%%  

void yyerror(const char* msg)
{
        syntaxe_error = 1;
	fprintf(stderr, "Syntaxe error : %s\n", msg);
}
