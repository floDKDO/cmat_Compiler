#include "quad.h"

void raler (const char *msg)
{
    perror (msg) ;
    exit (1) ;
}


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


struct tds* creation_tds(int taille_max, int taille_actuelle)
{
	struct tds* tds;
	NCHK(tds = malloc(sizeof(struct tds)));
	tds->taille_max = taille_max;
	tds->taille_actuelle = taille_actuelle;
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
/*void rehashing(struct tds** tds)
{
	int new_taille_max = (*tds)->taille_max * 2;

	struct tds* new_tds = creation_tds(new_taille_max, 0);

	struct noeud* noeud;

	for(int i = 0; i < (*tds)->taille_max; i++) //parcourir l'ancienne tds
	{
	    if((*tds)->listes[i] == NULL) //entrée vide, rien à mettre dans la nouvelle tds : passer à l'itération suivante
	    {
		continue;
	    }
	    else
	    {
		//mettre tous les noeuds de la liste chaînée de l'entrée i dans la nouvelle tds
		while((*tds)->listes[i] != NULL)
		{
		    noeud = (*tds)->listes[i];
		    if(noeud->info.sorte == SORTE_CONSTANTE)
		    	insertion_constante(&new_tds, (*tds)->listes[i]->info.type, (*tds)->listes[i]->info.constante.valeur); //insérer ce noeud à l'indice dans la nouvelle tds
		    else insertion(&new_tds, (*tds)->listes[i]->info.nom, (*tds)->listes[i]->info.sorte, (*tds)->listes[i]->info.type); //insérer ce noeud à l'indice dans la nouvelle tds
		    
		    (*tds)->listes[i] = (*tds)->listes[i]->suivant;
		    free(noeud->info.nom);
		    free(noeud);
		}
	    }
	}
	destruction_tds(*tds);
	*tds = new_tds;
}*/

void destruction_tds(struct tds* tds)
{
   	struct noeud* temp;
    
	for(int i = 0; i < tds->taille_max; i++) //libérer tous les noeuds de chaque liste
	{
	    while(tds->listes[i] != NULL) //si la liste existe
	    {
	        temp = tds->listes[i];
	        tds->listes[i] = tds->listes[i]->suivant;
	        if(temp->info.type == TYPE_STR)
	        	free(temp->info.valeur_str);
	        free(temp->info.nom);
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


struct noeud* insertion(struct tds** tds, char* nom, enum sorte sorte, enum type type)
{
    int indice = fonctionHash(nom, (*tds)->taille_max);
    
    //info : il n'est pas nécessaire de regarder chaque entrée de la table des symboles pour vérifier si nom n'est pas déjà présent
    //       car la fonction de hash nous donnerait le même indice pour le même nom
    
    struct noeud* noeud = NULL;
    
    //cas 1 : ajout dans une entrée vide
    if((*tds)->listes[indice] == NULL)
    {
        //printf("ENTREE %d VIDE : AJOUT DE %s DANS LA TABLE\n", indice, nom);
        
        //créer l'entrée
        NCHK(noeud = malloc(sizeof(struct noeud)));
        noeud->suivant = NULL;
        
        NCHK(noeud->info.nom = malloc(MAX_LONGUEUR_VARIABLE * sizeof(char)));
        snprintf(noeud->info.nom, MAX_LONGUEUR_VARIABLE, "%s", nom);
        noeud->info.sorte = sorte;
        noeud->info.type = type;
        noeud->info.valeur_entiere = 0;
        noeud->info.valeur_flottante = 0.0;
        
        (*tds)->listes[indice] = noeud;
        (*tds)->taille_actuelle += 1;
    }
    else //cas 2 : ajout dans une entrée non vide
    {
        //parcourir la liste chainée de l'entrée et regarder si la clef est déjà présente
        struct noeud* eventuel_noeud = get_elem((*tds)->listes[indice], nom);
        
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
            NCHK(noeud = malloc(sizeof(struct noeud)));
            noeud->suivant = NULL;
            NCHK(noeud->info.nom = malloc(MAX_LONGUEUR_VARIABLE * sizeof(char)));
            snprintf(noeud->info.nom, MAX_LONGUEUR_VARIABLE, "%s", nom);
            noeud->info.sorte = sorte;
            noeud->info.type = type;
	     noeud->info.valeur_entiere = 0;
	     noeud->info.valeur_flottante = 0.0;
            
            (*tds)->listes[indice] = ajout_queue((*tds)->listes[indice], noeud);
            (*tds)->taille_actuelle += 1;
        }
    }
    
    /*float load_factor = (float)((*tds)->taille_actuelle) / (float)((*tds)->taille_max); //obtenir le résultat de la division en nombres flottants
    //printf("LOAD FACTOR : %f\n", load_factor);
    if(load_factor >= 0.75)
    {
        printf("REHASHING REQUIS\n");
        rehashing(tds);
        int indice = fonctionHash(nom, (*tds)->taille_max);
        noeud = get_symbole(*tds, nom);
    }*/
    
    return noeud;
}


struct noeud* insertion_tableau(struct tds** tds, char* nom, enum type type, int nombre_dimension, int taille_dimensions[MAX_DIMENSION_TABLEAU])
{
    int indice = fonctionHash(nom, (*tds)->taille_max);
    
    //info : il n'est pas nécessaire de regarder chaque entrée de la table des symboles pour vérifier si nom n'est pas déjà présent
    //       car la fonction de hash nous donnerait le même indice pour le même nom
    
    struct noeud* noeud = NULL;
    
    /*printf("Insertion tableau de dimension %d et les dimensions ont la taille : ", nombre_dimension);
    for(int i = 0; i < nombre_dimension; i++)
	{
		printf("Dim%d : %d ", i+1, taille_dimensions[i]);
	}
	printf("\n");*/
    
    
    //cas 1 : ajout dans une entrée vide
    if((*tds)->listes[indice] == NULL)
    {
        //printf("ENTREE %d VIDE : AJOUT DE %s DANS LA TABLE\n", indice, nom);
        
        //créer l'entrée
        NCHK(noeud = malloc(sizeof(struct noeud)));
        noeud->suivant = NULL;
        
        NCHK(noeud->info.nom = malloc(MAX_LONGUEUR_VARIABLE * sizeof(char)));
        snprintf(noeud->info.nom, MAX_LONGUEUR_VARIABLE, "%s", nom);
        noeud->info.sorte = SORTE_TABLEAU;
        noeud->info.type = type;
        noeud->info.valeur_entiere = 0;
        noeud->info.valeur_flottante = 0.0;
        noeud->info.tableau.nombre_dimension = nombre_dimension;
        
        if(nombre_dimension == 1)
        {
        	noeud->info.tableau.valeurs_entieres_tableau = calloc(taille_dimensions[0], sizeof(int)); 
       	noeud->info.tableau.valeurs_flottantes_tableau = calloc(taille_dimensions[0], sizeof(float)); 
        }
        else if(nombre_dimension == 2)
        {
        	noeud->info.tableau.valeurs_entieres_tableau = calloc(taille_dimensions[0] * taille_dimensions[1], sizeof(int)); //row major
        	noeud->info.tableau.valeurs_flottantes_tableau = calloc(taille_dimensions[0] * taille_dimensions[1], sizeof(float)); //row major
        }
        
        
        for(int i = 0; i < nombre_dimension; i++)
        {
        	noeud->info.tableau.taille_dimensions[i] = taille_dimensions[i];
        }
        
        (*tds)->listes[indice] = noeud;
        (*tds)->taille_actuelle += 1;
    }
    else //cas 2 : ajout dans une entrée non vide
    {
        //parcourir la liste chainée de l'entrée et regarder si la clef est déjà présente
        struct noeud* eventuel_noeud = get_elem((*tds)->listes[indice], nom);
        
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
            NCHK(noeud = malloc(sizeof(struct noeud)));
            noeud->suivant = NULL;
            NCHK(noeud->info.nom = malloc(MAX_LONGUEUR_VARIABLE * sizeof(char)));
            snprintf(noeud->info.nom, MAX_LONGUEUR_VARIABLE, "%s", nom);
            noeud->info.sorte = SORTE_TABLEAU;
            noeud->info.type = type;
		noeud->info.valeur_entiere = 0;
		noeud->info.valeur_flottante = 0.0;
		noeud->info.tableau.nombre_dimension = nombre_dimension;
		if(nombre_dimension == 1)
		{
			noeud->info.tableau.valeurs_entieres_tableau = calloc(taille_dimensions[0], sizeof(int)); 
			noeud->info.tableau.valeurs_flottantes_tableau = calloc(taille_dimensions[0], sizeof(float)); 
		}
		else if(nombre_dimension == 2)
		{
			noeud->info.tableau.valeurs_entieres_tableau = calloc(taille_dimensions[0] * taille_dimensions[1], sizeof(int)); //row major
			noeud->info.tableau.valeurs_flottantes_tableau = calloc(taille_dimensions[0] * taille_dimensions[1], sizeof(float)); //row major
		}
        
		for(int i = 0; i < nombre_dimension; i++)
		{
			noeud->info.tableau.taille_dimensions[i] = taille_dimensions[i];
		}
            
            (*tds)->listes[indice] = ajout_queue((*tds)->listes[indice], noeud);
            (*tds)->taille_actuelle += 1;
        }
    }
    
    /*float load_factor = (float)((*tds)->taille_actuelle) / (float)((*tds)->taille_max); //obtenir le résultat de la division en nombres flottants
    //printf("LOAD FACTOR : %f\n", load_factor);
    if(load_factor >= 0.75)
    {
        printf("REHASHING REQUIS\n");
        rehashing(tds);
        int indice = fonctionHash(nom, (*tds)->taille_max);
        noeud = get_symbole(*tds, nom);
    }*/
    
    return noeud;
}


struct noeud* insertion_matrix(struct tds** tds, char* nom, int nombre_dimension, int taille_dimensions[MAX_DIMENSION_TABLEAU])
{
    int indice = fonctionHash(nom, (*tds)->taille_max);
    
    //info : il n'est pas nécessaire de regarder chaque entrée de la table des symboles pour vérifier si nom n'est pas déjà présent
    //       car la fonction de hash nous donnerait le même indice pour le même nom
    
    struct noeud* noeud = NULL;
    
    /*printf("Insertion tableau de dimension %d et les dimensions ont la taille : ", nombre_dimension);
    for(int i = 0; i < nombre_dimension; i++)
	{
		printf("Dim%d : %d ", i+1, taille_dimensions[i]);
	}
	printf("\n");*/
    
    
    //cas 1 : ajout dans une entrée vide
    if((*tds)->listes[indice] == NULL)
    {
        //printf("ENTREE %d VIDE : AJOUT DE %s DANS LA TABLE\n", indice, nom);
        
        //créer l'entrée
        NCHK(noeud = malloc(sizeof(struct noeud)));
        noeud->suivant = NULL;
        
        NCHK(noeud->info.nom = malloc(MAX_LONGUEUR_VARIABLE * sizeof(char)));
        snprintf(noeud->info.nom, MAX_LONGUEUR_VARIABLE, "%s", nom);
        noeud->info.sorte = SORTE_TABLEAU;
        noeud->info.type = TYPE_MATRIX;
        noeud->info.valeur_entiere = 0;
        noeud->info.valeur_flottante = 0.0;
        noeud->info.tableau.nombre_dimension = nombre_dimension;
        noeud->info.tableau.is_matrix = true;
        
        if(nombre_dimension == 1)
        {
        	noeud->info.tableau.valeurs_entieres_tableau = calloc(taille_dimensions[0], sizeof(int)); 
       	noeud->info.tableau.valeurs_flottantes_tableau = calloc(taille_dimensions[0], sizeof(float)); 
        }
        else if(nombre_dimension == 2)
        {
        	noeud->info.tableau.valeurs_entieres_tableau = calloc(taille_dimensions[0] * taille_dimensions[1], sizeof(int)); //row major
        	noeud->info.tableau.valeurs_flottantes_tableau = calloc(taille_dimensions[0] * taille_dimensions[1], sizeof(float)); //row major
        }
        
        
        for(int i = 0; i < nombre_dimension; i++)
        {
        	noeud->info.tableau.taille_dimensions[i] = taille_dimensions[i];
        }
        
        (*tds)->listes[indice] = noeud;
        (*tds)->taille_actuelle += 1;
    }
    else //cas 2 : ajout dans une entrée non vide
    {
        //parcourir la liste chainée de l'entrée et regarder si la clef est déjà présente
        struct noeud* eventuel_noeud = get_elem((*tds)->listes[indice], nom);
        
        if(eventuel_noeud != NULL) //différent de NULL => noeud trouvé
        {
            //printf("NOM : %s DEJA PRESENT A l'ENTREE %d, MISE A JOUR !\n", nom, indice);
            
            //le modifier
            eventuel_noeud->info.type = TYPE_MATRIX;
        }
        else
        {
            //printf("PAS PRESENT : AJOUT DE %s DANS LA TABLE A L'ENTREE %d\n", nom, indice);
            
            //créer l'entrée
            NCHK(noeud = malloc(sizeof(struct noeud)));
            noeud->suivant = NULL;
            NCHK(noeud->info.nom = malloc(MAX_LONGUEUR_VARIABLE * sizeof(char)));
            snprintf(noeud->info.nom, MAX_LONGUEUR_VARIABLE, "%s", nom);
            noeud->info.sorte = SORTE_TABLEAU;
            noeud->info.type = TYPE_MATRIX;
		noeud->info.valeur_entiere = 0;
		noeud->info.valeur_flottante = 0.0;
		noeud->info.tableau.nombre_dimension = nombre_dimension;
		noeud->info.tableau.is_matrix = true;
		
		if(nombre_dimension == 1)
		{
			noeud->info.tableau.valeurs_entieres_tableau = calloc(taille_dimensions[0], sizeof(int)); 
			noeud->info.tableau.valeurs_flottantes_tableau = calloc(taille_dimensions[0], sizeof(float)); 
		}
		else if(nombre_dimension == 2)
		{
			noeud->info.tableau.valeurs_entieres_tableau = calloc(taille_dimensions[0] * taille_dimensions[1], sizeof(int)); //row major
			noeud->info.tableau.valeurs_flottantes_tableau = calloc(taille_dimensions[0] * taille_dimensions[1], sizeof(float)); //row major
		}
        
		for(int i = 0; i < nombre_dimension; i++)
		{
			noeud->info.tableau.taille_dimensions[i] = taille_dimensions[i];
		}
            
            (*tds)->listes[indice] = ajout_queue((*tds)->listes[indice], noeud);
            (*tds)->taille_actuelle += 1;
        }
    }
    
    /*float load_factor = (float)((*tds)->taille_actuelle) / (float)((*tds)->taille_max); //obtenir le résultat de la division en nombres flottants
    //printf("LOAD FACTOR : %f\n", load_factor);
    if(load_factor >= 0.75)
    {
        printf("REHASHING REQUIS\n");
        rehashing(tds);
        int indice = fonctionHash(nom, (*tds)->taille_max);
        noeud = get_symbole(*tds, nom);
    }*/
    
    return noeud;
}


struct noeud* insertion_constante(struct tds** tds, enum type type, float valeur) //float pour gérer float et int
{
    static int compteur = 0; //pour le nom des constantes : 'constante x' avec 'x' = compteur
    
    char* nom;
    NCHK(nom = malloc(MAX_LONGUEUR_VARIABLE * sizeof(char)));
    snprintf(nom, MAX_LONGUEUR_VARIABLE, "constante_%d", compteur);
    
    int indice = fonctionHash(nom, (*tds)->taille_max);
    
    //info : il n'est pas nécessaire de regarder chaque entrée de la table des symboles pour vérifier si nom n'est pas déjà présent
    //       car la fonction de hash nous donnerait le même indice pour le même nom
    
    struct noeud* noeud;
    
    //cas 1 : ajout dans une entrée vide
    if((*tds)->listes[indice] == NULL)
    {
        //printf("ENTREE %d VIDE : AJOUT DE %s DANS LA TABLE\n", indice, nom);
        
        //créer l'entrée
        NCHK(noeud = malloc(sizeof(struct noeud)));
        noeud->suivant = NULL;
        
        noeud->info.nom = nom;
        noeud->info.sorte = SORTE_CONSTANTE;
        noeud->info.type = type;
        
        if(type == TYPE_INT)
        {
        	noeud->info.valeur_entiere = valeur;
        }
        else if(type == TYPE_FLOAT)
        {
        	noeud->info.valeur_flottante = valeur;
        }
        
        (*tds)->listes[indice] = noeud;
        (*tds)->taille_actuelle += 1;
        
        compteur += 1;
    }
    else //cas 2 : ajout dans une entrée non vide
    {
        //parcourir la liste chainée de l'entrée et regarder si la clef est déjà présente
        struct noeud* eventuel_noeud = get_elem((*tds)->listes[indice], nom);
        
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
            NCHK(noeud = malloc(sizeof(struct noeud)));
            noeud->suivant = NULL;
            noeud->info.nom = nom;
            noeud->info.sorte = SORTE_CONSTANTE;
            noeud->info.type = type;
            
        if(type == TYPE_INT)
        {
        	noeud->info.valeur_entiere = valeur;
        }
        else if(type == TYPE_FLOAT)
        {
        	noeud->info.valeur_flottante = valeur;
        }
            
            (*tds)->listes[indice] = ajout_queue((*tds)->listes[indice], noeud);
            (*tds)->taille_actuelle += 1;
            
            compteur += 1;
        }
    }
    
	float load_factor = (float)((*tds)->taille_actuelle) / (float)((*tds)->taille_max); //obtenir le résultat de la division en nombres flottants
    //printf("LOAD FACTOR : %f\n", load_factor);
    /*if(load_factor >= 0.75)
    {
	printf("REHASHING REQUIS\n");
	rehashing(tds);
	int indice = fonctionHash(nom, (*tds)->taille_max);
	noeud = get_symbole(*tds, nom);
    }*/
    
    return noeud;
}



struct noeud* insertion_constante_str(struct tds** tds, enum type type, char valeur[MAX_LONGUEUR_VARIABLE]) 
{
    static int compteur_str = 0; //pour le nom des constantes : 'constante x' avec 'x' = compteur
    
