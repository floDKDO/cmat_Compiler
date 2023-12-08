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
        /*struct u_tab {
                enum u_type type_tab;
                int nDim;
        } tableau;*/
        
        enum QuadOp op;
        
        char nom[64];
        
        float constante;
        
        struct {
		struct noeud* ptr;
	    } exprval;
	    
	 char tab_str[64][64]; //limite arbitraire : 64 chaînes de 64 caractères max
	 
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
%token <constante> C_INT C_FLOAT
%type <constante> constante
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


declaration_variable : type liste_variable_declaree {for(int i = 0; i < indice_tab_str; i++) //mettre le type dans la tds
							{
								struct noeud* noeud = get_symbole(tds, $2[i]);
								if(noeud != NULL)
									noeud->info.type = $1;
							}
}
;

liste_variable_declaree : liste_variable_declaree ',' variable_declaree {strcpy($$[indice_tab_str], $3); indice_tab_str += 1;}
			| variable_declaree {strcpy($$[indice_tab_str], $1); indice_tab_str += 1;}
;

variable_declaree : IDENT {struct noeud* entree = insertion(&tds, $1, SORTE_VARIABLE, TYPE_NONE); /*strcpy($$, $1);*/}
                  | IDENT '=' expression {struct noeud* entree = insertion(&tds, $1, SORTE_VARIABLE, TYPE_NONE);
                  				
                  			if(entree == NULL) 
                  			{
                  				fprintf(stderr,"Previous declaration of %s exists\n", $1); 
                  				exit(1);
                  			}
                  			
                
                  			
                  			if($3.ptr->info.sorte == SORTE_CONSTANTE)
						gencode(liste_quad, QOP_ASSIGN, $3.ptr, NULL, entree);
					else gencode(liste_quad, QOP_ASSIGN, $3.ptr, NULL, entree);
					
					//strcpy($$, $1);
						}
                  | IDENT intervalle_dimension {}
                  | IDENT intervalle_dimension '=' valeur_tableau {}
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

