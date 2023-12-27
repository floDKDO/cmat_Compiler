%{

extern int yylex();
void yyerror(const char* msg);

int syntaxe_error = 0;

int indice_tab_str = 0;

%}

%define parse.error verbose //indique le type d'erreur de syntaxe

%code requires {
    #include "global.h"
}


%union 
{
	struct u_tab {
		enum type type_tab;
		int nDim;
	} tableau;
	
	enum QuadOp op;
	
	char nom[MAX_LENGTH_VAR_NAME];
	
	float constante_flottante;
	int constante_entiere;
	
	struct {
		struct noeud* ptr;
	} exprval;
	
	char tab_str[64][MAX_LENGTH_VAR_NAME]; //limite arbitraire : 64 chaînes de 64 caractères max
	
	enum type type;
}

%token INTERV_OP LOGICAL_AND LOGICAL_OR
%token PLUS_ASSIGN MINUS_ASSIGN MULT_ASSIGN DIV_ASSIGN MOD_ASSIGN AND_ASSIGN XOR_ASSIGN OR_ASSIGN
%token LE GE EQ NE 
%token INT FLOAT MATRIX
%token IF ELSE FOR RETURN  
%token MAIN PRINTF PRINT PRINTMAT WHILE
%token C_STR

%token <nom> IDENT
%type <nom> variable_declaree
%token <op> INCR DECR
%type <tableau> intervalle_dimension valeur_tableau liste_tableau liste_nombre rangee liste_rangee
%type <op> assign
%token <constante_entiere> C_INT 
%token <constante_flottante> C_FLOAT
%type <constante_entiere> constante_entiere 
%type <constante_flottante> constante_flottante
%type <tab_str> liste_variable_declaree

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

%type <exprval> expression incr_et_decr valeur 
%type <type> type;

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
	{
		for(int i = 0; i < indice_tab_str; i++) { //mettre le type dans la tds
			struct noeud* noeud = get_symbole(tds, $2[i]);
			if(noeud != NULL)
				noeud->info.type = $1;
			}
	}
;

liste_variable_declaree : liste_variable_declaree ',' variable_declaree {strcpy($$[indice_tab_str], $3); indice_tab_str += 1;}
			| variable_declaree {strcpy($$[indice_tab_str], $1); indice_tab_str += 1;}
;

variable_declaree : 
	IDENT {struct noeud* entree = insertion(&tds, $1, SORTE_VARIABLE, TYPE_NONE); /*strcpy($$, $1);*/}
    | IDENT '=' expression {
			struct noeud* entree = insertion(&tds, $1, SORTE_VARIABLE, TYPE_NONE);
            
            if(entree == NULL) {
                fprintf(stderr,"Previous declaration of %s exists\n", $1); 
                exit(1);
            }
            
			gencode(liste_quad, QOP_ASSIGN, $3.ptr, NULL, entree);
			
			//strcpy($$, $1);
		}
    | IDENT intervalle_dimension {}
    | IDENT intervalle_dimension '=' valeur_tableau {}
;


liste_operation : 
	liste_operation ',' operation
	| operation
;

operation : expression
	| IDENT assign operation
	| IDENT intervalle_dimension assign operation
;

declaration_fonction : 
	type IDENT '(' liste_parametre ')' corps
    | type IDENT '(' ')' corps
;
		 
appel_fonction : 
	IDENT '(' liste_argument ')'
    | IDENT '(' ')'
	| PRINTF '(' C_STR ')'
	| PRINT '(' constante_entiere ')'
	| PRINT '(' constante_flottante ')'
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