    char* nom;
    NCHK(nom = malloc(MAX_LONGUEUR_VARIABLE * sizeof(char)));
    snprintf(nom, MAX_LONGUEUR_VARIABLE, "constante_str_%d", compteur_str);
    
    int indice = fonctionHash(nom, (*tds)->taille_max);
    
    //info : il n'est pas nécessaire de regarder chaque entrée de la table des symboles pour vérifier si nom n'est pas déjà présent
    //       car la fonction de hash nous donnerait le même indice pour le même nom
    
    struct noeud* noeud;
    
    //cas 1 : ajout dans une entrée vide
    if((*tds)->listes[indice] == NULL)
    {
        //printf("ENTREE %d VIDE : AJOUT DE %s DANS LA TABLE\n", indice, nom);
        
        //créer l'entrée
        NCHK(noeud = malloc(sizeof(struct noeud)));
        noeud->suivant = NULL;
        
        noeud->info.nom = nom;
        noeud->info.sorte = SORTE_CONSTANTE;
        noeud->info.type = type;
	
	NCHK(noeud->info.valeur_str = malloc(MAX_LONGUEUR_VARIABLE * sizeof(char)));
        snprintf(noeud->info.valeur_str, MAX_LONGUEUR_VARIABLE, "%s", valeur);

        (*tds)->listes[indice] = noeud;
        (*tds)->taille_actuelle += 1;
        
        compteur_str += 1;
    }
    else //cas 2 : ajout dans une entrée non vide
    {
        //parcourir la liste chainée de l'entrée et regarder si la clef est déjà présente
        struct noeud* eventuel_noeud = get_elem((*tds)->listes[indice], nom);
        
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
            NCHK(noeud = malloc(sizeof(struct noeud)));
            noeud->suivant = NULL;
            noeud->info.nom = nom;
            noeud->info.sorte = SORTE_CONSTANTE;
            noeud->info.type = type;
            
        NCHK(noeud->info.valeur_str = malloc(MAX_LONGUEUR_VARIABLE * sizeof(char)));
        
        snprintf(noeud->info.valeur_str, MAX_LONGUEUR_VARIABLE, "%s", valeur);
            
            (*tds)->listes[indice] = ajout_queue((*tds)->listes[indice], noeud);
            (*tds)->taille_actuelle += 1;
            
            compteur_str += 1;
        }
    }
    
