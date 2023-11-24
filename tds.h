#ifndef __TDS__H__
#define __TDS__H__

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <stdint.h>

//tester si la valeur de retour est NULL, si oui, appeler la fonction raler
#define NCHK(prim) do { if ((prim) == NULL) { raler (#prim); } } while (0)

enum type //type de l'identificateur
{
    TYPE_NONE, //aucun type ou type inconnu
	TYPE_INT,
	TYPE_FLOAT
};

//l'identificateur est quoi ?
enum sorte
{
    SORTE_NONE, //on se sait pas encore ce que c'est 
    SORTE_VARIABLE,
    SORTE_CONSTANTE,
    SORTE_TABLEAU,
    SORTE_MATRIX
};


struct info //infos sur un identificateur
{
    //ces trois champs sont communs à toutes les sortes d'identificateurs
    char* nom; //clef de la table de hachage, correspond au nom de l'identificateur
	enum sorte sorte;
	enum type type;
	
	//on peut avoir dans le langage soit des variables, des constantes ou des tableaux
	//utilisation d'une union car un identificateur peut être une seule des trois sortes à la fois
	//VARIABLE (rien de spécial), CONSTANTE (valeur de la constante), TABLEAU (NOMBRE DIM + BORNES), MATRIX (NOMBRE DIM + BORNES)
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
	    } tableau; //tableau (hors matrix)
	    
	    struct matrix
	    {
	        int nombre_dimension;
	        int borne_inf;
	        int borne_sup;
	    } matrix; 
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


#endif