expression : valeur {		struct noeud* entree;
				if($1.ptr->info.sorte == SORTE_CONSTANTE)
					entree = get_symbole_constante(tds, $1.ptr->info.constante.valeur); 
				else entree = get_symbole(tds, $1.ptr->info.nom); 
			    	if(entree == NULL) 
				{
					fprintf(stderr,"Name '%s' undeclared\n",$1.ptr->info.nom);
					exit(1);
				}
				$$.ptr = entree;
		}
            | expression '+' expression {
	    					if(recherche(tds, $1.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $1.ptr->info.nom);
							exit(1);
	    					}
	    					else if(recherche(tds, $3.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $3.ptr->info.nom);
							exit(1);
	    					}

		    				  if(get_type(tds, $1.ptr->info.nom) == TYPE_INT && get_type(tds, $3.ptr->info.nom) == TYPE_INT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_INT);
						  }
						  else if(get_type(tds, $1.ptr->info.nom) == TYPE_FLOAT && get_type(tds, $3.ptr->info.nom) == TYPE_FLOAT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_FLOAT);
						  }
						  else
						  {
						 	$$.ptr = newtemp(&tds, TYPE_NONE);
						  }

						  
						  gencode(liste_quad, QOP_PLUS, $1.ptr, $3.ptr, $$.ptr);
					  }
            | expression '-' expression {          
           					 if(recherche(tds, $1.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $1.ptr->info.nom);
							exit(1);
	    					}
	    					else if(recherche(tds, $3.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $3.ptr->info.nom);
							exit(1);
	    					}

		    				  if(get_type(tds, $1.ptr->info.nom) == TYPE_INT && get_type(tds, $3.ptr->info.nom) == TYPE_INT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_INT);
						  }
						  else if(get_type(tds, $1.ptr->info.nom) == TYPE_FLOAT && get_type(tds, $3.ptr->info.nom) == TYPE_FLOAT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_FLOAT);
						  }
						  else
						  {
						 	$$.ptr = newtemp(&tds, TYPE_NONE);
						  }
						  gencode(liste_quad, QOP_MINUS, $1.ptr, $3.ptr, $$.ptr);
}
            | expression '*' expression {
            
            					if(recherche(tds, $1.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $1.ptr->info.nom);
							exit(1);
	    					}
	    					else if(recherche(tds, $3.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $3.ptr->info.nom);
							exit(1);
	    					}

		    				  if(get_type(tds, $1.ptr->info.nom) == TYPE_INT && get_type(tds, $3.ptr->info.nom) == TYPE_INT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_INT);
						  }
						  else if(get_type(tds, $1.ptr->info.nom) == TYPE_FLOAT && get_type(tds, $3.ptr->info.nom) == TYPE_FLOAT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_FLOAT);
						  }
						  else
						  {
						 	$$.ptr = newtemp(&tds, TYPE_NONE);
						  }
						  gencode(liste_quad, QOP_MULT, $1.ptr, $3.ptr, $$.ptr);
}
            | expression '/' expression {
            
            					if(recherche(tds, $1.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $1.ptr->info.nom);
							exit(1);
	    					}
	    					else if(recherche(tds, $3.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $3.ptr->info.nom);
							exit(1);
	    					}

		    				  if(get_type(tds, $1.ptr->info.nom) == TYPE_INT && get_type(tds, $3.ptr->info.nom) == TYPE_INT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_INT);
						  }
						  else if(get_type(tds, $1.ptr->info.nom) == TYPE_FLOAT && get_type(tds, $3.ptr->info.nom) == TYPE_FLOAT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_FLOAT);
						  }
						  else
						  {
						 	$$.ptr = newtemp(&tds, TYPE_NONE);
						  }
						  gencode(liste_quad, QOP_DIV, $1.ptr, $3.ptr, $$.ptr);
}
            | expression '%' expression {
				    
				    		if(recherche(tds, $1.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $1.ptr->info.nom);
							exit(1);
	    					}
	    					else if(recherche(tds, $3.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $3.ptr->info.nom);
							exit(1);
	    					}

		    				  if(get_type(tds, $1.ptr->info.nom) == TYPE_INT && get_type(tds, $3.ptr->info.nom) == TYPE_INT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_INT);
						  }
						  else if(get_type(tds, $1.ptr->info.nom) == TYPE_FLOAT && get_type(tds, $3.ptr->info.nom) == TYPE_FLOAT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_FLOAT);
						  }
						  else
						  {
						 	$$.ptr = newtemp(&tds, TYPE_NONE);
						  }
						  gencode(liste_quad, QOP_MOD, $1.ptr, $3.ptr, $$.ptr);
}
            | expression '^' expression {
            
            					if(recherche(tds, $1.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $1.ptr->info.nom);
							exit(1);
	    					}
	    					else if(recherche(tds, $3.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $3.ptr->info.nom);
							exit(1);
	    					}

		    				  if(get_type(tds, $1.ptr->info.nom) == TYPE_INT && get_type(tds, $3.ptr->info.nom) == TYPE_INT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_INT);
						  }
						  else if(get_type(tds, $1.ptr->info.nom) == TYPE_FLOAT && get_type(tds, $3.ptr->info.nom) == TYPE_FLOAT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_FLOAT);
						  }
						  else
						  {
						 	$$.ptr = newtemp(&tds, TYPE_NONE);
						  }
						  gencode(liste_quad, QOP_XOR, $1.ptr, $3.ptr, $$.ptr);
}
            | expression '&' expression {
            
    						if(recherche(tds, $1.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $1.ptr->info.nom);
							exit(1);
	    					}
	    					else if(recherche(tds, $3.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $3.ptr->info.nom);
							exit(1);
	    					}

		    				  if(get_type(tds, $1.ptr->info.nom) == TYPE_INT && get_type(tds, $3.ptr->info.nom) == TYPE_INT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_INT);
						  }
						  else if(get_type(tds, $1.ptr->info.nom) == TYPE_FLOAT && get_type(tds, $3.ptr->info.nom) == TYPE_FLOAT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_FLOAT);
						  }
						  else
						  {
						 	$$.ptr = newtemp(&tds, TYPE_NONE);
						  }
						  gencode(liste_quad, QOP_AND, $1.ptr, $3.ptr, $$.ptr);
}
            | expression '|' expression {
            
    						if(recherche(tds, $1.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $1.ptr->info.nom);
							exit(1);
	    					}
	    					else if(recherche(tds, $3.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $3.ptr->info.nom);
							exit(1);
	    					}

		    				  if(get_type(tds, $1.ptr->info.nom) == TYPE_INT && get_type(tds, $3.ptr->info.nom) == TYPE_INT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_INT);
						  }
						  else if(get_type(tds, $1.ptr->info.nom) == TYPE_FLOAT && get_type(tds, $3.ptr->info.nom) == TYPE_FLOAT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_FLOAT);
						  }
						  else
						  {
						 	$$.ptr = newtemp(&tds, TYPE_NONE);
						  }
						  gencode(liste_quad, QOP_OR, $1.ptr, $3.ptr, $$.ptr);
}
            | expression '>' expression {
            
    						if(recherche(tds, $1.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $1.ptr->info.nom);
							exit(1);
	    					}
	    					else if(recherche(tds, $3.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $3.ptr->info.nom);
							exit(1);
	    					}

		    				  if(get_type(tds, $1.ptr->info.nom) == TYPE_INT && get_type(tds, $3.ptr->info.nom) == TYPE_INT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_INT);
						  }
						  else if(get_type(tds, $1.ptr->info.nom) == TYPE_FLOAT && get_type(tds, $3.ptr->info.nom) == TYPE_FLOAT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_FLOAT);
						  }
						  else
						  {
						 	$$.ptr = newtemp(&tds, TYPE_NONE);
						  }
						  gencode(liste_quad, QOP_GT, $1.ptr, $3.ptr, $$.ptr);
}
            | expression '<' expression {
    						if(recherche(tds, $1.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $1.ptr->info.nom);
							exit(1);
	    					}
	    					else if(recherche(tds, $3.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $3.ptr->info.nom);
							exit(1);
	    					}

		    				  if(get_type(tds, $1.ptr->info.nom) == TYPE_INT && get_type(tds, $3.ptr->info.nom) == TYPE_INT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_INT);
						  }
						  else if(get_type(tds, $1.ptr->info.nom) == TYPE_FLOAT && get_type(tds, $3.ptr->info.nom) == TYPE_FLOAT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_FLOAT);
						  }
						  else
						  {
						 	$$.ptr = newtemp(&tds, TYPE_NONE);
						  }
						  gencode(liste_quad, QOP_LT, $1.ptr, $3.ptr, $$.ptr);
}
            | expression LE expression {
            
    						if(recherche(tds, $1.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $1.ptr->info.nom);
							exit(1);
	    					}
	    					else if(recherche(tds, $3.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $3.ptr->info.nom);
							exit(1);
	    					}

		    				  if(get_type(tds, $1.ptr->info.nom) == TYPE_INT && get_type(tds, $3.ptr->info.nom) == TYPE_INT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_INT);
						  }
						  else if(get_type(tds, $1.ptr->info.nom) == TYPE_FLOAT && get_type(tds, $3.ptr->info.nom) == TYPE_FLOAT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_FLOAT);
						  }
						  else
						  {
						 	$$.ptr = newtemp(&tds, TYPE_NONE);
						  }
						  gencode(liste_quad, QOP_LE, $1.ptr, $3.ptr, $$.ptr);
}
            | expression GE expression {
            
    						if(recherche(tds, $1.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $1.ptr->info.nom);
							exit(1);
	    					}
	    					else if(recherche(tds, $3.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $3.ptr->info.nom);
							exit(1);
	    					}

		    				  if(get_type(tds, $1.ptr->info.nom) == TYPE_INT && get_type(tds, $3.ptr->info.nom) == TYPE_INT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_INT);
						  }
						  else if(get_type(tds, $1.ptr->info.nom) == TYPE_FLOAT && get_type(tds, $3.ptr->info.nom) == TYPE_FLOAT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_FLOAT);
						  }
						  else
						  {
						 	$$.ptr = newtemp(&tds, TYPE_NONE);
						  }
						  gencode(liste_quad, QOP_GE, $1.ptr, $3.ptr, $$.ptr);
}
            | expression EQ expression {
            
    						if(recherche(tds, $1.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $1.ptr->info.nom);
							exit(1);
	    					}
	    					else if(recherche(tds, $3.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $3.ptr->info.nom);
							exit(1);
	    					}

		    				  if(get_type(tds, $1.ptr->info.nom) == TYPE_INT && get_type(tds, $3.ptr->info.nom) == TYPE_INT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_INT);
						  }
						  else if(get_type(tds, $1.ptr->info.nom) == TYPE_FLOAT && get_type(tds, $3.ptr->info.nom) == TYPE_FLOAT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_FLOAT);
						  }
						  else
						  {
						 	$$.ptr = newtemp(&tds, TYPE_NONE);
						  }
						  gencode(liste_quad, QOP_EQ, $1.ptr, $3.ptr, $$.ptr);
}
            | expression NE expression {
            
    						if(recherche(tds, $1.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $1.ptr->info.nom);
							exit(1);
	    					}
	    					else if(recherche(tds, $3.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $3.ptr->info.nom);
							exit(1);
	    					}

		    				  if(get_type(tds, $1.ptr->info.nom) == TYPE_INT && get_type(tds, $3.ptr->info.nom) == TYPE_INT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_INT);
						  }
						  else if(get_type(tds, $1.ptr->info.nom) == TYPE_FLOAT && get_type(tds, $3.ptr->info.nom) == TYPE_FLOAT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_FLOAT);
						  }
						  else
						  {
						 	$$.ptr = newtemp(&tds, TYPE_NONE);
						  }
						  gencode(liste_quad, QOP_NE, $1.ptr, $3.ptr, $$.ptr);
}
            | expression LOGICAL_AND expression {
            
            					if(recherche(tds, $1.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $1.ptr->info.nom);
							exit(1);
	    					}
	    					else if(recherche(tds, $3.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $3.ptr->info.nom);
							exit(1);
	    					}

		    				  if(get_type(tds, $1.ptr->info.nom) == TYPE_INT && get_type(tds, $3.ptr->info.nom) == TYPE_INT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_INT);
						  }
						  else if(get_type(tds, $1.ptr->info.nom) == TYPE_FLOAT && get_type(tds, $3.ptr->info.nom) == TYPE_FLOAT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_FLOAT);
						  }
						  else
						  {
						 	$$.ptr = newtemp(&tds, TYPE_NONE);
						  }
						  gencode(liste_quad, QOP_LOGICAL_AND, $1.ptr, $3.ptr, $$.ptr);
}
            | expression LOGICAL_OR expression {
            
    						if(recherche(tds, $1.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $1.ptr->info.nom);
							exit(1);
	    					}
	    					else if(recherche(tds, $3.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $3.ptr->info.nom);
							exit(1);
	    					}

		    				  if(get_type(tds, $1.ptr->info.nom) == TYPE_INT && get_type(tds, $3.ptr->info.nom) == TYPE_INT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_INT);
						  }
						  else if(get_type(tds, $1.ptr->info.nom) == TYPE_FLOAT && get_type(tds, $3.ptr->info.nom) == TYPE_FLOAT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_FLOAT);
						  }
						  else
						  {
						 	$$.ptr = newtemp(&tds, TYPE_NONE);
						  }
						  gencode(liste_quad, QOP_LOGICAL_OR, $1.ptr, $3.ptr, $$.ptr);
}
            | '-' expression %prec UNARY {
            
            					if(recherche(tds, $2.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $2.ptr->info.nom);
							exit(1);
	    					}
		    					

		    				  if(get_type(tds, $2.ptr->info.nom) == TYPE_INT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_INT);
						  }
						  else if(get_type(tds, $2.ptr->info.nom) == TYPE_FLOAT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_FLOAT);
						  }
						  else
						  {
						 	$$.ptr = newtemp(&tds, TYPE_NONE);
						  }
						  gencode(liste_quad, QOP_UNARY_MINUS, $2.ptr, NULL, $$.ptr);
}
            | '+' expression %prec UNARY {
            
            					if(recherche(tds, $2.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $2.ptr->info.nom);
							exit(1);
	    					}
		    					

		    				  if(get_type(tds, $2.ptr->info.nom) == TYPE_INT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_INT);
						  }
						  else if(get_type(tds, $2.ptr->info.nom) == TYPE_FLOAT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_FLOAT);
						  }
						  else
						  {
						 	$$.ptr = newtemp(&tds, TYPE_NONE);
						  }
						  gencode(liste_quad, QOP_UNARY_PLUS, $2.ptr, NULL, $$.ptr);
}
            | '!' expression %prec UNARY {
            					if(recherche(tds, $2.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $2.ptr->info.nom);
							exit(1);
	    					}
		    					

		    				  if(get_type(tds, $2.ptr->info.nom) == TYPE_INT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_INT);
						  }
						  else if(get_type(tds, $2.ptr->info.nom) == TYPE_FLOAT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_FLOAT);
						  }
						  else
						  {
						 	$$.ptr = newtemp(&tds, TYPE_NONE);
						  }
						  gencode(liste_quad, QOP_NOT, $2.ptr, NULL, $$.ptr);
}
            | '~' expression %prec UNARY {
            
            					if(recherche(tds, $2.ptr->info.nom) == false)
	    					{
	    						fprintf(stderr,"Name '%s' undeclared\n", $2.ptr->info.nom);
							exit(1);
	    					}
		    					

		    				  if(get_type(tds, $2.ptr->info.nom) == TYPE_INT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_INT);
						  }
						  else if(get_type(tds, $2.ptr->info.nom) == TYPE_FLOAT)
						  {
						 	 $$.ptr = newtemp(&tds, TYPE_FLOAT);
						  }
						  else
						  {
						 	$$.ptr = newtemp(&tds, TYPE_NONE);
						  }
						  gencode(liste_quad, QOP_NEG, $2.ptr, NULL, $$.ptr);
}
            /*| '*' expression %prec UNARY    //On fait les pointeurs ?
            | '&' expression %prec UNARY*/
            | '(' expression ')' {$$ = $2;}
