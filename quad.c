#include "quad.h"


struct Liste_Quad* creer_liste_quad(int taille_max)
{
    struct Liste_Quad* liste_quad = malloc(sizeof(struct Liste_Quad));
    liste_quad->taille_max = taille_max;
    liste_quad->taille_actuelle = 0;
    liste_quad->nextquad = 0;
    liste_quad->compteur_label_else = 0;
    liste_quad->compteur_label_endif = 0;
    liste_quad->compteur_label_loop = 0;
    liste_quad->compteur_label_endloop = 0;
    
    liste_quad->quads = malloc(taille_max * sizeof(struct Quad));
    
    return liste_quad;
}


void destruction_liste_quad(struct Liste_Quad* liste_quad)
{
	free(liste_quad->quads); 
	free(liste_quad); 
}



struct Liste_Quad* agrandir_liste_quad(struct Liste_Quad* liste_quad)
{
	liste_quad->taille_max += 1024;
    NCHK(liste_quad->quads = realloc(liste_quad->quads, liste_quad->taille_max * sizeof(struct Quad)));
}


int gencode(struct Liste_Quad* liste_quad, enum QuadOp op, struct noeud* arg1, struct noeud* arg2, struct noeud* res)
{
	if(liste_quad->nextquad == liste_quad->taille_max)
		agrandir_liste_quad(liste_quad);
		
	struct Quad* quad = &(liste_quad->quads[liste_quad->nextquad]);
	quad->op = op;
	quad->arg1 = arg1;
	quad->arg2 = arg2;
	quad->res = res;
	
	++ (liste_quad->nextquad);
	return liste_quad->nextquad - 1;
}