	float load_factor = (float)((*tds)->taille_actuelle) / (float)((*tds)->taille_max); //obtenir le résultat de la division en nombres flottants
    //printf("LOAD FACTOR : %f\n", load_factor);
    /*if(load_factor >= 0.75)
    {
	printf("REHASHING REQUIS\n");
	rehashing(tds);
	int indice = fonctionHash(nom, (*tds)->taille_max);
	noeud = get_symbole(*tds, nom);
    }*/
    
    return noeud;
}




struct noeud* get_symbole_constante(struct tds* tds, float valeur)
{
    for(int i = 0; i < tds->taille_max; i++) //parcourir chaque ligne de la tds
    {
        for(struct noeud* noeud = tds->listes[i]; noeud != NULL; noeud = noeud->suivant) //parcourir chaque liste chainee de chaque ligne
        {
            if(noeud->info.sorte == SORTE_CONSTANTE)
            {
		    if(noeud->info.type == TYPE_FLOAT && noeud->info.valeur_flottante == valeur) //noeud trouvé
		    {
		        //printf("Entrée %d non-vide : nom %s présent\n", indice, nom);
		        return noeud; //noeud = noeud ayant la valeur "valeur"
		    }
	    }
        }
    }
    return NULL; //aucune case avec la valeur en paramètre
}