;

       
intervalle_dimension : intervalle_dimension '[' liste_rangee ']' { //$$.nDim = $1.nDim + 1;
                        }
                        | '[' liste_rangee ']' {/*$$.type_tab = $2.type_tab; $$.nDim = 1;*/}
;

liste_rangee : liste_rangee ';' rangee { //$$.nDim = $1.nDim + 1;
                }
                | rangee {/*$$ = $1; $$.nDim = 1;*/}
;

rangee : '*' {/*$$.type_tab = MATRIX_TYPE; Matrix exclusivement*/} 
        | expression INTERV_OP expression {}
        | expression {}
;

valeur_tableau : '{' liste_nombre '}' {/*$$ = $2; $$.nDim = 1;*/}
		| '{' liste_tableau '}' {/*$$ = $2; $$.nDim = $2.nDim + 1;*/}
;
		
liste_tableau : liste_tableau ',' valeur_tableau {//$$.nDim = ($1.nDim >= $3.nDim ? $1.nDim : $3.nDim);
}
		| valeur_tableau {/*$$ = $1;*/}
;

liste_nombre : liste_entiers {/*$$.type_tab = INT_TYPE;*/} | liste_flottants {/*$$.type_tab = FLOAT_TYPE;*/}
;

liste_flottants : liste_flottants ',' C_FLOAT | C_FLOAT
;

