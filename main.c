#include <stdio.h>
#include "tds.h"
#include "quad.h"
extern int yyparse();
extern FILE* yyin;
//extern int yydebug;

struct tds* tds;
struct Liste_Quad* liste_quad;
FILE * output;

int main(int argc, char *argv[])
{
	//yydebug = 1;
	
	output = stdout;
	
	if (argc > 1) yyin = fopen(argv[1], "r");
	if (argc > 2) output = fopen(argv[2], "w");

	tds = creation_tds(2000, 0);
	liste_quad = creer_liste_quad(17);

	int r = yyparse();
	printf("-> %d\n", r);
	
	if(!r){
		affichage_tds(tds);
		affiche_code(liste_quad);
		fprintf(output, "\n\n");
		affiche_spim(liste_quad);
	}

	destruction_liste_quad(liste_quad);
	destruction_tds(tds);
	if (argc > 2) fclose(output);
	return r;
}