expression : 
	valeur {
			struct noeud* entree;
			if($1.ptr->info.sorte == SORTE_CONSTANTE) {
				if($1.ptr->info.type == TYPE_INT)
					entree = get_symbole_constante_int(tds, $1.ptr->info.valeur_entiere);
				else if($1.ptr->info.type == TYPE_FLOAT)
					entree = get_symbole_constante(tds, $1.ptr->info.valeur_flottante);
			} else entree = get_symbole(tds, $1.ptr->info.nom);
			
			$$.ptr = entree;
		}
	| expression '+' expression {
			if($1.ptr->info.type == TYPE_ERROR || $3.ptr->info.type == TYPE_ERROR) {
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if(($1.ptr->info.sorte == SORTE_TABLEAU && $1.ptr->info.type != TYPE_MATRIX) || ($3.ptr->info.sorte == SORTE_TABLEAU && $3.ptr->info.type != TYPE_MATRIX)) {
				yyerror("+ avec des tableaux");
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($1.ptr->info.type == TYPE_MATRIX) {
				//$$.ptr = newtemp(&tds, TYPE_ERROR); => pas encore géré
			} else if($3.ptr->info.type == TYPE_MATRIX) {
				//$$.ptr = newtemp(&tds, TYPE_ERROR); => pas encore géré
			} else if($1.ptr->info.type == TYPE_FLOAT) {
				$$.ptr = newtemp(&tds, TYPE_FLOAT);
				if ($3.ptr->info.type == TYPE_INT) {
					struct noeud *tmp = newtemp(&tds, TYPE_FLOAT);
					gencode(liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
					gencode(liste_quad, QOP_PLUS, $1.ptr, tmp, $$.ptr);
				} else {
					gencode(liste_quad, QOP_PLUS, $1.ptr, $3.ptr, $$.ptr);
				}
			} else if ($3.ptr->info.type == TYPE_FLOAT){
				struct noeud *tmp = newtemp(&tds, TYPE_FLOAT);
				gencode(liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
				$$.ptr = newtemp(&tds, TYPE_FLOAT);
				gencode(liste_quad, QOP_PLUS, $1.ptr, tmp, $$.ptr);
			} else if($1.ptr->info.type == TYPE_INT && $3.ptr->info.type == TYPE_INT) {
				$$.ptr = newtemp(&tds, TYPE_INT);
				gencode(liste_quad, QOP_PLUS, $1.ptr, $3.ptr, $$.ptr);
			} else {
				$$.ptr = newtemp(&tds, TYPE_NONE);
			}
		}
	| expression '-' expression {          
			if($1.ptr->info.type == TYPE_ERROR || $3.ptr->info.type == TYPE_ERROR) {
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if(($1.ptr->info.sorte == SORTE_TABLEAU && $1.ptr->info.type != TYPE_MATRIX) || ($3.ptr->info.sorte == SORTE_TABLEAU && $3.ptr->info.type != TYPE_MATRIX)) {
				yyerror("- avec des tableaux");
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($1.ptr->info.type == TYPE_MATRIX) {
				//$$.ptr = newtemp(&tds, TYPE_ERROR); => pas encore géré
			} else if($3.ptr->info.type == TYPE_MATRIX) {
				//$$.ptr = newtemp(&tds, TYPE_ERROR); => pas encore géré
			} else if($1.ptr->info.type == TYPE_FLOAT) {
				$$.ptr = newtemp(&tds, TYPE_FLOAT);
				if ($3.ptr->info.type == TYPE_INT) {
					struct noeud *tmp = newtemp(&tds, TYPE_FLOAT);
					gencode(liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
					gencode(liste_quad, QOP_MINUS, $1.ptr, tmp, $$.ptr);
				} else {
					gencode(liste_quad, QOP_MINUS, $1.ptr, $3.ptr, $$.ptr);
				}
			} else if ($3.ptr->info.type == TYPE_FLOAT){
				struct noeud *tmp = newtemp(&tds, TYPE_FLOAT);
				gencode(liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
				$$.ptr = newtemp(&tds, TYPE_FLOAT);
				gencode(liste_quad, QOP_MINUS, $1.ptr, tmp, $$.ptr);
			} else if($1.ptr->info.type == TYPE_INT && $3.ptr->info.type == TYPE_INT) {
				$$.ptr = newtemp(&tds, TYPE_INT);
				gencode(liste_quad, QOP_MINUS, $1.ptr, $3.ptr, $$.ptr);
			} else {
				$$.ptr = newtemp(&tds, TYPE_NONE);
			}
		}
    | expression '*' expression {
			if($1.ptr->info.type == TYPE_ERROR || $3.ptr->info.type == TYPE_ERROR) {
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if(($1.ptr->info.sorte == SORTE_TABLEAU && $1.ptr->info.type != TYPE_MATRIX) || ($3.ptr->info.sorte == SORTE_TABLEAU && $3.ptr->info.type != TYPE_MATRIX)) {
				yyerror("* avec des tableaux");
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($1.ptr->info.type == TYPE_MATRIX) {
				//$$.ptr = newtemp(&tds, TYPE_ERROR); => pas encore géré
			} else if($3.ptr->info.type == TYPE_MATRIX) {
				//$$.ptr = newtemp(&tds, TYPE_ERROR); => pas encore géré
			} else if($1.ptr->info.type == TYPE_FLOAT) {
				$$.ptr = newtemp(&tds, TYPE_FLOAT);
				if ($3.ptr->info.type == TYPE_INT) {
					struct noeud *tmp = newtemp(&tds, TYPE_FLOAT);
					gencode(liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
					gencode(liste_quad, QOP_MULT, $1.ptr, tmp, $$.ptr);
				} else {
					gencode(liste_quad, QOP_MULT, $1.ptr, $3.ptr, $$.ptr);
				}
			} else if ($3.ptr->info.type == TYPE_FLOAT){
				struct noeud *tmp = newtemp(&tds, TYPE_FLOAT);
				gencode(liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
				$$.ptr = newtemp(&tds, TYPE_FLOAT);
				gencode(liste_quad, QOP_MULT, $1.ptr, tmp, $$.ptr);
			} else if($1.ptr->info.type == TYPE_INT && $3.ptr->info.type == TYPE_INT) {
				$$.ptr = newtemp(&tds, TYPE_INT);
				gencode(liste_quad, QOP_MULT, $1.ptr, $3.ptr, $$.ptr);
			} else {
				$$.ptr = newtemp(&tds, TYPE_NONE);
			}
		}
    | expression '/' expression {
			if($1.ptr->info.type == TYPE_ERROR || $3.ptr->info.type == TYPE_ERROR) {
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if(($1.ptr->info.sorte == SORTE_TABLEAU && $1.ptr->info.type != TYPE_MATRIX) || ($3.ptr->info.sorte == SORTE_TABLEAU && $3.ptr->info.type != TYPE_MATRIX)) {
				yyerror("/ avec des tableaux");
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($1.ptr->info.type == TYPE_MATRIX) {
				//$$.ptr = newtemp(&tds, TYPE_ERROR); => pas encore géré
			} else if($3.ptr->info.type == TYPE_MATRIX) {
				//$$.ptr = newtemp(&tds, TYPE_ERROR); => pas encore géré
			} else if($1.ptr->info.type == TYPE_FLOAT) {
				$$.ptr = newtemp(&tds, TYPE_FLOAT);
				if ($3.ptr->info.type == TYPE_INT) {
					struct noeud *tmp = newtemp(&tds, TYPE_FLOAT);
					gencode(liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
					gencode(liste_quad, QOP_DIV, $1.ptr, tmp, $$.ptr);
				} else {
					gencode(liste_quad, QOP_DIV, $1.ptr, $3.ptr, $$.ptr);
				}
			} else if ($3.ptr->info.type == TYPE_FLOAT){
				struct noeud *tmp = newtemp(&tds, TYPE_FLOAT);
				gencode(liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
				$$.ptr = newtemp(&tds, TYPE_FLOAT);
				gencode(liste_quad, QOP_DIV, $1.ptr, tmp, $$.ptr);
			} else if($1.ptr->info.type == TYPE_INT && $3.ptr->info.type == TYPE_INT) {
				$$.ptr = newtemp(&tds, TYPE_INT);
				gencode(liste_quad, QOP_DIV, $1.ptr, $3.ptr, $$.ptr);
			} else {
				$$.ptr = newtemp(&tds, TYPE_NONE);
			}
		}
    | expression '%' expression {
			if($1.ptr->info.type == TYPE_ERROR || $3.ptr->info.type == TYPE_ERROR) {
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($1.ptr->info.type != TYPE_INT || $1.ptr->info.sorte == SORTE_TABLEAU || $3.ptr->info.type != TYPE_INT || $3.ptr->info.sorte == SORTE_TABLEAU) {
				yyerror("\% avec des non entiers");
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else {
				$$.ptr = newtemp(&tds, TYPE_INT);
				gencode(liste_quad, QOP_MOD, $1.ptr, $3.ptr, $$.ptr);
			}
		}
    | expression '^' expression {
			if($1.ptr->info.type == TYPE_ERROR || $3.ptr->info.type == TYPE_ERROR) {
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($1.ptr->info.type != TYPE_INT || $1.ptr->info.sorte == SORTE_TABLEAU || $3.ptr->info.type != TYPE_INT || $3.ptr->info.sorte == SORTE_TABLEAU) {
				yyerror("^ avec des non entiers");
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else {
				$$.ptr = newtemp(&tds, TYPE_INT);
				gencode(liste_quad, QOP_XOR, $1.ptr, $3.ptr, $$.ptr);
			}
		}
    | expression '&' expression {
			if($1.ptr->info.type == TYPE_ERROR || $3.ptr->info.type == TYPE_ERROR) {
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($1.ptr->info.type != TYPE_INT || $1.ptr->info.sorte == SORTE_TABLEAU || $3.ptr->info.type != TYPE_INT || $3.ptr->info.sorte == SORTE_TABLEAU) {
				yyerror("& avec des non entiers");
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else {
				$$.ptr = newtemp(&tds, TYPE_INT);
				gencode(liste_quad, QOP_AND, $1.ptr, $3.ptr, $$.ptr);
			}
		}
    | expression '|' expression {
			if($1.ptr->info.type == TYPE_ERROR || $3.ptr->info.type == TYPE_ERROR) {
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($1.ptr->info.type != TYPE_INT || $1.ptr->info.sorte == SORTE_TABLEAU || $3.ptr->info.type != TYPE_INT || $3.ptr->info.sorte == SORTE_TABLEAU) {
				yyerror("| avec des non entiers");
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else {
				$$.ptr = newtemp(&tds, TYPE_INT);
				gencode(liste_quad, QOP_OR, $1.ptr, $3.ptr, $$.ptr);
			}
		}
    | expression '>' expression {
			if($1.ptr->info.type == TYPE_ERROR || $3.ptr->info.type == TYPE_ERROR) {
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($1.ptr->info.sorte == SORTE_TABLEAU || $3.ptr->info.sorte == SORTE_TABLEAU) {
				yyerror("> avec des tableaux/matrices");
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($1.ptr->info.type == TYPE_FLOAT) {
				$$.ptr = newtemp(&tds, TYPE_INT);
				if ($3.ptr->info.type == TYPE_INT) {
					struct noeud *tmp = newtemp(&tds, TYPE_FLOAT);
					gencode(liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
					gencode(liste_quad, QOP_GT, $1.ptr, tmp, $$.ptr);
				} else {
					gencode(liste_quad, QOP_GT, $1.ptr, $3.ptr, $$.ptr);
				}
			} else if ($3.ptr->info.type == TYPE_FLOAT){
				struct noeud *tmp = newtemp(&tds, TYPE_FLOAT);
				gencode(liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
				$$.ptr = newtemp(&tds, TYPE_INT);
				gencode(liste_quad, QOP_GT, $1.ptr, tmp, $$.ptr);
			} else if($1.ptr->info.type == TYPE_INT && $3.ptr->info.type == TYPE_INT) {
				$$.ptr = newtemp(&tds, TYPE_INT);
				gencode(liste_quad, QOP_GT, $1.ptr, $3.ptr, $$.ptr);
			} else {
				$$.ptr = newtemp(&tds, TYPE_NONE);
			}
		}
    | expression '<' expression {
			if($1.ptr->info.type == TYPE_ERROR || $3.ptr->info.type == TYPE_ERROR) {
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($1.ptr->info.sorte == SORTE_TABLEAU || $3.ptr->info.sorte == SORTE_TABLEAU) {
				yyerror("< avec des tableaux/matrices");
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($1.ptr->info.type == TYPE_FLOAT) {
				$$.ptr = newtemp(&tds, TYPE_INT);
				if ($3.ptr->info.type == TYPE_INT) {
					struct noeud *tmp = newtemp(&tds, TYPE_FLOAT);
					gencode(liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
					gencode(liste_quad, QOP_LT, $1.ptr, tmp, $$.ptr);
				} else {
					gencode(liste_quad, QOP_LT, $1.ptr, $3.ptr, $$.ptr);
				}
			} else if ($3.ptr->info.type == TYPE_FLOAT){
				struct noeud *tmp = newtemp(&tds, TYPE_FLOAT);
				gencode(liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
				$$.ptr = newtemp(&tds, TYPE_FLOAT);
				gencode(liste_quad, QOP_LT, $1.ptr, tmp, $$.ptr);
			} else if($1.ptr->info.type == TYPE_INT && $3.ptr->info.type == TYPE_INT) {
				$$.ptr = newtemp(&tds, TYPE_INT);
				gencode(liste_quad, QOP_LT, $1.ptr, $3.ptr, $$.ptr);
			} else {
				$$.ptr = newtemp(&tds, TYPE_NONE);
			}
		}
    | expression LE expression {
			if($1.ptr->info.type == TYPE_ERROR || $3.ptr->info.type == TYPE_ERROR) {
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($1.ptr->info.sorte == SORTE_TABLEAU || $3.ptr->info.sorte == SORTE_TABLEAU) {
				yyerror("<= avec des tableaux/matrices");
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($1.ptr->info.type == TYPE_FLOAT) {
				$$.ptr = newtemp(&tds, TYPE_INT);
				if ($3.ptr->info.type == TYPE_INT) {
					struct noeud *tmp = newtemp(&tds, TYPE_FLOAT);
					gencode(liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
					gencode(liste_quad, QOP_LE, $1.ptr, tmp, $$.ptr);
				} else {
					gencode(liste_quad, QOP_LE, $1.ptr, $3.ptr, $$.ptr);
				}
			} else if ($3.ptr->info.type == TYPE_FLOAT){
				struct noeud *tmp = newtemp(&tds, TYPE_FLOAT);
				gencode(liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
				$$.ptr = newtemp(&tds, TYPE_FLOAT);
				gencode(liste_quad, QOP_LE, $1.ptr, tmp, $$.ptr);
			} else if($1.ptr->info.type == TYPE_INT && $3.ptr->info.type == TYPE_INT) {
				$$.ptr = newtemp(&tds, TYPE_INT);
				gencode(liste_quad, QOP_LE, $1.ptr, $3.ptr, $$.ptr);
			} else {
				$$.ptr = newtemp(&tds, TYPE_NONE);
			}
		}
    | expression GE expression {
			if($1.ptr->info.type == TYPE_ERROR || $3.ptr->info.type == TYPE_ERROR) {
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($1.ptr->info.sorte == SORTE_TABLEAU || $3.ptr->info.sorte == SORTE_TABLEAU) {
				yyerror(">= avec des tableaux/matrices");
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($1.ptr->info.type == TYPE_FLOAT) {
				$$.ptr = newtemp(&tds, TYPE_INT);
				if ($3.ptr->info.type == TYPE_INT) {
					struct noeud *tmp = newtemp(&tds, TYPE_FLOAT);
					gencode(liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
					gencode(liste_quad, QOP_GE, $1.ptr, tmp, $$.ptr);
				} else {
					gencode(liste_quad, QOP_GE, $1.ptr, $3.ptr, $$.ptr);
				}
			} else if ($3.ptr->info.type == TYPE_FLOAT){
				struct noeud *tmp = newtemp(&tds, TYPE_FLOAT);
				gencode(liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
				$$.ptr = newtemp(&tds, TYPE_FLOAT);
				gencode(liste_quad, QOP_GE, $1.ptr, tmp, $$.ptr);
			} else if($1.ptr->info.type == TYPE_INT && $3.ptr->info.type == TYPE_INT) {
				$$.ptr = newtemp(&tds, TYPE_INT);
				gencode(liste_quad, QOP_GE, $1.ptr, $3.ptr, $$.ptr);
			} else {
				$$.ptr = newtemp(&tds, TYPE_NONE);
			}
		}
    | expression EQ expression {
			if($1.ptr->info.type == TYPE_ERROR || $3.ptr->info.type == TYPE_ERROR) {
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($1.ptr->info.sorte == SORTE_TABLEAU || $3.ptr->info.sorte == SORTE_TABLEAU) {
				yyerror("== avec des tableaux/matrices");
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($1.ptr->info.type == TYPE_FLOAT) {
				$$.ptr = newtemp(&tds, TYPE_INT);
				if ($3.ptr->info.type == TYPE_INT) {
					struct noeud *tmp = newtemp(&tds, TYPE_FLOAT);
					gencode(liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
					gencode(liste_quad, QOP_EQ, $1.ptr, tmp, $$.ptr);
				} else {
					gencode(liste_quad, QOP_EQ, $1.ptr, $3.ptr, $$.ptr);
				}
			} else if ($3.ptr->info.type == TYPE_FLOAT){
				struct noeud *tmp = newtemp(&tds, TYPE_FLOAT);
				gencode(liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
				$$.ptr = newtemp(&tds, TYPE_FLOAT);
				gencode(liste_quad, QOP_EQ, $1.ptr, tmp, $$.ptr);
			} else if($1.ptr->info.type == TYPE_INT && $3.ptr->info.type == TYPE_INT) {
				$$.ptr = newtemp(&tds, TYPE_INT);
				gencode(liste_quad, QOP_EQ, $1.ptr, $3.ptr, $$.ptr);
			} else {
				$$.ptr = newtemp(&tds, TYPE_NONE);
			}
		}
    | expression NE expression {
			if($1.ptr->info.type == TYPE_ERROR || $3.ptr->info.type == TYPE_ERROR) {
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($1.ptr->info.sorte == SORTE_TABLEAU || $3.ptr->info.sorte == SORTE_TABLEAU) {
				yyerror("!= avec des tableaux/matrices");
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($1.ptr->info.type == TYPE_FLOAT) {
				$$.ptr = newtemp(&tds, TYPE_INT);
				if ($3.ptr->info.type == TYPE_INT) {
					struct noeud *tmp = newtemp(&tds, TYPE_FLOAT);
					gencode(liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
					gencode(liste_quad, QOP_NE, $1.ptr, tmp, $$.ptr);
				} else {
					gencode(liste_quad, QOP_NE, $1.ptr, $3.ptr, $$.ptr);
				}
			} else if ($3.ptr->info.type == TYPE_FLOAT){
				struct noeud *tmp = newtemp(&tds, TYPE_FLOAT);
				gencode(liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
				$$.ptr = newtemp(&tds, TYPE_FLOAT);
				gencode(liste_quad, QOP_NE, $1.ptr, tmp, $$.ptr);
			} else if($1.ptr->info.type == TYPE_INT && $3.ptr->info.type == TYPE_INT) {
				$$.ptr = newtemp(&tds, TYPE_INT);
				gencode(liste_quad, QOP_NE, $1.ptr, $3.ptr, $$.ptr);
			} else {
				$$.ptr = newtemp(&tds, TYPE_NONE);
			}
		}
    | expression LOGICAL_AND expression { //à revoir parce que le AND n'existe pas en MIPS
			if($1.ptr->info.type == TYPE_ERROR || $3.ptr->info.type == TYPE_ERROR) {
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($1.ptr->info.type != TYPE_INT || $1.ptr->info.sorte == SORTE_TABLEAU || $3.ptr->info.type != TYPE_INT || $3.ptr->info.sorte == SORTE_TABLEAU) {
				yyerror("&& avec des non entiers");
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else {
				$$.ptr = newtemp(&tds, TYPE_INT);
				gencode(liste_quad, QOP_AND, $1.ptr, $3.ptr, $$.ptr);
			}
		}
	| expression LOGICAL_OR expression {//à revoir parce que le OR n'existe pas en MIPS
			if($1.ptr->info.type == TYPE_ERROR || $3.ptr->info.type == TYPE_ERROR) {
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($1.ptr->info.type != TYPE_INT || $1.ptr->info.sorte == SORTE_TABLEAU || $3.ptr->info.type != TYPE_INT || $3.ptr->info.sorte == SORTE_TABLEAU) {
				yyerror("|| avec des non entiers");
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else {
				$$.ptr = newtemp(&tds, TYPE_INT);
				gencode(liste_quad, QOP_OR, $1.ptr, $3.ptr, $$.ptr);
			}
		}
    | '-' expression %prec UNARY {
			if($2.ptr->info.type == TYPE_ERROR) {
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($2.ptr->info.sorte == SORTE_TABLEAU && $2.ptr->info.type != TYPE_MATRIX) {
				yyerror("- avec un tableau");
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($2.ptr->info.type == TYPE_MATRIX) {
				//$$.ptr = newtemp(&tds, TYPE_ERROR); => pas encore géré
			} else if($2.ptr->info.type == TYPE_FLOAT) {
				$$.ptr = newtemp(&tds, TYPE_FLOAT);
				gencode(liste_quad, QOP_UNARY_MINUS, $2.ptr, NULL, $$.ptr);
			} else if($2.ptr->info.type == TYPE_INT) {
				$$.ptr = newtemp(&tds, TYPE_INT);
				gencode(liste_quad, QOP_UNARY_MINUS, $2.ptr, NULL, $$.ptr);
			} else {
				$$.ptr = newtemp(&tds, TYPE_NONE);
			}
		}
    | '+' expression %prec UNARY {
			$$ = $2;
		}
    | '!' expression %prec UNARY {
			if($2.ptr->info.type == TYPE_ERROR) {
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($2.ptr->info.sorte == SORTE_TABLEAU) {
				yyerror("! avec un tableau/une matrice");
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($2.ptr->info.type == TYPE_FLOAT || $2.ptr->info.type == TYPE_INT) {
				$$.ptr = newtemp(&tds, TYPE_INT);
				gencode(liste_quad, QOP_NOT, $2.ptr, NULL, $$.ptr);
			} else {
				$$.ptr = newtemp(&tds, TYPE_NONE);
			}
		}
    | '~' expression %prec UNARY {
			if($2.ptr->info.type == TYPE_ERROR) {
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($2.ptr->info.sorte == SORTE_TABLEAU && $2.ptr->info.type != TYPE_MATRIX) {
				yyerror("~ avec un tableau");
				$$.ptr = newtemp(&tds, TYPE_ERROR);
			} else if($2.ptr->info.type == TYPE_FLOAT) {
				yyerror("~ avec un flottant");
			} else if($2.ptr->info.type == TYPE_MATRIX) {
				//$$.ptr = newtemp(&tds, TYPE_ERROR); => pas encore géré
			} else if($2.ptr->info.type == TYPE_INT) {
				$$.ptr = newtemp(&tds, TYPE_INT);
				gencode(liste_quad, QOP_NEG, $2.ptr, NULL, $$.ptr);
			} else {
				$$.ptr = newtemp(&tds, TYPE_NONE);
			}
		}
    /*| '*' expression %prec UNARY    //On fait les pointeurs ?
    | '&' expression %prec UNARY*/
    | '(' expression ')' {$$ = $2;}
;

       
intervalle_dimension : 
	intervalle_dimension '[' liste_rangee ']' {$$.nDim = $1.nDim + 1;}
    | '[' liste_rangee ']' {$$.type_tab = $2.type_tab; $$.nDim = 1;}
;

liste_rangee : 
	liste_rangee ';' rangee { $$.nDim = $1.nDim + 1;}
    | rangee {$$ = $1; $$.nDim = 1;}
;

rangee : '*' {$$.type_tab = TYPE_MATRIX; /*Matrix exclusivement*/} 
        | expression INTERV_OP expression {}
        | expression {}
;

valeur_tableau : '{' liste_nombre '}' {$$ = $2; $$.nDim = 1;}
		| '{' liste_tableau '}' {$$ = $2; $$.nDim = $2.nDim + 1;}
;
		
liste_tableau : liste_tableau ',' valeur_tableau {$$.nDim = ($1.nDim >= $3.nDim ? $1.nDim : $3.nDim);
}
		| valeur_tableau {$$ = $1;}
;

liste_nombre : liste_entiers {$$.type_tab = TYPE_INT;} | liste_flottants {$$.type_tab = TYPE_FLOAT;}
;

liste_flottants : liste_flottants ',' C_FLOAT | C_FLOAT
;

liste_entiers : liste_entiers ',' C_INT | C_INT 
;

type : INT {$$ = TYPE_INT;} | FLOAT {$$ = TYPE_FLOAT;} | MATRIX {$$ = TYPE_MATRIX;}
;

valeur : 
	IDENT {
			struct noeud* entree = get_symbole(tds, $1); 
			if(entree == NULL) {
				char err_msg[MAX_LENGTH_VAR_NAME + 20];
				sprintf(err_msg, "Undeclared name : '%s'", $1);
				yyerror(err_msg);
				entree = insertion(&tds, $1, SORTE_NONE, TYPE_ERROR);
			}
			$$.ptr = entree;
		}	
	| constante_entiere {
        	struct noeud* entree = get_symbole_constante_int(tds, $1);
		    $$.ptr = entree;
		}
	| constante_flottante {
			struct noeud* entree = get_symbole_constante(tds, $1);	
			$$.ptr = entree;
		}
    | IDENT intervalle_dimension {} 
    | incr_et_decr {
			struct noeud* entree = get_symbole(tds, $1.ptr->info.nom); 
		    if(entree == NULL) {
				entree = insertion(&tds, $1.ptr->info.nom, SORTE_VARIABLE, TYPE_NONE);
			}
			$$.ptr = entree;
		}
    | appel_fonction {} 
;

incr_et_decr : 
	IDENT INCR {
			$2 = QOP_POST_INCR; 
			struct noeud* entree = get_symbole(tds, $1); 
			if(entree == NULL) {
				char err_msg[MAX_LENGTH_VAR_NAME + 20];
				sprintf(err_msg, "Undeclared name : '%s'", $1);
				yyerror(err_msg);
				entree = insertion(&tds, $1, SORTE_NONE, TYPE_ERROR);
			}
			gencode(liste_quad, $2, entree, NULL, entree);
			$$.ptr = entree;
		}
	| IDENT DECR {
			$2 = QOP_POST_DECR;
	     	struct noeud* entree = get_symbole(tds, $1); 
			if(entree == NULL) {
				char err_msg[MAX_LENGTH_VAR_NAME + 20];
				sprintf(err_msg, "Undeclared name : '%s'", $1);
				yyerror(err_msg);
				entree = insertion(&tds, $1, SORTE_NONE, TYPE_ERROR);
			}
			gencode(liste_quad, $2, entree, NULL, entree);
			$$.ptr = entree; 
		}
	| INCR IDENT {
			$1 = QOP_PRE_INCR;
	     	struct noeud* entree = get_symbole(tds, $2); 
			if(entree == NULL) {
				char err_msg[MAX_LENGTH_VAR_NAME + 20];
				sprintf(err_msg, "Undeclared name : '%s'", $2);
				yyerror(err_msg);
				entree = insertion(&tds, $2, SORTE_NONE, TYPE_ERROR);
			}
			gencode(liste_quad, $1, entree, NULL, entree);
			$$.ptr = entree;
		}
	| DECR IDENT {
			$1 = QOP_PRE_DECR;
	     	struct noeud* entree = get_symbole(tds, $2); 
			if(entree == NULL) {
				char err_msg[MAX_LENGTH_VAR_NAME + 20];
				sprintf(err_msg, "Undeclared name : '%s'", $2);
				yyerror(err_msg);
				entree = insertion(&tds, $2, SORTE_NONE, TYPE_ERROR);
			}
			gencode(liste_quad, $1, entree, NULL, entree);
			$$.ptr = entree;
		}
;

constante_entiere : C_INT {
			struct noeud* entree = insertion_constante(&tds, TYPE_INT, $1);
			$$ = $1;
		} 
;

constante_flottante : C_FLOAT {
			struct noeud* entree = insertion_constante(&tds, TYPE_FLOAT, $1);
			$$ = $1;
		} 
;

assign : '=' {$$ = QOP_ASSIGN;}
	| PLUS_ASSIGN {$$ = QOP_PLUS_ASSIGN;}
	| MINUS_ASSIGN {$$ = QOP_MINUS_ASSIGN;}
	| MULT_ASSIGN {$$ = QOP_MULT_ASSIGN;}
	| DIV_ASSIGN {$$ = QOP_DIV_ASSIGN;}
	| MOD_ASSIGN {$$ = QOP_MOD_ASSIGN;}
	| AND_ASSIGN {$$ = QOP_AND_ASSIGN;}
	| XOR_ASSIGN {$$ = QOP_XOR_ASSIGN;}
	| OR_ASSIGN {$$ = QOP_OR_ASSIGN;}
;


            
%%  

void yyerror(const char* msg)
{
    syntaxe_error = 1;
	fprintf(stderr, "Syntaxe error : %s\n", msg);
}
