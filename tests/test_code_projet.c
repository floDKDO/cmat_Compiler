int main() {
	matrix A[2][2]={{12,27},{64,42}}, IA[2][2], B[2]={1,8}, X[2];
	float det;
	/* Calcul de la matrice inverse de A */
	IA = ~A;
	IA = IA[1;0][1;0];
	IA[0][1] = -IA[0][1];
	IA[1][0] = -IA[1][0];
	/* Calcul du déterminant de A */
	/*det = 1/(A[0][0]*A[1][1]-A[0][1]*A[1][0]);
	IA = det*IA;
	/* Calcul de X */
	/*X = IA*B;
	/* Affichage du résultat */
	printmat(IA);
	printf("La solution de l'équation AX=B, avec A = ");
	printmat(A);
	printf("et B = ");
	printmat(B);
	/*printf("est X= ");
	printmat(X);*/
	printf("\n");
	return 0;
}