void affiche_quad(struct Quad* quad)
{
	switch(quad->op)
	{
		case QOP_PRE_INCR:
			printf("++");
			affichage_symbole(quad->res);
			break;
		case QOP_PRE_DECR:
			printf("--");
			affichage_symbole(quad->res);
			break;
		case QOP_POST_INCR:
			affichage_symbole(quad->res);
			printf("++");
			break;
		case QOP_POST_DECR:
			affichage_symbole(quad->res);
			printf("--");
			break;
		case QOP_LE: //<=
			affichage_symbole(quad->res);
			printf(" <= ");
			affichage_symbole(quad->arg1);
			break;
		case QOP_LT: //<
			affichage_symbole(quad->res);
			printf(" < ");
			affichage_symbole(quad->arg1);
			break;
		case QOP_GE: //>=
			affichage_symbole(quad->res);
			printf(" >= ");
			affichage_symbole(quad->arg1);
			break;
		case QOP_GT: //>
			affichage_symbole(quad->res);
			printf(" > ");
			affichage_symbole(quad->arg1);
			break;
		case QOP_EQ: //==
			affichage_symbole(quad->res);
			printf(" == ");
			affichage_symbole(quad->arg1);
			break;
		case QOP_NE: //!=
			affichage_symbole(quad->res);
			printf(" != ");
			affichage_symbole(quad->arg1);
			break;
		case QOP_ASSIGN: //=
			affichage_symbole(quad->res);
			printf(" = ");
			affichage_symbole(quad->arg1);
			break;
		case QOP_PLUS:
			affichage_symbole(quad->res);
			printf(" = ");
			affichage_symbole(quad->arg1);
			printf(" + ");
			affichage_symbole(quad->arg2);
			break;
		case QOP_UNARY_PLUS:
			affichage_symbole(quad->res);
			printf(" = ");
			printf(" +");
			affichage_symbole(quad->arg1);
			break;
		case QOP_MINUS:
			affichage_symbole(quad->res);
			printf(" = ");
			affichage_symbole(quad->arg1);
			printf(" - ");
			affichage_symbole(quad->arg2);
			break;
		case QOP_UNARY_MINUS:
			affichage_symbole(quad->res);
			printf(" = ");
			printf(" -");
			affichage_symbole(quad->arg1);
			break;
		case QOP_MULT:
			affichage_symbole(quad->res);
			printf(" = ");
			affichage_symbole(quad->arg1);
			printf(" * ");
			affichage_symbole(quad->arg2);
			break;
		case QOP_DIV:	
			affichage_symbole(quad->res);
			printf(" = ");
			affichage_symbole(quad->arg1);
			printf(" / ");
			affichage_symbole(quad->arg2);
			break;
		case QOP_PLUS_ASSIGN:
			affichage_symbole(quad->res);
			printf(" += ");
			affichage_symbole(quad->arg1);
			break;
		case QOP_MINUS_ASSIGN:
			affichage_symbole(quad->res);
			printf(" -= ");
			affichage_symbole(quad->arg1);
			break;
		case QOP_MULT_ASSIGN:
			affichage_symbole(quad->res);
			printf(" *= ");
			affichage_symbole(quad->arg1);
			break;
		case QOP_DIV_ASSIGN:
			affichage_symbole(quad->res);
			printf(" /= ");
			affichage_symbole(quad->arg1);
			break;
		case QOP_MOD_ASSIGN:
			affichage_symbole(quad->res);
			printf(" %%= ");
			affichage_symbole(quad->arg1);
			break;
		case QOP_AND_ASSIGN:
			affichage_symbole(quad->res);
			printf(" &= ");
			affichage_symbole(quad->arg1);
			break;
		case QOP_XOR_ASSIGN:
			affichage_symbole(quad->res);
			printf(" ^= ");
			affichage_symbole(quad->arg1);
			break;
		case QOP_OR_ASSIGN:
			affichage_symbole(quad->res);
			printf(" |= ");
			affichage_symbole(quad->arg1);
			break;
		case QOP_LOGICAL_AND:
			affichage_symbole(quad->res);
			printf(" = ");
			affichage_symbole(quad->arg1);
			printf(" && ");
			affichage_symbole(quad->arg2);
			break;
		case QOP_LOGICAL_OR:
			affichage_symbole(quad->res);
			printf(" = ");
			affichage_symbole(quad->arg1);
			printf(" || ");
			affichage_symbole(quad->arg2);
			break;
		case QOP_AND:
			affichage_symbole(quad->res);
			printf(" = ");
			affichage_symbole(quad->arg1);
			printf(" & ");
			affichage_symbole(quad->arg2);
			break;
		case QOP_OR:
			affichage_symbole(quad->res);
			printf(" = ");
			affichage_symbole(quad->arg1);
			printf(" | ");
			affichage_symbole(quad->arg2);
			break;
		case QOP_XOR:
			affichage_symbole(quad->res);
			printf(" = ");
			affichage_symbole(quad->arg1);
			printf(" ^ ");
			affichage_symbole(quad->arg2);
			break;
		case QOP_MOD:
			affichage_symbole(quad->res);
			printf(" = ");
			affichage_symbole(quad->arg1);
			printf(" %% ");
			affichage_symbole(quad->arg2);
			break;
		case QOP_GOTO:
			printf("goto ");
			affichage_symbole(quad->res);
			break;
		case QOP_NOT:
			affichage_symbole(quad->res);
			printf(" = ");
			printf("!");
			affichage_symbole(quad->arg1);
			break;
		case QOP_NEG: //~
			affichage_symbole(quad->res);
			printf(" = ");
			printf(" ~");
			affichage_symbole(quad->arg1);
			break;
		case QOP_CAST:
			affichage_symbole(quad->res);
			printf(" = ");
			printf("(float)");
			affichage_symbole(quad->arg1);
			break;
		case QOP_PRINTF:
			printf("printf(");
			affichage_symbole(quad->res);
			printf(")");
			break;
		case QOP_PRINT:
			printf("print(");
			affichage_symbole(quad->res);
			printf(")");
			break;
		
		default:
			break;
	}
}

void affiche_code(struct Liste_Quad* liste_quad)
{
    unsigned int i;
    for(i = 0; i < liste_quad->nextquad; i++)
    {
        printf("%4u | ", i);
        affiche_quad(&liste_quad->quads[i]);
        printf("\n");
    }
}


