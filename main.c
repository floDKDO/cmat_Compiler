#include <stdio.h>
#include "tds.h"
#include "quad.h"
extern int yyparse();
//extern int yydebug;

struct tds* tds;
struct Liste_Quad* liste_quad;

int main()
{
	//yydebug = 1;
	
	tds = creation_tds(2000, 0);
	liste_quad = creer_liste_quad(17);

	int r = yyparse();
	printf("-> %d\n", r);
	
	affichage_tds(tds);
	affiche_code(liste_quad);

	destruction_liste_quad(liste_quad);
	destruction_tds(tds);
	return r;
}
