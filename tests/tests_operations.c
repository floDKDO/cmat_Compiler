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
	
	if(test < 42)
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
	
	return 0;
}
