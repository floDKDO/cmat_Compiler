int main() {
    int n = 10, k = 7, op;

    if (k < n-k) {
        op = n-k;
    } else {
        op = k;
    }

    int res = 1;
    for (int i = n ; i > op ; i--) {
        res *= i;
    }
    
    for (i = n-op ; i > 0 ; i--) {
        res /= i;
    }

    printf("k = ");
    print(k);
    printf("n = ");
    print(n);
    printf("k parmis n = ");
    print(res);

}