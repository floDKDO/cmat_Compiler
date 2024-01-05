#ifndef __TDS__H__
#define __TDS__H__

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <stdint.h>
#include "global.h"

//tester si la valeur de retour est NULL, si oui, appeler la fonction raler
#define NCHK(prim) do { if ((prim) == NULL) { raler (#prim); } } while (0)

#define MAX_LONGUEUR_VARIABLE 64
#define MAX_DIMENSION_TABLEAU 2

enum type //type de l'identificateur
{
    TYPE_NONE, //aucun type ou type inconnu
	TYPE_INT,
	TYPE_FLOAT,
	TYPE_STR,
	TYPE_MATRIX, //utilisé que lors du parsage du type, ensuite regarder champ is_matrix
	TYPE_ERROR
};

//l'identificateur est quoi ?
enum sorte
{
    SORTE_NONE, //on se sait pas encore ce que c'est 
    SORTE_VARIABLE,
    SORTE_CONSTANTE,
    SORTE_TABLEAU
};


struct info //infos sur un identificateur
{
    //ces trois champs sont communs à toutes les sortes d'identificateurs
    char* nom; //clef de la table de hachage, correspond au nom de l'identificateur
	enum sorte sorte;
	enum type type;
	
	//on peut avoir dans le langage soit des variables, des constantes ou des tableaux
	//utilisation d'une union car un identificateur peut être une seule des trois sortes à la fois
	//VARIABLE (rien de spécial), CONSTANTE (valeur de la constante), TABLEAU et MATRIX (NOMBRE DIM + TAILLES DIM)
	union
	{
	    float valeur_flottante;
	    int valeur_entiere;
	    char* valeur_str;
	    
	    struct tableau
	    {
	        int nombre_dimension;
	        int taille_dimensions[MAX_DIMENSION_TABLEAU]; //taille de chaque dimension : ex -> int tab[2][3]; => nombre_dimension = 2, et taille_dimensions[0] = 2 et taille_dimensions[1] = 3
	        int* valeurs_entieres_tableau; //stockés en row major
	        float* valeurs_flottantes_tableau; //stockés en row major
	        
	        ///////////////
		bool is_matrix; //est vrai si le tableau est une matrix
		///////////////
	        
	    } tableau; //tableau et matrix
	    
	    /*struct matrix
	    {
	        int nombre_dimension;
	        int taille_dimensions[2]; //une matrix peut posséder au max deux dimensions
	    } matrix; */
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
	int num_temp; //permet de nommer les variables temporaires selon le nombre qui ont été créées
};

void raler (const char *msg);

int fonctionHash(char* nom, int taille_max);

struct tds* creation_tds(int taille_max, int taille_actuelle);

void rehashing(struct tds** tds);

void destruction_tds(struct tds* tds);

struct noeud* get_elem(struct noeud* tete, char* nom) ;

struct noeud* ajout_queue(struct noeud* tete, struct noeud* new_queue);

struct noeud* insertion(struct tds** tds, char* nom, enum sorte sorte, enum type type);

struct noeud* insertion_tableau(struct tds** tds, char* nom, enum type type, int nombre_dimension, int taille_dimensions[MAX_DIMENSION_TABLEAU]);

struct noeud* insertion_constante(struct tds** tds, enum type type, float valeur);
struct noeud* insertion_constante_str(struct tds** tds, enum type type, char valeur[MAX_LONGUEUR_VARIABLE]);

struct noeud* newtemp(struct tds** tds, enum type type);

struct noeud* get_symbole(struct tds* tds, char* nom);

bool recherche(struct tds* tds, char* nom);

struct noeud* get_symbole_constante(struct tds* tds, float valeur);
struct noeud* get_symbole_constante_int(struct tds* tds, int valeur);
struct noeud* get_symbole_constante_str(struct tds* tds, char valeur[MAX_LONGUEUR_VARIABLE]);

enum type get_type(struct tds* tds, char* nom);

enum type get_sorte(struct tds* tds, char* nom);

void affichage_tds(struct tds* tds);

void affichage_symbole(struct noeud* noeud);


#endif
