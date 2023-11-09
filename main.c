#include <stdio.h>
extern int yyparse();
//extern int yydebug;

int main()
{
	//yydebug = 1;
	int r = yyparse();
	printf("-> %d\n", r);
	return r;
}