struct noeud* get_symbole_constante_int(struct tds* tds, int valeur)
{
    for(int i = 0; i < tds->taille_max; i++) //parcourir chaque ligne de la tds
    {
        for(struct noeud* noeud = tds->listes[i]; noeud != NULL; noeud = noeud->suivant) //parcourir chaque liste chainee de chaque ligne
        {
            if(noeud->info.sorte == SORTE_CONSTANTE)
            {
		    if(noeud->info.type == TYPE_INT && noeud->info.valeur_entiere == valeur) //noeud trouvé
		    {
		        //printf("Entrée %d non-vide : nom %s présent\n", indice, nom);
		        return noeud; //noeud = noeud ayant la valeur "valeur"
		    }
	    }
        }
    }
    return NULL; //aucune case avec la valeur en paramètre
}


struct noeud* get_symbole_constante_str(struct tds* tds, char valeur[MAX_LONGUEUR_VARIABLE])
{
    for(int i = 0; i < tds->taille_max; i++) //parcourir chaque ligne de la tds
    {
        for(struct noeud* noeud = tds->listes[i]; noeud != NULL; noeud = noeud->suivant) //parcourir chaque liste chainee de chaque ligne
        {
            if(noeud->info.sorte == SORTE_CONSTANTE)
            {
		    if(noeud->info.type == TYPE_STR && strcmp(noeud->info.valeur_str, valeur) == 0) //noeud trouvé
		    {
		        //printf("Entrée %d non-vide : nom %s présent\n", indice, nom);
		        return noeud; //noeud = noeud ayant la valeur "valeur"
		    }
	    }
        }
    }
    return NULL; //aucune case avec la valeur en paramètre
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


struct noeud* get_symbole(struct tds* tds, char* nom)
{
    int indice = fonctionHash(nom, tds->taille_max); //trouver l'entrée
    
