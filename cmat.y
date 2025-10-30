%{

#include <stdbool.h>

extern int yylex();
void yyerror(const char* msg);

int syntax_error = 0;

int indice = 0; //pour liste_entiers et liste_flottants
int last_index = 0; //derniere valeur de indice

int indice_tab_str = 0;

bool execute_action_incr_et_decr = true; //empêcher que le incr et decr soit exécuté trop tôt dans la boucle for
int action_incr_et_decr = 0; //0 ou 1 ou 2 ou 3 selon l'action de incr et decr pour la boucle for

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
		int tailleDim;
		int taillesDim[MAX_DIMENSION_TABLEAU];
		int listeValeursEntieres[1024];
		float listeValeursFlottantes[1024];
	} tableau;
	
	enum QuadOp op;
	
	char nom[MAX_LENGTH_VAR_NAME];
	
	float constante_flottante;
	int constante_entiere;
	char constante_caractere[MAX_LONGUEUR_VARIABLE];
	
	
	
	struct {
		int indice_demande[2]; //si tableau : [0] pour tab 1D et [0][1] pour tab 2d
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
%token <constante_caractere> C_STR
%type <constante_caractere> constante_caractere

%token <nom> IDENT
%type <nom> variable_declaree
%token <op> INCR DECR
%type <tableau> intervalle_dimension liste_tableau liste_nombre rangee liste_rangee liste_entiers liste_flottants valeur_tableau
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

%type <exprval> expression incr_et_decr valeur appel_fonction operation iterateur_boucle_for
%type <type> type;

%start programme

%% 

//Créer une liste de declaration_fonction si on ajoute les fonction en dehors du main
programme : main {return syntax_error;}
;

main : INT MAIN '(' ')' corps
;

corps : '{' liste_instruction '}' | '{' '}'
;

liste_instruction : liste_instruction instruction 
		   | instruction
;

instruction : declaration_variable ';' 
	    | declaration_fonction {}
	    | liste_operation ';'
        | condition
        | boucle
	    | RETURN C_INT ';'
;

partie_else : ELSE{gencode(liste_quad, QOP_ELSE_IF, NULL, NULL, NULL);} corps
	| ELSE{gencode(liste_quad, QOP_ELSE_IF, NULL, NULL, NULL);} condition
	| %empty {gencode(liste_quad, QOP_ELSE_IF, NULL, NULL, NULL);}
	;


condition : IF '(' expression {struct noeud* entree = get_symbole(tds, $3.ptr->info.nom); gencode(liste_quad, QOP_IF, NULL, NULL, entree);} ')' corps{gencode(liste_quad, QOP_HALF_IF, NULL, NULL, NULL);} partie_else{gencode(liste_quad, QOP_END_IF, NULL, NULL, NULL);}
;

boucle : boucle_for | boucle_while
;

iterateur_boucle_for: type IDENT {struct noeud* entree = insertion(&tds, $2, SORTE_VARIABLE, $1); $$.ptr = entree;}
		    | IDENT {struct noeud* entree = get_symbole(tds, $1); $$.ptr = entree;}
;

boucle_for : FOR '(' iterateur_boucle_for
'=' expression {struct noeud* entree = get_symbole(tds, $5.ptr->info.nom); gencode(liste_quad, QOP_FOR, entree, NULL, $<exprval>3.ptr);}
';' expression {gencode(liste_quad, QOP_HALF_FOR, NULL, NULL, $8.ptr);} ';' {execute_action_incr_et_decr = false;} incr_et_decr {execute_action_incr_et_decr = true;} 
')' corps{
	//il faut effectuer l'incrémentation/décrémentation maintenant
	if(action_incr_et_decr == 0) 
	{
		gencode(liste_quad, QOP_POST_INCR, $12.ptr, NULL, $12.ptr);
	}
	else if(action_incr_et_decr == 1) 
	{
		gencode(liste_quad, QOP_POST_DECR, $12.ptr, NULL, $12.ptr);
	}
	else if(action_incr_et_decr == 2) 
	{
		gencode(liste_quad, QOP_PRE_INCR, $12.ptr, NULL, $12.ptr);
	}
	else if(action_incr_et_decr == 3) 
	{
		gencode(liste_quad, QOP_PRE_DECR, $12.ptr, NULL, $12.ptr);
	}
	gencode(liste_quad, QOP_END_FOR, NULL, NULL, NULL);
}
;

boucle_while : WHILE '(' {gencode(liste_quad, QOP_WHILE, NULL, NULL, NULL);} expression {
			struct noeud* entree = get_symbole(tds, $4.ptr->info.nom); 
			if(entree == NULL) 
			{
				char err_msg[MAX_LENGTH_VAR_NAME + 20];
				sprintf(err_msg, "Undeclared name : '%s'", $4.ptr->info.nom);
				yyerror(err_msg);
				entree = insertion(&tds, $4.ptr->info.nom, SORTE_NONE, TYPE_ERROR);
			}
               }
 ')' {gencode(liste_quad, QOP_HALF_WHILE, NULL, NULL, $4.ptr);} corps{gencode(liste_quad, QOP_END_WHILE, NULL, NULL, NULL);}
;


declaration_variable : type liste_variable_declaree 
	{
		for(int i = 0; i < indice_tab_str; i++) 
		{ 	//mettre le type dans la tds
			struct noeud* noeud = get_symbole(tds, $2[i]);
			if(noeud != NULL)
			{
				if($1 == TYPE_MATRIX)
				{
					noeud->info.tableau.is_matrix = true;
					if(noeud->info.type == TYPE_INT) //éléments de types int dans la matrice => on doit cast en float
					{	
						if(noeud->info.tableau.nombre_dimension == 1)
						{
							for(int i = 0; i < noeud->info.tableau.taille_dimensions[0]; ++i) 
							{
							    noeud->info.tableau.valeurs_flottantes_tableau[i] = (float)noeud->info.tableau.valeurs_entieres_tableau[i];
							    noeud->info.tableau.valeurs_entieres_tableau[i] = 0;
							}
						}
						else if(noeud->info.tableau.nombre_dimension == 2)
						{
							for(int i = 0; i < noeud->info.tableau.taille_dimensions[0]*noeud->info.tableau.taille_dimensions[1]; ++i) 
							{
							    noeud->info.tableau.valeurs_flottantes_tableau[i] = (float)noeud->info.tableau.valeurs_entieres_tableau[i];
							    noeud->info.tableau.valeurs_entieres_tableau[i] = 0;
							}
						}
						noeud->info.type = TYPE_FLOAT;
					}
					else if(noeud->info.type == TYPE_NONE) 
						noeud->info.type = TYPE_FLOAT;
					
					if(noeud->info.tableau.nombre_dimension == 1)
					{
						//on considère que matrix tab[2] <=> matrix tab[1][2]
						noeud->info.tableau.nombre_dimension = 2;
						noeud->info.tableau.taille_dimensions[1] = noeud->info.tableau.taille_dimensions[0];
						noeud->info.tableau.taille_dimensions[0] = 1;
					}	
						
				}
				else 
				{
					noeud->info.type = $1;
				}
			}
		}
	}
;

liste_variable_declaree : liste_variable_declaree ',' variable_declaree {
				strcpy($$[indice_tab_str], $3); 
				indice_tab_str += 1; 
				indice = 0; //reset indice de liste_entiers et liste_flottants
				last_index = indice; //reset
			}
			| variable_declaree {
				strcpy($$[indice_tab_str], $1); 
				indice_tab_str += 1; 
				indice = 0; //reset indice de liste_entiers et liste_flottants
				last_index = indice; //reset
			}
;

variable_declaree : 
	IDENT {struct noeud* entree = insertion(&tds, $1, SORTE_VARIABLE, TYPE_NONE);
	
		if(entree == NULL) 
		{
			fprintf(stderr,"Previous declaration of %s exists\n", $1); 
			exit(1);
		}
	}
	| IDENT assign expression {
    
		struct noeud* entree = insertion(&tds, $1, SORTE_VARIABLE, TYPE_NONE);
		
		if(entree == NULL) 
		{
			fprintf(stderr,"Previous declaration of %s exists\n", $1); 
			exit(1);
		}
		
        	if($3.ptr->info.sorte == SORTE_TABLEAU)
        	{	
        		struct noeud* indice;
        		if($3.ptr->info.tableau.nombre_dimension == 1)
        		{
				indice = get_symbole_constante_int(tds, $3.indice_demande[0]);
			}
			else if($3.ptr->info.tableau.nombre_dimension == 2)
        		{
        			//tableau 2D => récupérer la bonne case
        			int indice_dim_un = $3.indice_demande[0];
        			int indice_dim_deux = $3.indice_demande[1];
        			
        			//pour obtenir le bon indice (valeurs rangées en ROW ORDER)
        			int vrai_indice = indice_dim_un * $3.ptr->info.tableau.taille_dimensions[1] + indice_dim_deux;
        			indice = insertion_constante(&tds, TYPE_INT, vrai_indice); //on ajoute le vrai indice à la table des symboles
        		}
        		
        		gencode(liste_quad, $2, $3.ptr, indice, entree); //la case de tableau demandée se trouve dans la valeur_entiere de indice
        	}
        	else
        	{
			gencode(liste_quad, $2, $3.ptr, NULL, entree);
		}
	}
    | IDENT intervalle_dimension {
    		struct noeud* entree = insertion_tableau(&tds, $1, TYPE_NONE, $2.nDim, $2.taillesDim); 
    		if(entree == NULL) 
    		{
                	fprintf(stderr,"Previous declaration of %s exists\n", $1); 
                	exit(1);
            	}
           }
    | IDENT intervalle_dimension '=' valeur_tableau {
    
    		struct noeud* entree = insertion_tableau(&tds, $1, $4.type_tab, $2.nDim, $2.taillesDim); 
    
    		if(entree == NULL) 
    		{
               	fprintf(stderr,"Previous declaration of %s exists\n", $1); 
                	exit(1);
		}
		
		entree->info.tableau.is_matrix = false; //si c'est vraiment une matrix, cela renseigné au moment du parsage du type
		
		if(entree->info.type == TYPE_INT)
		{
			if($2.nDim == 1)
			{
				for(int i = 0; i < $2.taillesDim[0]; i++)
				{
					entree->info.tableau.valeurs_entieres_tableau[i] = $4.listeValeursEntieres[i];
				}
			}
			else if($2.nDim == 2)
			{
				int next_index = 0;
				for(int j = 0; j < $2.taillesDim[0]; j++) //Exemple : int tab[4][2] => j 0->3
				{
				    for(int i = next_index; i < $2.taillesDim[1] + next_index; i++) //Exemple : int tab[4][2] => i 0->1, 2->3, 4->5, 6->7. Cela permet de récupérer les valeurs des 4 groupes de 2 valeurs et de les placer au bon endroit
				    {
				    	entree->info.tableau.valeurs_entieres_tableau[i] = $4.listeValeursEntieres[i];
				    }
				    next_index += $2.taillesDim[1]; //Valeurs du tableau 2D placées au bon indice dans le tableau 1D.
				}
			}
		}
		else if(entree->info.type == TYPE_FLOAT)
		{
			if($2.nDim == 1)
			{
				for(int i = 0; i < $2.taillesDim[0]; i++)
				{
					entree->info.tableau.valeurs_flottantes_tableau[i] = $4.listeValeursFlottantes[i];
				}
			}
			else if($2.nDim == 2)
			{
				int next_index = 0;
				for(int j = 0; j < $2.taillesDim[0]; j++) //idem TYPE_INT
				{
				    for(int i = next_index; i < $2.taillesDim[1] + next_index; i++) //idem TYPE_INT
				    {
				    	entree->info.tableau.valeurs_flottantes_tableau[i] = $4.listeValeursFlottantes[i];
				    }
				    next_index += $2.taillesDim[1];
				}
			}
		}
            	gencode(liste_quad, QOP_ASSIGN_TAB, NULL, NULL, entree);
}
;


liste_operation : 
	liste_operation ',' operation
	| operation
;

operation : expression {$$.ptr = $1.ptr;}
	| IDENT assign operation {struct noeud* entree = get_symbole(tds, $1);
				  gencode(liste_quad, $2, $3.ptr, NULL, entree);
				  $$.ptr = entree;} 
	| IDENT intervalle_dimension assign operation {}
;

declaration_fonction : 
	type IDENT '(' liste_parametre ')' corps {}
    | type IDENT '(' ')' corps {}
;
		 
appel_fonction : 
	IDENT '(' liste_argument ')' {fprintf(stderr, "Fonctions non gérées!\n"); exit(1);}
        | IDENT '(' ')' {fprintf(stderr, "Fonctions non gérées!\n"); exit(1);}
	| PRINTF '(' constante_caractere ')' {
				struct noeud* entree = get_symbole_constante_str(tds, $3);
				gencode(liste_quad, QOP_PRINTF, NULL, NULL, entree);
				$$.ptr = entree;}
	| PRINT '(' constante_entiere ')' {
				struct noeud* entree = get_symbole_constante_int(tds, $3);
				gencode(liste_quad, QOP_PRINT, NULL, NULL, entree);
				$$.ptr = entree;}
	| PRINT '(' constante_flottante ')' {
				struct noeud* entree = get_symbole_constante(tds, $3);
				gencode(liste_quad, QOP_PRINT, NULL, NULL, entree);
				$$.ptr = entree;}
        | PRINT '(' IDENT ')' {
        			struct noeud* entree = get_symbole(tds, $3);
				gencode(liste_quad, QOP_PRINT, NULL, NULL, entree);
				$$.ptr = entree;
				}
	| PRINT '(' IDENT '[' expression ']' ')' {
		struct noeud* entree = get_symbole(tds, $3);
		struct noeud* indice = $5.ptr;

		if(entree->info.sorte == SORTE_TABLEAU)
        	{		
        		if(entree->info.tableau.nombre_dimension == 1)
        		{
				gencode(liste_quad, QOP_PRINT, indice, NULL, entree);
        			$$.ptr = entree;
			}
        	}
	}
	| PRINT '(' IDENT '[' expression ']' '[' expression ']' ')' {
		struct noeud* entree = get_symbole(tds, $3);
		struct noeud* indice1 = $5.ptr;
		struct noeud* indice2 = $8.ptr;

		if(entree->info.sorte == SORTE_TABLEAU)
        	{		
        		if(entree->info.tableau.nombre_dimension == 2)
        		{
				gencode(liste_quad, QOP_PRINT, indice1, indice2, entree);
        			$$.ptr = entree;
			}
        	}
	}
	| PRINTMAT '(' IDENT ')' {
	struct noeud* entree = get_symbole(tds, $3);
	gencode(liste_quad, QOP_PRINTMAT, NULL, NULL, entree);
	$$.ptr = entree;
}
;
            
liste_parametre : liste_parametre ',' parametre | parametre
;

liste_argument : liste_argument ',' argument | argument
;

parametre : type IDENT
;

argument :  IDENT assign expression 
	| expression
; 

expression : valeur
{
        struct noeud *entree;
        if ($1.ptr->info.sorte == SORTE_CONSTANTE)
        {
                if ($1.ptr->info.type == TYPE_INT)
                        entree = get_symbole_constante_int (tds, $1.ptr->info.valeur_entiere);
                else if ($1.ptr->info.type == TYPE_FLOAT)
                        entree = get_symbole_constante (tds, $1.ptr->info.valeur_flottante);
        }
        else entree = get_symbole (tds, $1.ptr->info.nom);
        
        $$.ptr = entree;
}
| expression '+' expression
{
        if ($1.ptr->info.type == TYPE_ERROR || $3.ptr->info.type == TYPE_ERROR)
        {
                $$.ptr = newtemp (&tds, TYPE_ERROR);
        }
        else if (($1.ptr->info.sorte == SORTE_TABLEAU && $1.ptr->info.tableau.is_matrix == false && ($1.indice_demande[0] == -1 && $1.indice_demande[1] == -1))
                 || ($3.ptr->info.sorte == SORTE_TABLEAU && $3.ptr->info.tableau.is_matrix == false && ($3.indice_demande[0] == -1 && $3.indice_demande[1] == -1)))
        {
                yyerror ("+ avec des tableaux");
                $$.ptr = newtemp (&tds, TYPE_ERROR);
        }
        else if ($1.ptr->info.sorte == SORTE_TABLEAU && $1.ptr->info.tableau.is_matrix == true)
        {
               $$.ptr = newtempMatrix (&tds, $1.ptr->info.tableau.nombre_dimension, $1.ptr->info.tableau.taille_dimensions); 
               gencode (liste_quad, QOP_PLUS, $1.ptr, $3.ptr, $$.ptr);
        }
	else if ($3.ptr->info.sorte == SORTE_TABLEAU && $3.ptr->info.tableau.is_matrix == true)
        {
       	$$.ptr = newtempMatrix (&tds, $3.ptr->info.tableau.nombre_dimension, $3.ptr->info.tableau.taille_dimensions); 
        	gencode (liste_quad, QOP_PLUS, $1.ptr, $3.ptr, $$.ptr);
        }
        else if ($1.ptr->info.type == TYPE_FLOAT)
        {
		$$.ptr = newtemp (&tds, TYPE_FLOAT);
		if ($3.ptr->info.type == TYPE_INT)
		{
			struct noeud *tmp = newtemp (&tds, TYPE_FLOAT);
			gencode (liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
			gencode (liste_quad, QOP_PLUS, $1.ptr, tmp, $$.ptr);
		}
		else //2 flottants
		{
			gencode (liste_quad, QOP_PLUS, $1.ptr, $3.ptr, $$.ptr);
		}
        }
        else if ($3.ptr->info.type == TYPE_FLOAT) //donc $1 est un INT
        {
                struct noeud *tmp = newtemp (&tds, TYPE_FLOAT);
                gencode (liste_quad, QOP_CAST, $1.ptr, NULL, tmp);
                $$.ptr = newtemp (&tds, TYPE_FLOAT);
                gencode (liste_quad, QOP_PLUS, tmp, $3.ptr, $$.ptr);
        }
        else if ($1.ptr->info.type == TYPE_INT && $3.ptr->info.type == TYPE_INT)
        {
                $$.ptr = newtemp (&tds, TYPE_INT);
                gencode (liste_quad, QOP_PLUS, $1.ptr, $3.ptr, $$.ptr);
        }
        else
        {
                $$.ptr = newtemp (&tds, TYPE_NONE);
        }
}
| expression '-' expression
{
        if ($1.ptr->info.type == TYPE_ERROR || $3.ptr->info.type == TYPE_ERROR)
        {
                $$.ptr = newtemp (&tds, TYPE_ERROR);
        }
        else if (($1.ptr->info.sorte == SORTE_TABLEAU && $1.ptr->info.tableau.is_matrix == false && ($1.indice_demande[0] == -1 && $1.indice_demande[1] == -1))
                 || ($3.ptr->info.sorte == SORTE_TABLEAU && $3.ptr->info.tableau.is_matrix == false && ($3.indice_demande[0] == -1 && $3.indice_demande[1] == -1)))
        {
                yyerror ("- avec des tableaux");
                $$.ptr = newtemp (&tds, TYPE_ERROR);
        }
        else if ($1.ptr->info.sorte == SORTE_TABLEAU && $1.ptr->info.tableau.is_matrix == true)
        {
               $$.ptr = newtempMatrix (&tds, $1.ptr->info.tableau.nombre_dimension, $1.ptr->info.tableau.taille_dimensions); 
               gencode (liste_quad, QOP_MINUS, $1.ptr, $3.ptr, $$.ptr);
        }
	else if ($3.ptr->info.sorte == SORTE_TABLEAU && $3.ptr->info.tableau.is_matrix == true)
        {
               $$.ptr = newtempMatrix (&tds, $3.ptr->info.tableau.nombre_dimension, $3.ptr->info.tableau.taille_dimensions); 
               gencode (liste_quad, QOP_MINUS, $1.ptr, $3.ptr, $$.ptr);
        }
        else if ($1.ptr->info.type == TYPE_FLOAT)
        {
                $$.ptr = newtemp (&tds, TYPE_FLOAT);
                if ($3.ptr->info.type == TYPE_INT)
                {
                        struct noeud *tmp = newtemp (&tds, TYPE_FLOAT);
                        gencode (liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
                        gencode (liste_quad, QOP_MINUS, $1.ptr, tmp, $$.ptr);
                }
                else //2 flottants
                {
                        gencode (liste_quad, QOP_MINUS, $1.ptr, $3.ptr, $$.ptr);
                }
        }
        else if ($3.ptr->info.type == TYPE_FLOAT) //donc $1 est un INT
        {
                struct noeud *tmp = newtemp (&tds, TYPE_FLOAT);
                gencode (liste_quad, QOP_CAST, $1.ptr, NULL, tmp);
                $$.ptr = newtemp (&tds, TYPE_FLOAT);
                gencode (liste_quad, QOP_MINUS, tmp, $3.ptr, $$.ptr);
        }
        else if ($1.ptr->info.type == TYPE_INT && $3.ptr->info.type == TYPE_INT)
        {
                $$.ptr = newtemp (&tds, TYPE_INT);
                gencode (liste_quad, QOP_MINUS, $1.ptr, $3.ptr, $$.ptr);
        }
        else
        {
                $$.ptr = newtemp (&tds, TYPE_NONE);
        }
}
| expression '*' expression
{
        if ($1.ptr->info.type == TYPE_ERROR || $3.ptr->info.type == TYPE_ERROR)
        {
                $$.ptr = newtemp (&tds, TYPE_ERROR);
        }
        else if (($1.ptr->info.sorte == SORTE_TABLEAU && $1.ptr->info.tableau.is_matrix == false && ($1.indice_demande[0] == -1 && $1.indice_demande[1] == -1))
                 || ($3.ptr->info.sorte == SORTE_TABLEAU && $3.ptr->info.tableau.is_matrix == false && ($3.indice_demande[0] == -1 && $3.indice_demande[1] == -1)))
        {
                yyerror ("* avec des tableaux");
                $$.ptr = newtemp (&tds, TYPE_ERROR);
        }
	else if ($1.ptr->info.sorte == SORTE_TABLEAU && $1.ptr->info.tableau.is_matrix == true)
        {
               $$.ptr = newtempMatrix (&tds, $1.ptr->info.tableau.nombre_dimension, $1.ptr->info.tableau.taille_dimensions); 
               gencode (liste_quad, QOP_MULT, $1.ptr, $3.ptr, $$.ptr);
        }
	else if ($3.ptr->info.sorte == SORTE_TABLEAU && $3.ptr->info.tableau.is_matrix == true)
        {
               $$.ptr = newtempMatrix (&tds, $3.ptr->info.tableau.nombre_dimension, $3.ptr->info.tableau.taille_dimensions); 
               gencode (liste_quad, QOP_MULT, $1.ptr, $3.ptr, $$.ptr);
        }
        else if ($1.ptr->info.type == TYPE_FLOAT)
        {
                $$.ptr = newtemp (&tds, TYPE_FLOAT);
                if ($3.ptr->info.type == TYPE_INT)
                {
                        struct noeud *tmp = newtemp (&tds, TYPE_FLOAT);
                        gencode (liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
                        gencode (liste_quad, QOP_MULT, $1.ptr, tmp, $$.ptr);
                }
        	else //2 flottants
                {
                        gencode (liste_quad, QOP_MULT, $1.ptr, $3.ptr, $$.ptr);
                }
        }
        else if ($3.ptr->info.type == TYPE_FLOAT) //donc $1 est un INT
        {
                struct noeud *tmp = newtemp (&tds, TYPE_FLOAT);
                gencode (liste_quad, QOP_CAST, $1.ptr, NULL, tmp);
                $$.ptr = newtemp (&tds, TYPE_FLOAT);
                gencode (liste_quad, QOP_MULT, tmp, $3.ptr, $$.ptr);
        }
        else if ($1.ptr->info.type == TYPE_INT && $3.ptr->info.type == TYPE_INT)
        {
                $$.ptr = newtemp (&tds, TYPE_INT);
                gencode (liste_quad, QOP_MULT, $1.ptr, $3.ptr, $$.ptr);
        }
        else
        {
                $$.ptr = newtemp (&tds, TYPE_NONE);
        }
}
| expression '/' expression
{
        if ($1.ptr->info.type == TYPE_ERROR || $3.ptr->info.type == TYPE_ERROR)
        {
                $$.ptr = newtemp (&tds, TYPE_ERROR);
        }
        else if (($1.ptr->info.sorte == SORTE_TABLEAU && $1.ptr->info.tableau.is_matrix == false && ($1.indice_demande[0] == -1 && $1.indice_demande[1] == -1))
                 || ($3.ptr->info.sorte == SORTE_TABLEAU && $3.ptr->info.tableau.is_matrix == false && ($3.indice_demande[0] == -1 && $3.indice_demande[1] == -1)))
        {
                yyerror ("/ avec des tableaux");
                $$.ptr = newtemp (&tds, TYPE_ERROR);
        }
	else if ($1.ptr->info.sorte == SORTE_TABLEAU && $1.ptr->info.tableau.is_matrix == true)
        {
               $$.ptr = newtempMatrix (&tds, $1.ptr->info.tableau.nombre_dimension, $1.ptr->info.tableau.taille_dimensions); 
               gencode (liste_quad, QOP_DIV, $1.ptr, $3.ptr, $$.ptr);
        }
	else if ($3.ptr->info.sorte == SORTE_TABLEAU && $3.ptr->info.tableau.is_matrix == true)
        {
               $$.ptr = newtempMatrix (&tds, $3.ptr->info.tableau.nombre_dimension, $3.ptr->info.tableau.taille_dimensions); 
               gencode (liste_quad, QOP_DIV, $1.ptr, $3.ptr, $$.ptr);
        }
        else if ($1.ptr->info.type == TYPE_FLOAT)
        {
                $$.ptr = newtemp (&tds, TYPE_FLOAT);
                if ($3.ptr->info.type == TYPE_INT)
                {
                        struct noeud *tmp = newtemp (&tds, TYPE_FLOAT);
                        gencode (liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
                        gencode (liste_quad, QOP_DIV, $1.ptr, tmp, $$.ptr);
                }
                else //2 flottants
                {
                        gencode (liste_quad, QOP_DIV, $1.ptr, $3.ptr, $$.ptr);
                }
        }
        else if ($3.ptr->info.type == TYPE_FLOAT) //donc $1 est un INT
        {
                struct noeud *tmp = newtemp (&tds, TYPE_FLOAT);
                gencode (liste_quad, QOP_CAST, $1.ptr, NULL, tmp);
                $$.ptr = newtemp (&tds, TYPE_FLOAT);
                gencode (liste_quad, QOP_DIV, tmp, $3.ptr, $$.ptr);
        }
        else if ($1.ptr->info.type == TYPE_INT && $3.ptr->info.type == TYPE_INT)
        {
                $$.ptr = newtemp (&tds, TYPE_INT);
                gencode (liste_quad, QOP_DIV, $1.ptr, $3.ptr, $$.ptr);
        }
        else
        {
                $$.ptr = newtemp (&tds, TYPE_NONE);
        }
}
| expression '>' expression
{
        if ($1.ptr->info.type == TYPE_ERROR || $3.ptr->info.type == TYPE_ERROR)
        {
                $$.ptr = newtemp (&tds, TYPE_ERROR);
        }
        else if ($1.ptr->info.sorte == SORTE_TABLEAU || $3.ptr->info.sorte == SORTE_TABLEAU)
        {
                yyerror ("> avec des tableaux/matrices");
                $$.ptr = newtemp (&tds, TYPE_ERROR);
        }
        else if ($1.ptr->info.type == TYPE_FLOAT)
        {
                $$.ptr = newtemp (&tds, TYPE_FLOAT);
                if ($3.ptr->info.type == TYPE_INT)
                {
                        struct noeud *tmp = newtemp (&tds, TYPE_FLOAT);
                        gencode (liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
                        gencode (liste_quad, QOP_GT, $1.ptr, tmp, $$.ptr);
                }
                else //2 flottants
                {
                        gencode (liste_quad, QOP_GT, $1.ptr, $3.ptr, $$.ptr);
                }
        }
        else if ($3.ptr->info.type == TYPE_FLOAT) //donc $1 est un INT
        {
                struct noeud *tmp = newtemp (&tds, TYPE_FLOAT);
                gencode (liste_quad, QOP_CAST, $1.ptr, NULL, tmp);
                $$.ptr = newtemp (&tds, TYPE_FLOAT);
                gencode (liste_quad, QOP_GT, tmp, $3.ptr, $$.ptr);
        }
        else if ($1.ptr->info.type == TYPE_INT && $3.ptr->info.type == TYPE_INT)
        {
                $$.ptr = newtemp (&tds, TYPE_INT);
                gencode (liste_quad, QOP_GT, $1.ptr, $3.ptr, $$.ptr);
        }
        else
        {
                $$.ptr = newtemp (&tds, TYPE_NONE);
        }
}
| expression '<' expression
{
        if ($1.ptr->info.type == TYPE_ERROR || $3.ptr->info.type == TYPE_ERROR)
        {
                $$.ptr = newtemp (&tds, TYPE_ERROR);
        }
        else if ($1.ptr->info.sorte == SORTE_TABLEAU || $3.ptr->info.sorte == SORTE_TABLEAU)
        {
                yyerror ("< avec des tableaux/matrices");
                $$.ptr = newtemp (&tds, TYPE_ERROR);
        }
        else if ($1.ptr->info.type == TYPE_FLOAT)
        {
                $$.ptr = newtemp (&tds, TYPE_FLOAT);
                if ($3.ptr->info.type == TYPE_INT)
                {
                        struct noeud *tmp = newtemp (&tds, TYPE_FLOAT);
                        gencode (liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
                        gencode (liste_quad, QOP_LT, $1.ptr, tmp, $$.ptr);
                }
                else //2 flottants
                {
                        gencode (liste_quad, QOP_LT, $1.ptr, $3.ptr, $$.ptr);
                }
        }
        else if ($3.ptr->info.type == TYPE_FLOAT) //donc $1 est un INT
        {
                struct noeud *tmp = newtemp (&tds, TYPE_FLOAT);
                gencode (liste_quad, QOP_CAST, $1.ptr, NULL, tmp);
                $$.ptr = newtemp (&tds, TYPE_FLOAT);
                gencode (liste_quad, QOP_LT, tmp, $3.ptr, $$.ptr);
        }
        else if ($1.ptr->info.type == TYPE_INT && $3.ptr->info.type == TYPE_INT)
        {
                $$.ptr = newtemp (&tds, TYPE_INT);
                gencode (liste_quad, QOP_LT, $1.ptr, $3.ptr, $$.ptr);
        }
        else
        {
                $$.ptr = newtemp (&tds, TYPE_NONE);
        }
}
| expression LE expression
{
        if ($1.ptr->info.type == TYPE_ERROR || $3.ptr->info.type == TYPE_ERROR)
        {
                $$.ptr = newtemp (&tds, TYPE_ERROR);
        }
        else if ($1.ptr->info.sorte == SORTE_TABLEAU || $3.ptr->info.sorte == SORTE_TABLEAU)
        {
                yyerror ("<= avec des tableaux/matrices");
                $$.ptr = newtemp (&tds, TYPE_ERROR);
        }
        else if ($1.ptr->info.type == TYPE_FLOAT)
        {
                $$.ptr = newtemp (&tds, TYPE_FLOAT);
                if ($3.ptr->info.type == TYPE_INT)
                {
                        struct noeud *tmp = newtemp (&tds, TYPE_FLOAT);
                        gencode (liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
                        gencode (liste_quad, QOP_LE, $1.ptr, tmp, $$.ptr);
                }
                else //2 flottants
                {
                        gencode (liste_quad, QOP_LE, $1.ptr, $3.ptr, $$.ptr);
                }
        }
        else if ($3.ptr->info.type == TYPE_FLOAT) //donc $1 est un INT
        {
                struct noeud *tmp = newtemp (&tds, TYPE_FLOAT);
                gencode (liste_quad, QOP_CAST, $1.ptr, NULL, tmp);
                $$.ptr = newtemp (&tds, TYPE_FLOAT);
                gencode (liste_quad, QOP_LE, tmp, $3.ptr, $$.ptr);
        }
        else if ($1.ptr->info.type == TYPE_INT && $3.ptr->info.type == TYPE_INT)
        {
                $$.ptr = newtemp (&tds, TYPE_INT);
                gencode (liste_quad, QOP_LE, $1.ptr, $3.ptr, $$.ptr);
        }
        else
        {
                $$.ptr = newtemp (&tds, TYPE_NONE);
        }
}
| expression GE expression
{
        if ($1.ptr->info.type == TYPE_ERROR || $3.ptr->info.type == TYPE_ERROR)
        {
                $$.ptr = newtemp (&tds, TYPE_ERROR);
        }
        else if ($1.ptr->info.sorte == SORTE_TABLEAU || $3.ptr->info.sorte == SORTE_TABLEAU)
        {
                yyerror (">= avec des tableaux/matrices");
                $$.ptr = newtemp (&tds, TYPE_ERROR);
        }
        else if ($1.ptr->info.type == TYPE_FLOAT)
        {
                $$.ptr = newtemp (&tds, TYPE_FLOAT);
                if ($3.ptr->info.type == TYPE_INT)
                {
                        struct noeud *tmp = newtemp (&tds, TYPE_FLOAT);
                        gencode (liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
                        gencode (liste_quad, QOP_GE, $1.ptr, tmp, $$.ptr);
                }
                else //2 flottants
                {
                        gencode (liste_quad, QOP_GE, $1.ptr, $3.ptr, $$.ptr);
                }
        }
        else if ($3.ptr->info.type == TYPE_FLOAT) //donc $1 est un INT
        {
                struct noeud *tmp = newtemp (&tds, TYPE_FLOAT);
                gencode (liste_quad, QOP_CAST, $1.ptr, NULL, tmp);
                $$.ptr = newtemp (&tds, TYPE_FLOAT);
                gencode (liste_quad, QOP_GE, tmp, $3.ptr, $$.ptr);
        }
        else if ($1.ptr->info.type == TYPE_INT && $3.ptr->info.type == TYPE_INT)
        {
                $$.ptr = newtemp (&tds, TYPE_INT);
                gencode (liste_quad, QOP_GE, $1.ptr, $3.ptr, $$.ptr);
        }
        else
        {
                $$.ptr = newtemp (&tds, TYPE_NONE);
        }
}
| expression EQ expression
{
        if ($1.ptr->info.type == TYPE_ERROR || $3.ptr->info.type == TYPE_ERROR)
        {
                $$.ptr = newtemp (&tds, TYPE_ERROR);
        }
        else if ($1.ptr->info.sorte == SORTE_TABLEAU || $3.ptr->info.sorte == SORTE_TABLEAU)
        {
                yyerror ("== avec des tableaux/matrices");
                $$.ptr = newtemp (&tds, TYPE_ERROR);
        }
        else if ($1.ptr->info.type == TYPE_FLOAT)
        {
                $$.ptr = newtemp (&tds, TYPE_FLOAT);
                if ($3.ptr->info.type == TYPE_INT)
                {
                        struct noeud *tmp = newtemp (&tds, TYPE_FLOAT);
                        gencode (liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
                        gencode (liste_quad, QOP_EQ, $1.ptr, tmp, $$.ptr);
                }
                else //2 flottants
                {
                        gencode (liste_quad, QOP_EQ, $1.ptr, $3.ptr, $$.ptr);
                }
        }
        else if ($3.ptr->info.type == TYPE_FLOAT) //donc $1 est un INT
        {
                struct noeud *tmp = newtemp (&tds, TYPE_FLOAT);
                gencode (liste_quad, QOP_CAST, $1.ptr, NULL, tmp);
                $$.ptr = newtemp (&tds, TYPE_FLOAT);
                gencode (liste_quad, QOP_EQ, tmp, $3.ptr, $$.ptr);
        }
        else if ($1.ptr->info.type == TYPE_INT && $3.ptr->info.type == TYPE_INT)
        {
                $$.ptr = newtemp (&tds, TYPE_INT);
                gencode (liste_quad, QOP_EQ, $1.ptr, $3.ptr, $$.ptr);
        }
        else
        {
                $$.ptr = newtemp (&tds, TYPE_NONE);
        }
}
| expression NE expression
{
        if ($1.ptr->info.type == TYPE_ERROR || $3.ptr->info.type == TYPE_ERROR)
        {
                $$.ptr = newtemp (&tds, TYPE_ERROR);
        }
        else if ($1.ptr->info.sorte == SORTE_TABLEAU || $3.ptr->info.sorte == SORTE_TABLEAU)
        {
                yyerror ("!= avec des tableaux/matrices");
                $$.ptr = newtemp (&tds, TYPE_ERROR);
        }
        else if ($1.ptr->info.type == TYPE_FLOAT)
        {
                $$.ptr = newtemp (&tds, TYPE_FLOAT);
                if ($3.ptr->info.type == TYPE_INT)
                {
                        struct noeud *tmp = newtemp (&tds, TYPE_FLOAT);
                        gencode (liste_quad, QOP_CAST, $3.ptr, NULL, tmp);
                        gencode (liste_quad, QOP_NE, $1.ptr, tmp, $$.ptr);
                }
        	else //2 flottants
                {
                        gencode (liste_quad, QOP_NE, $1.ptr, $3.ptr, $$.ptr);
                }
        }
        else if ($3.ptr->info.type == TYPE_FLOAT) //donc $1 est un INT
        {
                struct noeud *tmp = newtemp (&tds, TYPE_FLOAT);
                gencode (liste_quad, QOP_CAST, $1.ptr, NULL, tmp);
                $$.ptr = newtemp (&tds, TYPE_FLOAT);
                gencode (liste_quad, QOP_NE, tmp, $3.ptr, $$.ptr);
        }
        else if ($1.ptr->info.type == TYPE_INT && $3.ptr->info.type == TYPE_INT)
        {
                $$.ptr = newtemp (&tds, TYPE_INT);
                gencode (liste_quad, QOP_NE, $1.ptr, $3.ptr, $$.ptr);
        }
        else
        {
                $$.ptr = newtemp (&tds, TYPE_NONE);
        }
}
| '-' expression %prec UNARY
{
        if ($2.ptr->info.type == TYPE_ERROR)
        {
                $$.ptr = newtemp (&tds, TYPE_ERROR);
        }
        else if ($2.ptr->info.sorte == SORTE_TABLEAU && $2.ptr->info.tableau.is_matrix == false)
        {
                yyerror ("- avec un tableau");
                $$.ptr = newtemp (&tds, TYPE_ERROR);
        }
        else if ($2.ptr->info.sorte == SORTE_TABLEAU && $2.ptr->info.tableau.is_matrix == true)
        {
                if($2.ptr->info.tableau.nombre_dimension == 2)
                {
                	$$.ptr = newtempMatrix (&tds, $2.ptr->info.tableau.nombre_dimension, $2.ptr->info.tableau.taille_dimensions); 
             	 	gencode(liste_quad, QOP_UNARY_MINUS, $2.ptr, NULL, $$.ptr);
                }
        }
        else if ($2.ptr->info.type == TYPE_FLOAT)
        {
                $$.ptr = newtemp (&tds, TYPE_FLOAT);
                gencode (liste_quad, QOP_UNARY_MINUS, $2.ptr, NULL, $$.ptr);
        }
        else if ($2.ptr->info.type == TYPE_INT)
        {
                $$.ptr = newtemp (&tds, TYPE_INT);
                gencode (liste_quad, QOP_UNARY_MINUS, $2.ptr, NULL, $$.ptr);
        }
        else
        {
                $$.ptr = newtemp (&tds, TYPE_NONE);
        }
}
| '+' expression %prec UNARY { $$ = $2; }
| '~' expression %prec UNARY
{
        if ($2.ptr->info.type == TYPE_ERROR)
        {
                $$.ptr = newtemp (&tds, TYPE_ERROR);
        }
        else if ($2.ptr->info.sorte == SORTE_TABLEAU && $2.ptr->info.tableau.is_matrix == false)
        {
                yyerror ("~ avec un tableau");
                $$.ptr = newtemp (&tds, TYPE_ERROR);
        }
        else if ($2.ptr->info.type == TYPE_FLOAT && $2.ptr->info.tableau.is_matrix == false)
        {
                yyerror ("~ avec un flottant");
                $$.ptr = newtemp (&tds, TYPE_ERROR);
        }
        else if ($2.ptr->info.sorte == SORTE_TABLEAU && $2.ptr->info.tableau.is_matrix == true)
        {
		//transposée : inverser taille colonne et ligne
		int taille_dimensions_transposee[MAX_DIMENSION_TABLEAU] = {$2.ptr->info.tableau.taille_dimensions[1], $2.ptr->info.tableau.taille_dimensions[0]};
		$$.ptr = newtempMatrix (&tds, $2.ptr->info.tableau.nombre_dimension, taille_dimensions_transposee); 

		gencode(liste_quad, QOP_NEG, $2.ptr, NULL, $$.ptr);
        }
        else if ($2.ptr->info.type == TYPE_INT)
        {
                $$.ptr = newtemp (&tds, TYPE_INT);
                gencode (liste_quad, QOP_NEG, $2.ptr, NULL, $$.ptr);
        }
        else
        {
                $$.ptr = newtemp (&tds, TYPE_NONE);
        }
}
| '(' expression ')' { $$ = $2; }
;

       
intervalle_dimension : 
	intervalle_dimension '[' liste_rangee ']' {$$.nDim = $1.nDim + 1; 
							$$.taillesDim[0] = $1.tailleDim; 
							$$.taillesDim[1] = $3.tailleDim;} 
    | '[' liste_rangee ']' {
			    $$.type_tab = $2.type_tab; 
			    $$.nDim = 1; 
			    $$.tailleDim = $2.tailleDim; 
			    $$.taillesDim[0] = $2.tailleDim; 
			    } 
;

liste_rangee : 
	liste_rangee ';' rangee { $$.nDim = $1.nDim + 1;}
    | rangee {$$ = $1; $$.nDim = 1;}
;

rangee : '*' {$$.type_tab = TYPE_MATRIX; /*Avoir un '*' => Matrix exclusivement*/} 
        | expression INTERV_OP expression {$$.type_tab = TYPE_NONE;}
        | expression {
        if($1.ptr->info.sorte == SORTE_VARIABLE) 
        {
		fprintf(stderr, "CAS variable non géré\n");  
		exit(1);
        }
        else 
        {
        	$$.tailleDim = $1.ptr->info.valeur_entiere; 	
        }
        
        $$.type_tab = TYPE_NONE;}
;

valeur_tableau : '{' liste_nombre '}' {$$.type_tab = $2.type_tab; 

					static int listeValeursEntieres_temp[1024]; //pour stocker les valeurs des éventuelles doubles accolades des tableaux 2D. 
					static float listeValeursFlottantes_temp[1024];
					
					/*
					
					Exemple : float tab1[2][2] = {{7.1, 8.1},{9.1, 1.1}};
					
					Premier parsage : {7.1, 8.1} => 7.1 et 8.1 dans listeValeursFlottantes_temp (le reste sont des 0.0)
					Deuxième parsage : {9.1, 1.1} =>7.1, 8.1, 9.1 et 1.1 dans listeValeursFlottantes_temp (le reste sont des 0.0)
					
					On a voulu sauvegarder les valeurs du premier parsage : sans ce tableau, les valeurs du premier parsage sont perdues
					
					*/

					if($2.type_tab == TYPE_INT)		
					{
						for(int i = last_index; i < 1024; i++)
						{
							listeValeursEntieres_temp[i] = $2.listeValeursEntieres[i];
						}
						memcpy($$.listeValeursEntieres, listeValeursEntieres_temp, 1024*sizeof(int));
					}	
					else if($2.type_tab == TYPE_FLOAT)
					{
						for(int i = last_index; i < 1024; i++)
						{
							listeValeursFlottantes_temp[i] = $2.listeValeursFlottantes[i];
						}
						memcpy($$.listeValeursFlottantes, listeValeursFlottantes_temp, 1024*sizeof(float));
						
						/*
					
						Exemple : float tab1[2][2] = {{7.1, 8.1},{9.1, 1.1}};
						
						Premier parsage : {7.1, 8.1} => last_index vaut 2
						Deuxième parsage : {9.1, 1.1} => pour insérer dans la 3ème case du tableau au deuxième parsage, on part à i = last_index = 2
						
						*/
						
					}
					
					last_index = indice;
					}
		| '{' liste_tableau '}' {$$ = $2; $$.nDim = $2.nDim + 1;}
;
		
liste_tableau : liste_tableau ',' valeur_tableau {
					if($3.type_tab == TYPE_INT)
						memcpy($$.listeValeursEntieres, $3.listeValeursEntieres, 1024*sizeof(int)); //remonter les valeurs dans $$
					else if($3.type_tab == TYPE_FLOAT)
						memcpy($$.listeValeursFlottantes, $3.listeValeursFlottantes, 1024*sizeof(float));
					}
		| valeur_tableau {$$ = $1;}
;

liste_nombre : liste_entiers {$$.type_tab = TYPE_INT;} | liste_flottants {$$.type_tab = TYPE_FLOAT;}
;

liste_flottants : liste_flottants ',' constante_flottante {$$.listeValeursFlottantes[indice] = $3; 
								indice += 1;}
		 | constante_flottante {$$.listeValeursFlottantes[indice] = $1; 
		 			indice+=1;}
;

liste_entiers : liste_entiers ',' constante_entiere {$$.listeValeursEntieres[indice] = $3; 
							indice += 1;}
		| constante_entiere {$$.listeValeursEntieres[indice] = $1; 
					indice+=1;}
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
			$$.indice_demande[0] = -1; 
			$$.indice_demande[1] = -1;
		}	
	| constante_entiere {
        	struct noeud* entree = get_symbole_constante_int(tds, $1);
		    $$.ptr = entree;
		    $$.indice_demande[0] = -1; 
			$$.indice_demande[1] = -1;
		}
	| constante_flottante {
			struct noeud* entree = get_symbole_constante(tds, $1);	
			$$.ptr = entree;
			$$.indice_demande[0] = -1; 
			$$.indice_demande[1] = -1;
		}
    | IDENT intervalle_dimension {
    			struct noeud* entree = get_symbole(tds, $1); //tableau récupéré
			if(entree == NULL) {
				char err_msg[MAX_LENGTH_VAR_NAME + 20];
				sprintf(err_msg, "Undeclared name : '%s'", $1);
				yyerror(err_msg);
				entree = insertion(&tds, $1, SORTE_NONE, TYPE_ERROR);
			}
			
			if($2.nDim == 1) //tableau 1 dimension => uniquement $2.taillesDim[0] contient une valeur (Exemple : int tab[2]; => $2.taillesDim[0] = 2)
			{
				$$.indice_demande[0] = $2.taillesDim[0]; 
			}
			else if($2.nDim == 2) //tableau 2 dimensions => $2.taillesDim[0] (= taille dimension 1) et $2.taillesDim[1] (= taille dimension 2) contiennent une valeur (Exemple : int tab[2][3]; => $2.taillesDim[0] = 2 et $2.taillesDim[1] = 3)
			{
				$$.indice_demande[0] = $2.taillesDim[0]; 
				$$.indice_demande[1] = $2.taillesDim[1]; 
			}

			if(entree->info.type == TYPE_INT)
			{
				$$.ptr = newtemp (&tds, TYPE_INT);
				
			}
			else if(entree->info.type == TYPE_FLOAT)
			{
				$$.ptr = newtemp (&tds, TYPE_FLOAT);	
			}
			
			struct noeud* indice;
        		if(entree->info.tableau.nombre_dimension == 1)
        		{
				indice = get_symbole_constante_int(tds, $$.indice_demande[0]);
			}
			else if(entree->info.tableau.nombre_dimension == 2)
        		{
        			//tableau 2D => récupérer la bonne case
        			int indice_dim_un = $$.indice_demande[0];
        			int indice_dim_deux = $$.indice_demande[1];
        			
        			//pour obtenir le bon indice (valeurs rangées en ROW ORDER)
        			int vrai_indice = indice_dim_un * entree->info.tableau.taille_dimensions[1] + indice_dim_deux;
        			indice = insertion_constante(&tds, TYPE_INT, vrai_indice); //on ajoute le vrai indice à la table des symboles
        		}
        		
        		gencode(liste_quad, QOP_ASSIGN, entree, indice, $$.ptr); //la case de tableau demandée se trouve dans la valeur_entiere de indice
			}
    | incr_et_decr {
			struct noeud* entree = get_symbole(tds, $1.ptr->info.nom); 
		    if(entree == NULL) {
				char err_msg[MAX_LENGTH_VAR_NAME + 20];
				sprintf(err_msg, "Undeclared name : '%s'", $1.ptr->info.nom);
				yyerror(err_msg);
				entree = insertion(&tds, $1.ptr->info.nom, SORTE_NONE, TYPE_ERROR);
			}
			$$.indice_demande[0] = -1; 
			$$.indice_demande[1] = -1;
			$$.ptr = entree;
		}
    | appel_fonction {} 
;

incr_et_decr : 
	IDENT INCR {
			struct noeud* entree = get_symbole(tds, $1); 
			if(execute_action_incr_et_decr == true)
			{
				$2 = QOP_POST_INCR; 
				if(entree == NULL) {
					char err_msg[MAX_LENGTH_VAR_NAME + 20];
					sprintf(err_msg, "Undeclared name : '%s'", $1);
					yyerror(err_msg);
					entree = insertion(&tds, $1, SORTE_NONE, TYPE_ERROR);
				}
				gencode(liste_quad, $2, entree, NULL, entree);
			}
			else action_incr_et_decr = 0; //pour boucle for => action 0 (i++)
			
			$$.ptr = entree;
		}
	| IDENT DECR {
			struct noeud* entree = get_symbole(tds, $1); 
			if(execute_action_incr_et_decr == true)
			{
				$2 = QOP_POST_DECR;
				if(entree == NULL) {
					char err_msg[MAX_LENGTH_VAR_NAME + 20];
					sprintf(err_msg, "Undeclared name : '%s'", $1);
					yyerror(err_msg);
					entree = insertion(&tds, $1, SORTE_NONE, TYPE_ERROR);
				}
				gencode(liste_quad, $2, entree, NULL, entree);
			}
			else action_incr_et_decr = 1; //pour boucle for => action 1 (i--)
			
			$$.ptr = entree; 
		}
	| INCR IDENT {
			struct noeud* entree = get_symbole(tds, $2);
			if(execute_action_incr_et_decr == true)
			{
				$1 = QOP_PRE_INCR; 
				if(entree == NULL) {
					char err_msg[MAX_LENGTH_VAR_NAME + 20];
					sprintf(err_msg, "Undeclared name : '%s'", $2);
					yyerror(err_msg);
					entree = insertion(&tds, $2, SORTE_NONE, TYPE_ERROR);
				}
				gencode(liste_quad, $1, entree, NULL, entree);
			}
			else action_incr_et_decr = 2; //pour boucle for => action 2 (++i)
			
			$$.ptr = entree;
		}
	| DECR IDENT {
			struct noeud* entree = get_symbole(tds, $2); 
			if(execute_action_incr_et_decr == true)
			{
				$1 = QOP_PRE_DECR;
				if(entree == NULL) {
					char err_msg[MAX_LENGTH_VAR_NAME + 20];
					sprintf(err_msg, "Undeclared name : '%s'", $2);
					yyerror(err_msg);
					entree = insertion(&tds, $2, SORTE_NONE, TYPE_ERROR);
				}
				gencode(liste_quad, $1, entree, NULL, entree);
			}
			else action_incr_et_decr = 3; //pour boucle for => action 3 (--i)
			
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

constante_caractere : C_STR {
			struct noeud* entree = insertion_constante_str(&tds, TYPE_STR, $1);
			strcpy($$, $1);
		} 
;

assign : '=' {$$ = QOP_ASSIGN;}
	| PLUS_ASSIGN {$$ = QOP_PLUS_ASSIGN;}
	| MINUS_ASSIGN {$$ = QOP_MINUS_ASSIGN;}
	| MULT_ASSIGN {$$ = QOP_MULT_ASSIGN;}
	| DIV_ASSIGN {$$ = QOP_DIV_ASSIGN;}
;


            
%%  

void yyerror(const char* msg)
{
    syntax_error = 1;
	fprintf(stderr, "Syntax error : %s\n", msg);
}
