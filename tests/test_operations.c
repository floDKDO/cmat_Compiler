int main() {
    int n = 5, k = 2, op;

    if (k < n-k) {
        op = n-k;
    } else {
        op = k;
    }

    int res = 1;
    //           n
    for (int i = 5 ; i > op ; i--) {
        res = res * i;
    }
    
    //          n-op
    for (int j = 2 ; j > 0 ; j--) {
        res = res / j;
    }

    printf("k = ");
    print(k);
    printf("n = ");
    print(n);
    printf("k parmis n = ");
    print(res);

}