    if(tds->listes[indice] == NULL) //entrée vide
    {
        //printf("Entrée %d vide : nom %s non présent\n", indice, nom);
        return NULL;
    }
    else //entrée non-vide, chercher dans la liste chaînée
    {
        for(struct noeud* noeud = tds->listes[indice]; noeud != NULL; noeud = noeud->suivant)
        {
            if(strcmp(noeud->info.nom, nom) == 0) //si un noeud de la liste contient ce nom
            {
                //printf("Entrée %d non-vide : nom %s présent\n", indice, nom);
                return noeud; //noeud = noeud ayant le nom "nom"
            }
        }
    }
 
    return NULL; //cas entrée non vide mais clef non présent
}


//ajoute une variable temporaire tx dans la tds et retourne l'entrée dans la tds stockant cette variable
struct noeud* newtemp(struct tds** tds, enum type type)
{
	char nom[MAX_LONGUEUR_VARIABLE];

	static int num_temp = 0;
	snprintf(nom, MAX_LONGUEUR_VARIABLE, "t%d", num_temp); //obtenir "tx" avec x le numéro de la var temp
	num_temp += 1;
	 
	return insertion(tds, nom, SORTE_VARIABLE, type); //type float pour la compatibilité ? Ou meilleur solution ?
}


struct noeud* newtempMatrix(struct tds** tds, int nombre_dimension, int taille_dimensions[MAX_DIMENSION_TABLEAU])
{
	char nom[MAX_LONGUEUR_VARIABLE];