liste_entiers : liste_entiers ',' C_INT | C_INT 
;

type : INT {$$ = TYPE_INT;} | FLOAT {$$ = TYPE_FLOAT;} | MATRIX {/*$$ = MATRIX_TYPE;*/}
;

valeur : IDENT {	struct noeud* entree = get_symbole(tds, $1); 
		    	if(entree == NULL) 
			{
				entree = insertion(&tds, $1, SORTE_VARIABLE, TYPE_NONE);
			}
			$$.ptr = entree;
}	| constante {
        		struct noeud* entree = get_symbole_constante(tds, $1);
        		if(entree == NULL) 
			{
				entree = insertion_constante(&tds, TYPE_NONE, $1);
			}
		        $$.ptr = entree;}
        | IDENT intervalle_dimension {} 
        | incr_et_decr {struct noeud* entree = get_symbole(tds, $1.ptr->info.nom); 
		    	if(entree == NULL) 
			{
				entree = insertion(&tds, $1.ptr->info.nom, SORTE_VARIABLE, TYPE_NONE);
			}
			$$.ptr = entree;}
        | appel_fonction {} 
;

incr_et_decr : IDENT INCR {	$2 = QOP_POST_INCR; 
			    	struct noeud* entree = get_symbole(tds, $1); 
			    	if(entree == NULL) 
				{
					fprintf(stderr,"Name '%s' undeclared\n",$1);
					exit(1);
				}
				gencode(liste_quad, $2, entree, NULL, entree);
				$$.ptr = entree;
			    }
	     | IDENT DECR {	$2 = QOP_POST_DECR;
	     			struct noeud* entree = get_symbole(tds, $1); 
			    	if(entree == NULL) 
				{
					fprintf(stderr,"Name '%s' undeclared\n",$1);
					exit(1);
				}
				gencode(liste_quad, $2, entree, NULL, entree);
				$$.ptr = entree; 
			}
	     | INCR IDENT {    $1 = QOP_PRE_INCR;
	     			struct noeud* entree = get_symbole(tds, $2); 
			    	if(entree == NULL) 
				{
					fprintf(stderr,"Name '%s' undeclared\n",$2);
					exit(1);
				}
				gencode(liste_quad, $1, entree, NULL, entree);
				$$.ptr = entree; }
	     | DECR IDENT {    $1 = QOP_PRE_DECR;
	     			struct noeud* entree = get_symbole(tds, $2); 
			    	if(entree == NULL) 
				{
					fprintf(stderr,"Name '%s' undeclared\n",$2);
					exit(1);
				}
				gencode(liste_quad, $1, entree, NULL, entree);
				$$.ptr = entree;  }
;

constante : C_INT {struct noeud* entree = insertion_constante(&tds, TYPE_INT, $1);
                   $$ = $1;} 
	  | C_FLOAT {struct noeud* entree = insertion_constante(&tds, TYPE_FLOAT, $1);
		   $$ = $1;} 
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
