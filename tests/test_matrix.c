int main() {
    matrix A[2][2] = {{1.5,2.6},{3.2,4.1}}, B[2][2] = {{5.4,6.0},{7.05,8.8}}, C[2][2];
    C = 2*A+3*B;
    
    printf("A = ");
    printmat(A);
    printf("B = ");
    printmat(B);
    printf("2A+3B = ");
    printmat(C);
}