	static int num_temp_matrix = 0;
	snprintf(nom, MAX_LONGUEUR_VARIABLE, "t_matrix%d", num_temp_matrix); //obtenir "t_matrixx" avec x le numéro de la var temp
	num_temp_matrix += 1;
	
	return insertion_matrix(tds, nom, nombre_dimension, taille_dimensions);
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
    if(sorte == SORTE_VARIABLE)
        return "SORTE_VARIABLE";
    else if(sorte == SORTE_CONSTANTE)
        return "SORTE_CONSTANTE";
    else if(sorte == SORTE_TABLEAU)
        return "SORTE_TABLEAU";
    else return "SORTE_NONE";
}

//utile pour affichage_tds()
char* parser_enum_type(enum type type)
{
    if(type == TYPE_INT)
        return "INT";
    else if(type == TYPE_FLOAT)
        return "FLOAT";
    else if(type == TYPE_STR)
        return "STR";
    else if(type == TYPE_MATRIX)
    	return "MATRIX";
    else if(type == TYPE_ERROR)
    	return "ERROR";
    else return "NONE";
}

void affichage_symbole(struct noeud* noeud)
{
	if(noeud != NULL)
	{
		//printf("NOEUD : %s et %d\n", noeud->info.nom, noeud->info.sorte);
		if(noeud->info.sorte == SORTE_CONSTANTE)
		{
			if(noeud->info.type == TYPE_INT)
				printf("%d", noeud->info.valeur_entiere);
			else if(noeud->info.type == TYPE_FLOAT)
				printf("%f", noeud->info.valeur_flottante);
			else if(noeud->info.type == TYPE_STR)
				printf("%s", noeud->info.valeur_str);
		}
		else
		{
			printf("$%s", noeud->info.nom);
		}
	}
}

void affichage_tds(struct tds* tds)
{
    struct noeud* temp;
    printf("\n");
    printf("\t\t\tTable des symboles\n");
    printf("/////////////////////////////////////////////////////////////////////////\n");
    for(int i = 0; i < tds->taille_max; i++) 
	{
	    temp = tds->listes[i];
	    if(temp != NULL)
	    	printf("Entrée %d : ", i);
	    while(temp != NULL) 
	    {
	    	if(temp->info.sorte == SORTE_CONSTANTE)
	    	{
	    		if(temp->info.type == TYPE_INT)
	    			printf("|%s, %s, %s, %d|->", temp->info.nom, parser_enum_sorte(temp->info.sorte), parser_enum_type(temp->info.type), temp->info.valeur_entiere);
        		else if(temp->info.type == TYPE_FLOAT)
				    printf("|%s, %s, %s, %f|->", temp->info.nom, parser_enum_sorte(temp->info.sorte), parser_enum_type(temp->info.type), temp->info.valeur_flottante);
			else if(temp->info.type == TYPE_STR)
					printf("|%s, %s, %s, %s|->", temp->info.nom, parser_enum_sorte(temp->info.sorte), parser_enum_type(temp->info.type), temp->info.valeur_str);
	    	}
	    	else if(temp->info.sorte == SORTE_VARIABLE)
	        	printf("|%s, %s, %s|->", temp->info.nom, parser_enum_sorte(temp->info.sorte), parser_enum_type(temp->info.type));
	        else
	        {
	        	if(temp->info.tableau.is_matrix == true)
	        		printf("|%s, %s, %s, MATRIX|->", temp->info.nom, parser_enum_sorte(temp->info.sorte), parser_enum_type(temp->info.type));
	        	else printf("|%s, %s, %s, TABLEAU CLASSIQUE|->", temp->info.nom, parser_enum_sorte(temp->info.sorte), parser_enum_type(temp->info.type));
	        }
	        temp = temp->suivant;
	        printf("\n");
	    }
	    
	}
	printf("/////////////////////////////////////////////////////////////////////////\n\n");
}
