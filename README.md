# Les pays en chiffre
## Description
Ce programme permet d'intégrer dans une table un référentiel de villes et d'effectuer des opérations dessus:

* Une fonction permet de retrouver une ville d'après son nom.

* Une procédure permet de créer une ville à partir d'un nom.

* Une fonction groupe les villes par densité

* La date d'insertion d'une ville en base de donnée est automatique.
## Pré-requis
Un instance de base **PostgresSql** est nécessaire, avec un schéma vide (ou non concurrent aux objets qui vont être crées). L'utilisateur de la table doit avoir les droits de lecture et écriture sur celle-ci.

Télécharger le repo du projet sur votre ordinateur. Celui-ci doit contenir les fichiers suivants : 

* _schema_initialisation.sql_
* _generate_data.sql_
* _test_data.sql_
* _Referential_generator.xlsx_
* _README.md_

Afin d'exécuter les scripts DDL de la solution, il est préconisé d'utiliser un outils de développement adapté : 
[Clients PostgreSQL](https://wiki.postgresql.org/wiki/PostgreSQL_Clients)


## Installation

**Initialisation de l'instance**

* Exécuter le fichier _schema_initialisation.sql_ pour effectuer les opérations suivantes :
     * suppression des objets liés au projet existant
     * création de la table _country_
     * création des fonctions de génération de nombre aléatoire _random_between, random_between_int, random_between_dec_
     * création de la procédure _insert_random_country_
     * création de la fonction _get_country_by_name_
     * création de la fonction _set_creation_date_ et du trigger _trigg_set_date_
     * création de la fonction _get_countries_by_density_

* Exécuter le fichier _generate_data.sql_.
     *Ce fichier intègre le référentiel des villes dans la table _country_


## Utilisation
Exemple d'instructions

**>Affichage du contenu de la table des pays:**
```sql
SELECT * FROM country
```

**>Récupérer les informations d'un pays par son nom, sous forme de table:**

_'china'= nom du pays recherché_

```sql
SELECT * FROM GetCountryByName('china');
```

**>Générer un nouveau pays:**

_'TomorrowLand'= nom du pays créé_
```sql
CALL InsertRandomCountry('TomorrowLand');
```

**>Récupérer la date de création d'un pays:**

_'TomorrowLand'= nom du pays recherché_
```sql
SELECT name, insertion_date FROM GetCountryByName('TomorrowLand');
```

**>Récupérer la liste des pays groupés par densité:**

_La fonction récupère les pays groupés selon 4 niveaux de densité._

_'100,200,400'= seuils des différents groupes:_

* _groupe 1 : inférieur ou égal à 100 (inclus)_
* _groupe 2 : supérieur à 100 et inférieur ou égal à 200 (inclus)_
* _groupe 3 : supérieur à 200 et inférieur ou égal à 400 (inclus)_
* _groupe 4 : supérieur à 400 (inclus)_

```sql
SELECT * FROM get_countries_by_density(100,200,400);
```

## Maintenance du référentiel
En cas de modification du référentiel source:
* Ouvrir le fichier _Referential_generator.xlsx_.
* Dans l'onglet 1 **'data'**, copier le contenu du référentiel.

   _Le nouveau référentiel doit contenir un header, le même nombre de colonne et le même nombre de ligne (v1)_
* L'onglet 2 **'prepare'** contient les données préparées
* L'onglet 3 **'generate'** contient le code SQL pour l'insertion du référentiel en base




# Donate
Plize argent si vou plé argent pour bébé

[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://img.pngio.com/joke-png-9-png-image-joke-png-1024_934.png)
