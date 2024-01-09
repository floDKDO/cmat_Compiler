int main()
{
	float a = 2.5 + 3.2 + 1.4 + 11.6;
	float b, c, d;
	float x = a;
	float z = a + 2.6;
	float s = a - 3.54;
	s = s++;
	float sol = --s;
	sol = s--;
	
	printf("toto\n");
	print(42.02);
	print(41);
	print(sol);
	
	int test = 42;
	
	if(test == 43)
	{
		printf("oui\n");
	}
	else if(test != 42)
	{
		printf("NON\n");
	}
	else 
	{
		printf("TEST\n");
	}
	
	if(test == 41)
	{
		printf("ok\n");
	}
	else
	{
		printf("blabla\n");
	}
	
	for(int i = 10; i > 5; --i)
	{
		printf("TOTO\n");
	}
	
	for(int j = 0; j < 10; j++)
	{
		printf("TITI\n");
	}
	
	while(test > 30)
	{
		print(test);
		test = test - 1;
	}
	
	//float tab[10] = {1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 10.5};
	
	/*matrix testeur[10];
	testeur = tab;
	printmat(testeur);*/
	
	int tableau[4][3] = {{1, 2, 3},{5, 6, 7},{8, 9, 0},{4, 7, 9}};
	float kas = tableau[0][0] + tableau[0][2] / tableau[0][1] * tableau[3][2];
	print(kas);
	
	matrix tab[4][3] = {{1.1, 2.1, 3.1},{5.1, 6.1, 7.1},{8.1, 9.1, 0.1},{8.2, 9.2, 0.2}};
	
	matrix transpose_tab[3][4];
	
	//tab = --tab;
	transpose_tab = ~tab;
	
	printmat(tab);
	printmat(transpose_tab);
	
	tab = 2* tab;
	printmat(tab);
	tab = tab * 3;
	printmat(tab);
	tab = tab/4;
	printmat(tab);
	
	tab = 1 - tab;
	
	
	printmat(tab);
	
	//int tab[2] = {1, 2};
	
	/*for(int k = 0; k < 4; k++)
	{
		print(k);
	}
	
	printf("NEW2\n");
	
	for(int l = 0; l < 3; l++)
	{
		print(tab[l][l]);
	}
	
	printf("NEW3\n");*/
	
	
	/*int abc = 44;
	
	float tab_test[3] = {1.5, 2.5, 3.5};
	
	float case_test = tab_test[1];
	
	print(tab_test[1]);
	
	int tab_testeur[2] = {42, 38};
	
	print(tab_testeur[0]);
	
	float tab[4][3] = {{1.1, 2.1, 3.1},{5.1, 6.1, 7.1},{8.1, 9.1, 0.1},{8.2, 9.2, 0.2}};
	
	float tab1[2][2] = {{7.1, 8.1},{9.1, 1.1}};
	
	float casee = tab[3][2];
	
	float caseee = tab1[1][1];
	
	print(tab[3][2]);*/
	
	//float toto[4][3] = {{1.1, 2.1, 3.1},{5.1, 6.1, 7.1},{8.1, 9.1, 0.1},{8.2, 9.2, 0.2}}, tab[2] = {1.2, 2.3}, tab1[2][2] = {{7.1, 8.1},{9.1, 1.1}}, tata = 42.21;
	
	//int toto[4][3] = {{1, 2, 3},{5, 6, 7},{8, 9, 0},{8, 9, 10}}, tab[2] = {1, 2}, tab1[2][2] = {{7, 8},{9, 11}}, tata = 42;
	
	/*float tab[4] = {1.1, 2.2, 3.3, 4.4};
	
	float bcd = tab[2];
	
	print(bcd);*/
	
	return 0;
}