void affiche_quad_spim(struct Quad* quad)
{
	switch (quad->op)
	{
		case QOP_WHILE:
			fprintf(output, "Loop%d:\n", liste_quad->compteur_label_loop);
			break;
			
		case QOP_HALF_WHILE:
			fprintf(output, "\tlw $t0, _%s\n", quad->res->info.nom);
			fprintf(output, "\tbeq $t0 0 End_Loop%d\n", liste_quad->compteur_label_endloop);
			break;
			
		case QOP_END_WHILE:
			fprintf(output, "\tj Loop%d\n", liste_quad->compteur_label_loop);
			fprintf(output, "End_Loop%d:\n", liste_quad->compteur_label_endloop);
			liste_quad->compteur_label_loop += 1;
    			liste_quad->compteur_label_endloop += 1;
			break;
	
		case QOP_FOR:
			fprintf(output, "\tli $t0 %d\n", quad->arg1->info.valeur_entiere); //valeur de l'itérateur
			fprintf(output, "\tsw $t0 _%s\n", quad->res->info.nom); //mettre la valeur dans i => int i = 5; mettre la valeur 5 dans i
			fprintf(output, "Loop%d:\n", liste_quad->compteur_label_loop);
			break;
			
		case QOP_HALF_FOR:
			//quad->res->info.valeur_entiere : 0 ou 1 selon que la condition soit vraie ou pas => si = 0, fin de la boucle
			fprintf(output, "\tlw $t0, _%s\n", quad->res->info.nom);
			fprintf(output, "\tbeq $t0 0 End_Loop%d\n", liste_quad->compteur_label_endloop);
			break;
			
		case QOP_END_FOR:
			fprintf(output, "\tj Loop%d\n", liste_quad->compteur_label_loop);
			fprintf(output, "End_Loop%d:\n", liste_quad->compteur_label_endloop);
			liste_quad->compteur_label_loop += 1;
    			liste_quad->compteur_label_endloop += 1;
			break;
	
		case QOP_IF:
			if(quad->res->info.type == TYPE_INT)
			{
				fprintf(output, "\tlw $t0, _%s\n", quad->res->info.nom);
				fprintf(output, "\tbeq $t0 0 Else%u\n", liste_quad->compteur_label_else); //si la condition est fausse, ne pas exécuter le code du if
			}
			else if(quad->res->info.type == TYPE_FLOAT)
			{
				//TODO
			}
			break;
			
		case QOP_HALF_IF:
			fprintf(output, "\tj Endif%d\n", liste_quad->compteur_label_endif);
			break;
			
		case QOP_ELSE_IF:
			fprintf(output, "Else%d:\n", liste_quad->compteur_label_else);
			liste_quad->compteur_label_else += 1;
			break;
			
		case QOP_END_IF:
			fprintf(output, "Endif%d:\n", liste_quad->compteur_label_endif); //label
			liste_quad->compteur_label_endif += 1;
			break;
	
		case QOP_PRINTF:
			fprintf(output, "\tla $a0 _%s\n", quad->res->info.nom);
			fprintf(output, "\tli $v0, 4\n");
			fprintf(output, "\tsyscall\n");
			break;
			
		case QOP_PRINT:
		
			if (quad->res->info.sorte == SORTE_CONSTANTE) 
			{
				if (quad->res->info.type == TYPE_INT) 
				{
					fprintf(output, "\tli $a0 %d\n", quad->res->info.valeur_entiere);
					fprintf(output, "\tli $v0, 1\n");
				}
				else if (quad->res->info.type == TYPE_FLOAT) 
				{
					fprintf(output, "\tli.s $f12 %f\n", quad->res->info.valeur_flottante);
					fprintf(output, "\tli $v0, 2\n");
				}
			}
			else if (quad->res->info.sorte == SORTE_VARIABLE) 
			{
				if (quad->res->info.type == TYPE_INT) 
				{
					fprintf(output, "\tlw $a0 _%s\n", quad->res->info.nom);
					fprintf(output, "\tli $v0, 1\n");
				}
				else if (quad->res->info.type == TYPE_FLOAT) 
				{
					fprintf(output, "\tl.s $f12 _%s\n", quad->res->info.nom);
					fprintf(output, "\tli $v0, 2\n");
				}
			}
			
			fprintf(output, "\tsyscall\n");
			
			//on ajoute un \n après un print
			fprintf(output, "\n\tli $v0 4\n\tla $a0 newline\n\tsyscall\n");
			break;
	
		case QOP_PRE_INCR:
			if (quad->res->info.type == TYPE_INT) 
			{
				fprintf(output, "\tlw $t0 _%s\n", quad->res->info.nom);
				fprintf(output, "\taddi $t0 $t0 1\n");
				fprintf(output, "\tsw $t0 _%s\n", quad->res->info.nom);
			}
			else
			{
				fprintf(output, "\tl.s $f0 _%s\n", quad->res->info.nom);
				fprintf(output, "\tl.s $f1 _constante_float_incr\n");
				fprintf(output, "\tadd.s $f0 $f0 $f1\n");
				fprintf(output, "\ts.s $f0 _%s\n", quad->res->info.nom);
			}
			break;
			
		case QOP_PRE_DECR:
			if (quad->res->info.type == TYPE_INT) 
			{
				fprintf(output, "\tlw $t0 _%s\n", quad->res->info.nom);
				fprintf(output, "\taddi $t0 $t0 -1\n");
				fprintf(output, "\tsw $t0 _%s\n", quad->res->info.nom);
			}
			else
			{
				fprintf(output, "\tl.s $f0 _%s\n", quad->res->info.nom);
				fprintf(output, "\tl.s $f1 _constante_float_decr\n");
				fprintf(output, "\tadd.s $f0 $f0 $f1\n");
				fprintf(output, "\ts.s $f0 _%s\n", quad->res->info.nom);
			}
			break;
			
		case QOP_POST_INCR:
			if (quad->res->info.type == TYPE_INT) 
			{
				fprintf(output, "\tlw $t0 _%s\n", quad->res->info.nom);
				fprintf(output, "\taddi $t1 $t0 1\n");
				fprintf(output, "\tsw $t1 _%s\n", quad->res->info.nom);
			}
			else
			{
				fprintf(output, "\tl.s $f0 _%s\n", quad->res->info.nom);
				fprintf(output, "\tl.s $f1 _constante_float_incr\n");
				fprintf(output, "\tadd.s $f2 $f0 $f1\n");
				fprintf(output, "\ts.s $f2 _%s\n", quad->res->info.nom);
			}
			break;
			
		case QOP_POST_DECR:
			if (quad->res->info.type == TYPE_INT) 
			{
				fprintf(output, "\tlw $t0 _%s\n", quad->res->info.nom);
				fprintf(output, "\taddi $t1 $t0 -1\n");
				fprintf(output, "\tsw $t1 _%s\n", quad->res->info.nom);
			}
			else
			{
				fprintf(output, "\tl.s $f0 _%s\n", quad->res->info.nom);
				fprintf(output, "\tl.s $f1 _constante_float_decr\n");
				fprintf(output, "\tadd.s $f2 $f0 $f1\n");
				fprintf(output, "\ts.s $f2 _%s\n", quad->res->info.nom);
			}
			break;
	
		case QOP_PLUS:
		if (quad->res->info.type == TYPE_INT) {
			if (quad->arg1->info.sorte == SORTE_CONSTANTE) {
				fprintf(output, "\tli $t0 %d\n", quad->arg1->info.valeur_entiere);
			} else {
				fprintf(output, "\tlw $t0 _%s\n", quad->arg1->info.nom);
			}
			if (quad->arg2->info.sorte == SORTE_CONSTANTE) {
				fprintf(output, "\taddi $t2 $t0 %d\n", quad->arg2->info.valeur_entiere);
			} else {
				fprintf(output, "\tlw $t1 _%s\n", quad->arg2->info.nom);
				fprintf(output, "\tadd $t2 $t0 $t1\n");
			}
			fprintf(output, "\tsw $t2 _%s\n", quad->res->info.nom);
		} else {
			if (quad->arg1->info.sorte == SORTE_CONSTANTE) {
				fprintf(output, "\tli.s $f0 %f\n", quad->arg1->info.valeur_flottante);
			} else {
				fprintf(output, "\tl.s $f0 _%s\n", quad->arg1->info.nom);
			}
			if (quad->arg2->info.sorte == SORTE_CONSTANTE) {
				fprintf(output, "\tli.s $f1 %f\n", quad->arg2->info.valeur_flottante);
			} else {
				fprintf(output, "\tl.s $f1 _%s\n", quad->arg2->info.nom);
			}
			fprintf(output, "\tadd.s $f2 $f0 $f1\n");
			fprintf(output, "\ts.s $f2 _%s\n", quad->res->info.nom);
		}
		break;
	case QOP_MINUS:
		if (quad->res->info.type == TYPE_INT) {
			if (quad->arg1->info.sorte == SORTE_CONSTANTE) {
				fprintf(output, "\tli $t0 %d\n", quad->arg1->info.valeur_entiere);
			} else {
				fprintf(output, "\tlw $t0 _%s\n", quad->arg1->info.nom);
			}
			if (quad->arg2->info.sorte == SORTE_CONSTANTE) {
				fprintf(output, "\tli $t1 %d\n", quad->arg2->info.valeur_entiere);
			} else {
				fprintf(output, "\tlw $t1 _%s\n", quad->arg2->info.nom);
			}
			fprintf(output, "\tsub $t2 $t0 $t1\n");
			fprintf(output, "\tsw $t2 _%s\n", quad->res->info.nom);
		} else {
			if (quad->arg1->info.sorte == SORTE_CONSTANTE) {
				fprintf(output, "\tli.s $f0 %f\n", quad->arg1->info.valeur_flottante);
			} else {
				fprintf(output, "\tl.s $f0 _%s\n", quad->arg1->info.nom);
			}
			if (quad->arg2->info.sorte == SORTE_CONSTANTE) {
				fprintf(output, "\tli.s $f1 %f\n", quad->arg2->info.valeur_flottante);
			} else {
				fprintf(output, "\tl.s $f1 _%s\n", quad->arg2->info.nom);
			}
			fprintf(output, "\tsub.s $f2 $f0 $f1\n");
			fprintf(output, "\ts.s $f2 _%s\n", quad->res->info.nom);
		}
		break;
	case QOP_UNARY_MINUS:
		if (quad->res->info.type == TYPE_INT) {
			if (quad->arg1->info.sorte == SORTE_CONSTANTE) {
				fprintf(output, "\tli $t0 %d\n", quad->arg1->info.valeur_entiere);
			} else {
				fprintf(output, "\tlw $t0 _%s\n", quad->arg1->info.nom);
			}
			fprintf(output, "\tneg $t2 $t0\n");
			fprintf(output, "\tsw $t2 _%s\n", quad->res->info.nom);
		} else {
			if (quad->arg1->info.sorte == SORTE_CONSTANTE) {
				fprintf(output, "\tli.s $f0 %f\n", quad->arg1->info.valeur_flottante);
			} else {
				fprintf(output, "\tl.s $f0 _%s\n", quad->arg1->info.nom);
			}
			fprintf(output, "\tneg.s $f2 $f0\n");
			fprintf(output, "\ts.s $f2 _%s\n", quad->res->info.nom);
		}
		break;
	case QOP_MULT:
		if (quad->res->info.type == TYPE_INT) {
			if (quad->arg1->info.sorte == SORTE_CONSTANTE) {
				fprintf(output, "\tli $t0 %d\n", quad->arg1->info.valeur_entiere);
			} else {
				fprintf(output, "\tlw $t0 _%s\n", quad->arg1->info.nom);
			}
			if (quad->arg2->info.sorte == SORTE_CONSTANTE) {
				fprintf(output, "\tli $t1 %d\n", quad->arg2->info.valeur_entiere);
			} else {
				fprintf(output, "\tlw $t1 _%s\n", quad->arg2->info.nom);
			}
			fprintf(output, "\tmul $t2 $t0 $t1\n");
			fprintf(output, "\tsw $t2 _%s\n", quad->res->info.nom);
		} else {
			if (quad->arg1->info.sorte == SORTE_CONSTANTE) {
				fprintf(output, "\tli.s $f0 %f\n", quad->arg1->info.valeur_flottante);
			} else {
				fprintf(output, "\tl.s $f0 _%s\n", quad->arg1->info.nom);
			}
			if (quad->arg2->info.sorte == SORTE_CONSTANTE) {
				fprintf(output, "\tli.s $f1 %f\n", quad->arg2->info.valeur_flottante);
			} else {
				fprintf(output, "\tl.s $f1 _%s\n", quad->arg2->info.nom);
			}
			fprintf(output, "\tmul.s $f2 $f0 $f1\n");
			fprintf(output, "\ts.s $f2 _%s\n", quad->res->info.nom);
		}
		break;
	case QOP_DIV:
		if (quad->res->info.type == TYPE_INT) {
			if (quad->arg1->info.sorte == SORTE_CONSTANTE) {
				fprintf(output, "\tli $t0 %d\n", quad->arg1->info.valeur_entiere);
			} else {
				fprintf(output, "\tlw $t0 _%s\n", quad->arg1->info.nom);
			}
			if (quad->arg2->info.sorte == SORTE_CONSTANTE) {
				fprintf(output, "\tli $t1 %d\n", quad->arg2->info.valeur_entiere);
			} else {
				fprintf(output, "\tlw $t1 _%s\n", quad->arg2->info.nom);
			}
			fprintf(output, "\tdiv $t2 $t0 $t1\n");
			fprintf(output, "\tsw $t2 _%s\n", quad->res->info.nom);
		} else {
			if (quad->arg1->info.sorte == SORTE_CONSTANTE) {
				fprintf(output, "\tli.s $f0 %f\n", quad->arg1->info.valeur_flottante);
			} else {
				fprintf(output, "\tl.s $f0 _%s\n", quad->arg1->info.nom);
			}
			if (quad->arg2->info.sorte == SORTE_CONSTANTE) {
				fprintf(output, "\tli.s $f1 %f\n", quad->arg2->info.valeur_flottante);
			} else {
				fprintf(output, "\tl.s $f1 _%s\n", quad->arg2->info.nom);
			}
			fprintf(output, "\tdiv.s $f2 $f0 $f1\n");
			fprintf(output, "\ts.s $f2 _%s\n", quad->res->info.nom);
		}
		break;
	case QOP_ASSIGN:
		if (quad->res->info.type == TYPE_INT) {
			if (quad->arg1->info.sorte == SORTE_CONSTANTE) {
				fprintf(output, "\tli $t0 %d\n", quad->arg1->info.valeur_entiere);
			} else {
				fprintf(output, "\tlw $t0 _%s\n", quad->arg1->info.nom);
			}
			fprintf(output, "\tsw $t0 _%s\n", quad->res->info.nom);
		} else {
			if (quad->arg1->info.sorte == SORTE_CONSTANTE) {
				fprintf(output, "\tli.s $f0 %f\n", quad->arg1->info.valeur_flottante);
			} else {
				fprintf(output, "\tl.s $f0 _%s\n", quad->arg1->info.nom);
			}
			fprintf(output, "\ts.s $f0 _%s\n", quad->res->info.nom);
		}
		break;

	case QOP_AND:
		if (quad->arg1->info.sorte == SORTE_CONSTANTE)
		{
			fprintf(output, "\tli $t0 %d\n", quad->arg1->info.valeur_entiere);
		} else {
			fprintf(output, "\tlw $t0 _%s\n", quad->arg1->info.nom);
		}
		if (quad->arg2->info.sorte == SORTE_CONSTANTE)
		{
			fprintf(output, "\tandi $t2 $t0 %d\n", quad->arg1->info.valeur_entiere);
		} else {
			fprintf(output, "\tlw $t1 _%s\n", quad->arg1->info.nom);
			fprintf(output, "\tand $t2 $t0 $t1\n");
		}
		fprintf(output, "\tsw $t2 _%s\n", quad->res->info.nom);
		break;
	case QOP_OR:
		if (quad->arg1->info.sorte == SORTE_CONSTANTE)
		{
			fprintf(output, "\tli $t0 %d\n", quad->arg1->info.valeur_entiere);
		} else {
			fprintf(output, "\tlw $t0 _%s\n", quad->arg1->info.nom);
		}
		if (quad->arg2->info.sorte == SORTE_CONSTANTE)
		{
			fprintf(output, "\tori $t2 $t0 %d\n", quad->arg1->info.valeur_entiere);
		} else {
			fprintf(output, "\tlw $t1 _%s\n", quad->arg1->info.nom);
			fprintf(output, "\tor $t2 $t0 $t1\n");
		}
		fprintf(output, "\tsw $t2 _%s\n", quad->res->info.nom);
		break;
	case QOP_XOR:
		if (quad->arg1->info.sorte == SORTE_CONSTANTE)
		{
			fprintf(output, "\tli $t0 %d\n", quad->arg1->info.valeur_entiere);
		} else {
			fprintf(output, "\tlw $t0 _%s\n", quad->arg1->info.nom);
		}
		if (quad->arg2->info.sorte == SORTE_CONSTANTE)
		{
			fprintf(output, "\txori $t2 $t0 %d\n", quad->arg1->info.valeur_entiere);
		} else {
			fprintf(output, "\tlw $t1 _%s\n", quad->arg1->info.nom);
			fprintf(output, "\txor $t2 $t0 $t1\n");
		}
		fprintf(output, "\tsw $t2 _%s\n", quad->res->info.nom);
		break;
	case QOP_MOD:
		if (quad->arg1->info.sorte == SORTE_CONSTANTE)
		{
			fprintf(output, "\tli $t0 %d\n", quad->arg1->info.valeur_entiere);
		} else {
			fprintf(output, "\tlw $t0 _%s\n", quad->arg1->info.nom);
		}
		if (quad->arg2->info.sorte == SORTE_CONSTANTE)
		{
			fprintf(output, "\tli $t1 %d\n", quad->arg1->info.valeur_entiere);
		} else {
			fprintf(output, "\tlw $t1 _%s\n", quad->arg1->info.nom);
		}
		fprintf(output, "\trem $t2 $t0 $t1\n");
		fprintf(output, "\tsw $t2 _%s\n", quad->res->info.nom);
		break;
	case QOP_NOT:
		if (quad->arg1->info.sorte == SORTE_CONSTANTE)
		{
			fprintf(output, "\tli $t0 %d\n", quad->arg1->info.valeur_entiere);
		} else {
			fprintf(output, "\tlw $t0 _%s\n", quad->arg1->info.nom);
		}
		fprintf(output, "\tslti $t2 $t0 1\n");
		fprintf(output, "\tsw $t2 _%s\n", quad->res->info.nom);
		break;
	case QOP_NEG:
		if (quad->arg1->info.sorte == SORTE_CONSTANTE)
		{
			fprintf(output, "\tli $t0 %d\n", quad->arg1->info.valeur_entiere);
		} else {
			fprintf(output, "\tlw $t0 _%s\n", quad->arg1->info.nom);
		}
		fprintf(output, "\tnot $t2 $t0\n");
		fprintf(output, "\tsw $t2 _%s\n", quad->res->info.nom);
		break;

	case QOP_LE:
		if (quad->arg1->info.type == TYPE_INT)
		{	
			if (quad->arg1->info.sorte == SORTE_CONSTANTE)
			{
				fprintf(output, "\tli $t0 %d\n", quad->arg1->info.valeur_entiere);
			} else {
				fprintf(output, "\tlw $t0 _%s\n", quad->arg1->info.nom);
			}
			if (quad->arg2->info.sorte == SORTE_CONSTANTE)
			{
				fprintf(output, "\tli $t1 %d\n", quad->arg2->info.valeur_entiere);
			} else {
				fprintf(output, "\tlw $t1 _%s\n", quad->arg2->info.nom);
			}
			fprintf(output, "\tsle $t2 $t0 $t1\n");
			fprintf(output, "\tsw $t2 _%s\n", quad->res->info.nom);
		} else {
			if (quad->arg1->info.sorte == SORTE_CONSTANTE)
			{
				fprintf(output, "\tli.s $f0 %f\n", quad->arg1->info.valeur_flottante);
			} else {
				fprintf(output, "\tl.s $f0 _%s\n", quad->arg1->info.nom);
			}
			if (quad->arg2->info.sorte == SORTE_CONSTANTE)
			{
				fprintf(output, "\tli.s $f1 %f\n", quad->arg2->info.valeur_flottante);
			} else {
				fprintf(output, "\tl.s $f1 _%s\n", quad->arg2->info.nom);
			}
			fprintf(output, "\t c.le.s $f0 $f1\n");
		}
		break;
	case QOP_LT:
		if (quad->arg1->info.type == TYPE_INT)
		{	
			if (quad->arg1->info.sorte == SORTE_CONSTANTE)
			{
				fprintf(output, "\tli $t0 %d\n", quad->arg1->info.valeur_entiere);
			} else {
				fprintf(output, "\tlw $t0 _%s\n", quad->arg1->info.nom);
			}
			if (quad->arg2->info.sorte == SORTE_CONSTANTE)
			{
				fprintf(output, "\tli $t1 %d\n", quad->arg2->info.valeur_entiere);
			} else {
				fprintf(output, "\tlw $t1 _%s\n", quad->arg2->info.nom);
			}
			fprintf(output, "\tslt $t2 $t0 $t1\n");
			fprintf(output, "\tsw $t2 _%s\n", quad->res->info.nom);
		} else {
			if (quad->arg1->info.sorte == SORTE_CONSTANTE)
			{
				fprintf(output, "\tli.s $f0 %f\n", quad->arg1->info.valeur_flottante);
			} else {
				fprintf(output, "\tl.s $f0 _%s\n", quad->arg1->info.nom);
			}
			if (quad->arg2->info.sorte == SORTE_CONSTANTE)
			{
				fprintf(output, "\tli.s $f1 %f\n", quad->arg2->info.valeur_flottante);
			} else {
				fprintf(output, "\tl.s $f1 _%s\n", quad->arg2->info.nom);
			}
			fprintf(output, "\t c.lt.s $f0 $f1\n");
		}
		break;
	case QOP_GE:
		if (quad->arg1->info.type == TYPE_INT)
		{	
			if (quad->arg1->info.sorte == SORTE_CONSTANTE)
			{
				fprintf(output, "\tli $t0 %d\n", quad->arg1->info.valeur_entiere);
			} else {
				fprintf(output, "\tlw $t0 _%s\n", quad->arg1->info.nom);
			}
			if (quad->arg2->info.sorte == SORTE_CONSTANTE)
			{
				fprintf(output, "\tli $t1 %d\n", quad->arg2->info.valeur_entiere);
			} else {
				fprintf(output, "\tlw $t1 _%s\n", quad->arg2->info.nom);
			}
			fprintf(output, "\tsge $t2 $t0 $t1\n");
			fprintf(output, "\tsw $t2 _%s\n", quad->res->info.nom);
		} else {
			//TODO
		}
		break;
	case QOP_GT:
		if (quad->arg1->info.type == TYPE_INT)
		{	
			if (quad->arg1->info.sorte == SORTE_CONSTANTE)
			{
				fprintf(output, "\tli $t0 %d\n", quad->arg1->info.valeur_entiere);
			} else {
				fprintf(output, "\tlw $t0 _%s\n", quad->arg1->info.nom);
			}
			if (quad->arg2->info.sorte == SORTE_CONSTANTE)
			{
				fprintf(output, "\tli $t1 %d\n", quad->arg2->info.valeur_entiere);
			} else {
				fprintf(output, "\tlw $t1 _%s\n", quad->arg2->info.nom);
			}
			fprintf(output, "\tsgt $t2 $t0 $t1\n");
			fprintf(output, "\tsw $t2 _%s\n", quad->res->info.nom);
		} else {
			//TODO
		}
		break;
	case QOP_EQ:
		if (quad->arg1->info.type == TYPE_INT)
		{	
			if (quad->arg1->info.sorte == SORTE_CONSTANTE)
			{
				fprintf(output, "\tli $t0 %d\n", quad->arg1->info.valeur_entiere);
			} else {
				fprintf(output, "\tlw $t0 _%s\n", quad->arg1->info.nom);
			}
			if (quad->arg2->info.sorte == SORTE_CONSTANTE)
			{
				fprintf(output, "\tli $t1 %d\n", quad->arg2->info.valeur_entiere);
			} else {
				fprintf(output, "\tlw $t1 _%s\n", quad->arg2->info.nom);
			}
			
			//fprintf(output, "Valeureee : %d et %s\n", quad->op,quad->res->info.nom);
			
			fprintf(output, "\tseq $t2 $t0 $t1\n");
			fprintf(output, "\tsw $t2 _%s\n", quad->res->info.nom);
		} else {
			if (quad->arg1->info.sorte == SORTE_CONSTANTE)
			{
				fprintf(output, "\tli.s $f0 %f\n", quad->arg1->info.valeur_flottante);
			} else {
				fprintf(output, "\tl.s $f0 _%s\n", quad->arg1->info.nom);
			}
			if (quad->arg2->info.sorte == SORTE_CONSTANTE)
			{
				fprintf(output, "\tli.s $f1 %f\n", quad->arg2->info.valeur_flottante);
			} else {
				fprintf(output, "\tl.s $f1 _%s\n", quad->arg2->info.nom);
			}
			fprintf(output, "\t c.eq.s $f0 $f1\n");
		}
		break;
	case QOP_NE:
		if (quad->arg1->info.type == TYPE_INT)
		{	
			if (quad->arg1->info.sorte == SORTE_CONSTANTE)
			{
				fprintf(output, "\tli $t0 %d\n", quad->arg1->info.valeur_entiere);
			} else {
				fprintf(output, "\tlw $t0 _%s\n", quad->arg1->info.nom);
			}
			if (quad->arg2->info.sorte == SORTE_CONSTANTE)
			{
				fprintf(output, "\tli $t1 %d\n", quad->arg2->info.valeur_entiere);
			} else {
				fprintf(output, "\tlw $t1 _%s\n", quad->arg2->info.nom);
			}
			fprintf(output, "\tsne $t2 $t0 $t1\n");
			fprintf(output, "\tsw $t2 _%s\n", quad->res->info.nom);
		} else {
			//TODO
		}
		break;

	case QOP_CAST:
		if (quad->arg1->info.sorte == SORTE_CONSTANTE)
		{
			fprintf(output, "\tli $t0 %d\n", quad->arg1->info.valeur_entiere);
		} else {
			fprintf(output, "\tlw $t0 _%s\n", quad->arg1->info.nom);
		}
		fprintf(output, "\tmtc1 $t0 $f0\n");
		fprintf(output, "\tcvt.s.w $f0 $f0\n");
		fprintf(output, "\ts.s $f0 _%s\n", quad->res->info.nom);
	default:
		break;
	}
}

