#ifndef __QUAD__H__
#define __QUAD__H__

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <stdint.h>
#include "tds.h"

//tester si la valeur de retour est NULL, si oui, appeler la fonction raler
#define NCHK(prim) do { if ((prim) == NULL) { raler (#prim); } } while (0)



enum QuadOp
{
	QOP_PRE_INCR,
	QOP_PRE_DECR,
	QOP_POST_INCR,
	QOP_POST_DECR,
	QOP_PLUS,
	QOP_UNARY_PLUS,
	QOP_MINUS,
	QOP_UNARY_MINUS,
	QOP_MULT,
	QOP_DIV,
	QOP_XOR,
	QOP_OR,
	QOP_AND,
	QOP_MOD,
	QOP_NOT,
	QOP_NEG,
	QOP_LE, //<=
	QOP_LT, //<
	QOP_GE, //>=
	QOP_GT, //>
	QOP_EQ, //==
	QOP_NE, //!=
	QOP_ASSIGN, //=
	QOP_ASSIGN_TAB,
	QOP_PLUS_ASSIGN,
	QOP_MINUS_ASSIGN,
	QOP_MULT_ASSIGN,
	QOP_DIV_ASSIGN,
	QOP_MOD_ASSIGN,
	QOP_AND_ASSIGN,
	QOP_XOR_ASSIGN,
	QOP_OR_ASSIGN,
	QOP_LOGICAL_AND,
	QOP_LOGICAL_OR,
	QOP_GOTO,
	QOP_CAST, //INT to FLOAT
	QOP_PRINTF,
	QOP_PRINT,
	QOP_IF,
	QOP_HALF_IF,
	QOP_ELSE_IF,
	QOP_END_IF,
	QOP_FOR,
	QOP_HALF_FOR,
	QOP_END_FOR,
	QOP_WHILE,
	QOP_HALF_WHILE,
	QOP_END_WHILE
};

struct Quad
{
	enum QuadOp op;
	struct noeud* arg1;
	struct noeud* arg2;
	struct noeud* res;
};

struct Liste_Quad 
{
	struct Quad* quads; //tableau de struct Quad*
	int taille_max; //nb entrées max dans la liste de quads
	int taille_actuelle; //nb d'entrées actuellement utilisées dans la liste de quads
	unsigned int nextquad;
	unsigned int compteur_label_else; //Else0:, Else1:, ...
	unsigned int compteur_label_endif; //Endif0:, Endif1:, ...
	unsigned int compteur_label_loop; //Loop:, Loop1:, ...
	unsigned int compteur_label_endloop; //End_Loop0:, End_Loop1:, ...
};


struct Liste_Quad* creer_liste_quad(int taille_max);

void destruction_liste_quad(struct Liste_Quad* liste_quad);

struct Liste_Quad* agrandir_liste_quad(struct Liste_Quad* liste_quad);

int gencode(struct Liste_Quad* liste_quad, enum QuadOp op, struct noeud* arg1, struct noeud* arg2, struct noeud* res);

void affiche_quad(struct Quad* quad);

void affiche_code(struct Liste_Quad* liste_quad);

void affiche_spim(struct Liste_Quad* liste_quad);


#endif
