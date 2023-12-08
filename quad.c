#include "quad.h"


struct Liste_Quad* creer_liste_quad(int taille_max)
{
    struct Liste_Quad* liste_quad = malloc(sizeof(struct Liste_Quad));
    liste_quad->taille_max = taille_max;
    liste_quad->taille_actuelle = 0;
    liste_quad->nextquad = 0;
    
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
			printf(" !");
			affichage_symbole(quad->arg1);
			break;
		case QOP_NEG: //~
			affichage_symbole(quad->res);
			printf(" = ");
			printf(" ~");
			affichage_symbole(quad->arg1);
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