void affiche_data_spim()
{	
	fprintf(output, "newline: .asciiz \"\\n\"\n");
	
	//il faut écrire la constante flottante 1.0 pour permettre l'incrémentation
	fprintf(output, "_%s:\t.float %f\n", "constante_float_incr", 1.0);
	//il faut écrire la constante flottante -1.0 pour permettre la décrémentation
	fprintf(output, "_%s:\t.float %f\n", "constante_float_decr", -1.0);
	
	struct noeud* temp;
	for(int i = 0; i < tds->taille_max; i++) 
	{
	    temp = tds->listes[i];
	    while(temp != NULL) 
	    {
	    	if(temp->info.sorte != SORTE_CONSTANTE) {
			if (temp->info.type == TYPE_INT) {
				fprintf(output, "_%s:\t.word %d\n", temp->info.nom, temp->info.valeur_entiere);
			} else if (temp->info.type == TYPE_FLOAT){
				fprintf(output, "_%s:\t.float %f\n", temp->info.nom, temp->info.valeur_flottante);
			}
	    	}
	    	else
	    	{
	    		if(temp->info.type == TYPE_STR)
			{
				fprintf(output, "_%s:\t.asciiz %s\n", temp->info.nom, temp->info.valeur_str);
			}
	    	}
		temp = temp->suivant;
	    }
	}
}

void affiche_spim(struct Liste_Quad* liste_quad) 
{
	fprintf(output, "\t.data\n");
	affiche_data_spim();

	fprintf(output, "\n\t.text\nmain:\n");
	for (unsigned int i = 0; i < liste_quad->nextquad; i++)
	{
		affiche_quad_spim(&liste_quad->quads[i]);
	}
	fprintf(output, "\n\tli $v0 4\n\tla $a0 newline\n\tsyscall\n");
	fprintf(output, "\n\tli $v0 10\n\tsyscall\n");

}


