#include <stdio.h>
#include <getopt.h>
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
	bool option_version = false, option_tos = false, option_o = false; 
	
	char* fichier_name;
	
	static struct option long_options[] =
        {
          {"version", 0, 0, 0},
          {"tos", 0, 0, 1},
          {"o", 1, 0, 2},
          {0, 0, 0, 0}
        };
	
	int opt;
	int long_index = 0;
	while((opt = getopt_long_only(argc, argv, "", long_options, &long_index)) != -1)
	{
		switch(opt)
		{
			case 0: //version
				option_version = true; 
				break;
				
			case 1: //tos
				option_tos = true;
				break;
				
			case 2: //o
				option_o = true;
				fichier_name = optarg;
				break;
				
			default:
				break;
		}
	}
	
	if(option_version == true)
	{
		printf("HALM Florian (SIRIS)\nDENIAU Martin (SDSC)\nMASSEBEUF Valentin (SDSC)\nBLAZEK Killian (I3D)\n");
	}

	if(option_o == true)
	{
		if((output = fopen(fichier_name, "w")) == NULL)
		{
			fprintf(stderr, "Erreur fopen\n");
			exit(1);
		}
	}
	else output = stdout;

	tds = creation_tds(2000, 0);
	liste_quad = creer_liste_quad(17);

	int r = yyparse();
	printf("-> %d\n", r);
	
	if(option_tos == true)
	{
		affichage_tds(tds);
	}
	//affiche_code(liste_quad);
	fprintf(output, "\n\n");
	affiche_spim(liste_quad);

	destruction_liste_quad(liste_quad);
	destruction_tds(tds);
	if(option_o == true)
	{
		fclose(output);
	}
	return r;
}
