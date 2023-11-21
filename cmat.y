%{
    
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <stdint.h>

extern int yylex();
void yyerror(const char* msg);


//tester si la valeur de retour est NULL, si oui, appeler la fonction raler
#define NCHK(prim) do { if ((prim) == NULL) { raler (#prim); } } while (0)

void raler (const char *msg)
{
    perror (msg) ;
    exit (1) ;
}
    
/*typedef struct symbole {
    char* nom;
    struct symbole* suivant;
} symbole;

void initTS();
int addTableSymb(char* symb);
symbole* getTableSymb(int index);
void printTS();
void freeTS();

symbole* TS;

extern int yylex();
void yyerror(const char* msg);

//Initialisation de la table des symboles avec le cas d'arrêt
void initTS(){
    TS = (symbole*) malloc(sizeof(symbole*));
    TS->suivant = TS;
};

//Affichage de chaque symbole
void printTS(){
    for (symbole *iterator = TS ; iterator->suivant != iterator ; iterator = iterator->suivant){
        printf("%s\n", iterator->nom);
    }
}

//Ajout d'un symbole sans doublon avec l'indice dans la liste en retour
int addTableSymb(char* name) {
    
    //On recherche si le nom existe déjà
    int i = 0;
    symbole *iterator;
    for (iterator = TS ; iterator->suivant != iterator ; iterator = iterator->suivant){
        if (strcmp(iterator->nom, name) == 0) {
            return i;
        }
        i++;
    }

    //Sinon on l'ajoute
    iterator->nom = name;
    symbole *symb = (symbole*) malloc(sizeof(symbole*));
    symb->suivant = symb;
    iterator->suivant = symb;
    return i;
}

//Recherche d'un symbole à partir de son indice
symbole* getTableSymb(int index){
    int i = 0;
    symbole *iterator = TS;
    //On avance dans la liste jusqu'à index ou fin de liste
    while (iterator->suivant != iterator && i < index){
        iterator = iterator->suivant;
        i++;
    }
    //On vérifie dans quel cas d'arrêt du while on est
    if (i == index){
        return iterator;
    }
    //Symbole non trouvé
    fprintf(stderr, "Table des Sybloles : index trop grand\n");
}

//Ne surtout pas oublier de libérer les symboles
void freeTS(){
    symbole* pre_iterator = TS;
    symbole* iterator = pre_iterator->suivant;

    while (iterator->suivant != iterator){
        free(pre_iterator);
        pre_iterator = iterator;
        iterator = iterator->suivant;
    }
    free(pre_iterator);
}*/

enum type //type de l'identificateur
{
    TYPE_NONE, //aucun type ou type inconnu
	TYPE_INT,
	TYPE_FLOAT
};

//l'identificateur est quoi ?
enum sorte
{
    RIEN, //on se sait pas encore ce que c'est 
    VARIABLE,
    CONSTANTE,
    TABLEAU
};


struct info //infos sur un identificateur
{
    //ces trois champs sont communs à toutes les sortes d'identificateurs
    char* nom; //clef de la table de hachage, correspond au nom de l'identificateur
	enum sorte sorte;
	enum type type;
	
	//on peut avoir dans le langage soit des variables, des constantes ou des tableaux
	//utilisation d'une union car un identificateur peut être une seule des trois sortes à la fois
	//VARIABLE (rien de spécial), CONSTANTE (valeur de la constante), TABLEAU (NOMBRE DIM + BORNES)
	union
	{
	    struct constante
	    {
	        float valeur; //pourra être casté en int
	    } constante;
	    
	    struct tableau
	    {
	        int nombre_dimension;
	        int borne_inf;
	        int borne_sup;
	    } tableau; //matrix est un tableau
	};
};

struct noeud //représente une entrée de la tds : noeud de liste simplement chaînée
{
	struct info info; //décrit l'identificateur
	struct noeud* suivant;
};

struct tds //tds = table des symboles
{
	struct noeud** listes; //tableau de listes chainees => chaque entree est une liste chainee
	int taille_max; //nb entrées max dans la tds
	int taille_actuelle; //nb d'entrées actuellement utilisées dans la tds
};


//prototypes des fonctions ////////////////////////////////////////////
int fonctionHash(char* nom, int taille_max);
struct tds* creation_tds(int taille_max);
struct tds* rehashing(struct tds* tds);
void destruction_tds(struct tds* tds);
struct noeud* get_elem(struct noeud* tete, char* nom) ;
struct noeud* ajout_queue(struct noeud* tete, struct noeud* new_queue);
struct tds* insertion(struct tds* tds, char* nom, enum sorte sorte, enum type type);
bool recherche(struct tds* tds, char* nom);
enum type get_type(struct tds* tds, char* nom);
enum type get_sorte(struct tds* tds, char* nom);
void affichage_tds(struct tds* tds);
//////////////////////////////////////////////////////////////////////


//Jenkins_one_at_a_time_hash
int fonctionHash(char* nom, int taille_max)
{
    uint32_t hash, i;
    for (hash = i = 0; nom[i] != '\0'; ++i)
    {
        hash += nom[i];
        hash += (hash << 10);
        hash ^= (hash >> 6);
    }
    hash += (hash << 3);
    hash ^= (hash >> 11);
    hash += (hash << 15);
    
    return hash % taille_max;
}


struct tds* creation_tds(int taille_max)
{
    struct tds* tds;
    NCHK(tds = malloc(sizeof(struct tds)));
    tds->taille_max = taille_max;
    tds->taille_actuelle = 0;
	NCHK(tds->listes = malloc(taille_max * sizeof(struct noeud)));
	for(int i = 0; i < taille_max; i++)
	{
		tds->listes[i] = NULL; //mettre toutes les listes à NULL : utile pour la fonction de destruction
	}
	return tds;
}


//fonction de rehashing : elle est appelée quand le load factor >= 0.75
//elle créee une nouvelle tds 2 fois plus grande que l'ancienne
//et remet toutes les anciennes entrées dans cette nouvelle table en les rehashant selon la taille de la nouvelle tds
struct tds* rehashing(struct tds* tds)
{
    struct tds* previous_tds = tds;
    int new_taille_max = previous_tds->taille_max * 2;
    
    struct tds* new_tds = creation_tds(new_taille_max);
    
    for(int i = 0; i < previous_tds->taille_max; i++) //parcourir l'ancienne tds
	{
	    if(previous_tds->listes[i] == NULL) //entrée vide, rien à mettre dans la nouvelle tds : passer à l'itération suivante
	    {
	        continue;
	    }
	    else
	    {
	        //mettre tous les noeuds de la liste chaînée de l'entrée i dans la nouvelle tds
	        while(previous_tds->listes[i] != NULL)
	        {
	            new_tds = insertion(new_tds, previous_tds->listes[i]->info.nom, previous_tds->listes[i]->info.sorte, previous_tds->listes[i]->info.type); //insérer ce noeud à l'indice dans la nouvelle tds
	            previous_tds->listes[i] = previous_tds->listes[i]->suivant;
	        }
	    }
	}
	destruction_tds(previous_tds);
	return new_tds;
}

void destruction_tds(struct tds* tds)
{
    struct noeud* temp;
	for(int i = 0; i < tds->taille_max; i++) //libérer tous les noeuds de chaque liste
	{
	    while(tds->listes[i] != NULL) //si la liste existe
	    {
	        temp = tds->listes[i];
	        tds->listes[i] = tds->listes[i]->suivant;
	        free(temp);
	    }
	}
	free(tds->listes); //libérer le tableau de listes
	free(tds); //libérer la tds
}

//obtenir le noeud de la liste chaînée tête contenant la clef
struct noeud* get_elem(struct noeud* tete, char* nom) 
{
    if(tete == NULL)
    {
        //printf("Liste vide...\n");
        return NULL;
    }
    else
    {
        //parcourir la liste de la tete à la queue
        for(struct noeud* noeud = tete; noeud != NULL; noeud = noeud->suivant)
        {
            if(strcmp(noeud->info.nom, nom) == 0) //si un noeud de la liste contient ce nom
            {
                return noeud; //noeud = noeud ayant le nom "nom"
            }
        }
    } 
    return NULL; //nom non trouvée...
}

struct noeud* ajout_queue(struct noeud* tete, struct noeud* new_queue)
{ 
    struct noeud* queue = tete; //on veut garder la meme tete
    
    while(queue->suivant != NULL)
    {
        queue = queue->suivant;
    }
    queue->suivant = new_queue;
    return tete;
}


struct tds* insertion(struct tds* tds, char* nom, enum sorte sorte, enum type type)
{
    int indice = fonctionHash(nom, tds->taille_max);
    
    //info : il n'est pas nécessaire de regarder chaque entrée de la table des symboles pour vérifier si nom n'est pas déjà présent
    //       car la fonction de hash nous donnerait le même indice pour le même nom
    
    //cas 1 : ajout dans une entrée vide
    if(tds->listes[indice] == NULL)
    {
        //printf("ENTREE %d VIDE : AJOUT DE %s DANS LA TABLE\n", indice, nom);
        
        //créer l'entrée
        struct noeud* noeud;
        NCHK(noeud = malloc(sizeof(struct noeud)));
        noeud->suivant = NULL;
        noeud->info.nom = nom;
        noeud->info.sorte = sorte;
        noeud->info.type = type;
        tds->listes[indice] = noeud;
        tds->taille_actuelle += 1;
    }
    else //cas 2 : ajout dans une entrée non vide
    {
        //parcourir la liste chainée de l'entrée et regarder si la clef est déjà présente
        struct noeud* eventuel_noeud = get_elem(tds->listes[indice], nom);
        
        if(eventuel_noeud != NULL) //différent de NULL => noeud trouvé
        {
            //printf("NOM : %s DEJA PRESENT A l'ENTREE %d, MISE A JOUR !\n", nom, indice);
            
            //le modifier
            eventuel_noeud->info.type = type;
        }
        else
        {
            //printf("PAS PRESENT : AJOUT DE %s DANS LA TABLE A L'ENTREE %d\n", nom, indice);
            
            //créer l'entrée
            struct noeud* noeud;
            NCHK(noeud = malloc(sizeof(struct noeud)));
            noeud->suivant = NULL;
            noeud->info.nom = nom;
            noeud->info.sorte = sorte;
            noeud->info.type = type;
            tds->listes[indice] = ajout_queue(tds->listes[indice], noeud);
            tds->taille_actuelle += 1;
        }
    }
    
    float load_factor = (float)(tds->taille_actuelle) / (float)(tds->taille_max); //obtenir le résultat de la division en nombres flottants
    //printf("LOAD FACTOR : %f\n", load_factor);
    if(load_factor >= 0.75)
    {
        //printf("REHASHING REQUIS\n");
        tds = rehashing(tds);
    }
    
    return tds;
}


bool recherche(struct tds* tds, char* nom)
{
    int indice = fonctionHash(nom, tds->taille_max); //trouver l'entrée
    
    if(tds->listes[indice] == NULL) //entrée vide
    {
        //printf("Entrée %d vide : nom %s non présent\n", indice, nom);
        return false;
    }
    else //entrée non-vide, chercher dans la liste chaînée
    {
        for(struct noeud* noeud = tds->listes[indice]; noeud != NULL; noeud = noeud->suivant)
        {
            if(strcmp(noeud->info.nom, nom) == 0) //si un noeud de la liste contient ce nom
            {
                //printf("Entrée %d non-vide : nom %s présent\n", indice, nom);
                return true; //noeud = noeud ayant le nom "nom"
            }
        }
    }
    //printf("Entrée %d non-vide : nom %s non présent\n", indice, nom);
    
    return false; //cas entrée non vide mais clef non présent
}

//retourne le type d'un nom 
enum type get_type(struct tds* tds, char* nom)
{
    int indice = fonctionHash(nom, tds->taille_max);
    struct noeud* noeud = get_elem(tds->listes[indice], nom);
    return noeud->info.type;
}

enum type get_sorte(struct tds* tds, char* nom)
{
    int indice = fonctionHash(nom, tds->taille_max);
    struct noeud* noeud = get_elem(tds->listes[indice], nom);
    return noeud->info.sorte;
}

//utile pour affichage_tds()
char* parser_enum_sorte(enum sorte sorte)
{
    if(sorte == VARIABLE)
        return "VARIABLE";
    else if(sorte == CONSTANTE)
        return "CONSTANTE";
    else if(sorte == TABLEAU)
        return "TABLEAU";
    else return "RIEN";
}

//utile pour affichage_tds()
char* parser_enum_type(enum type type)
{
    if(type == TYPE_INT)
        return "INT";
    else if(type == TYPE_FLOAT)
        return "FLOAT";
    else return "NONE";
}

void affichage_tds(struct tds* tds)
{
    struct noeud* temp;
    printf("\n");
    printf("\t\t\tTable des symboles\n");
    printf("/////////////////////////////////////////////////////////////////////////\n");
    for(int i = 0; i < tds->taille_max; i++) //libérer tous les noeud de chaque liste
	{
	    temp = tds->listes[i];
	    printf("Entrée %d : ", i);
	    while(temp != NULL) 
	    {
	        printf("|%s, %s, %s|->", temp->info.nom, parser_enum_sorte(temp->info.sorte), parser_enum_type(temp->info.type));
	        temp = temp->suivant;
	    }
	    printf("\n");
	}
	printf("/////////////////////////////////////////////////////////////////////////\n\n");
}

%}

