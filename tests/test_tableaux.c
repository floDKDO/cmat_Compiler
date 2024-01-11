int main() {
    int tab[5] = {1,3,2,2,5}, res = 0;

    res = res + tab[0];
    res = res + tab[1];
    res = res + tab[2];
    res = res + tab[3];
    res = res + tab[4];

    printf("La somme des valeurs du tableau est : ");
    print(res);
}