%token INCR DECR INTERV
%token INT FLOAT MATRIX
%token IF ELSE FOR RETURN  
%token MAIN PRINTF PRINT PRINTMAT WHILE
%token IDENT C_INT C_FLOAT C_STR

%start start

%% //grammaire temporaire

start : type element_fonction;



declaration : type liste_element

liste_element : liste_element ',' element | element

element : element_variable | element_fonction;

element_variable : IDENT 
            | IDENT '=' valeur 
            | IDENT liste_dimension
            | IDENT liste_dimension '=' valeur_tableau;


element_fonction : IDENT '(' ')'
            | IDENT '(' liste_argument ')'
            | IDENT '(' ')' corps
            | MAIN '(' ')' corps
            | IDENT '(' liste_argument ')' corps;


type : INT | FLOAT | MATRIX;

liste_dimension : liste_dimension dimension | dimension;
dimension : '[' C_INT ']';

liste_argument : liste_argument ',' argument | argument;
argument : type IDENT | type IDENT '=' constante;
constante : C_INT | C_FLOAT;

valeur_tableau : liste_vecteur | '{' valeur_tableau '}';
liste_vecteur : liste_vecteur ',' valeur_vecteur | valeur_vecteur;
valeur_vecteur : '{' liste_nombre '}';

liste_nombre : liste_entiers | liste_flottants
liste_flottants : liste_flottants ',' C_FLOAT | C_FLOAT;
liste_entiers : liste_entiers ',' C_INT | C_INT;

corps : '{' liste_instruction '}';

affectation : IDENT '=' expression;

expression : valeur
            | expression op expression
            | '-' expression
            | expression INCR
            | expression DECR
            ;

op : '+' | '-' | '*' | '/'

valeur : IDENT
        | constante
        | IDENT '[' valeur INTERV valeur ']'
        | appel_fonction;

appel_fonction : IDENT '(' ')'
                | IDENT '('  ')';

liste_instruction : liste_instruction ';' instruction | instruction;

instruction : declaration | affectation | appel_fonction;

%%  

void yyerror(const char* msg)
{
	fprintf(stderr, "%s\n", msg);
}
