# GoCho : Analyses pour un article sur les goûts et le chômage

Projet réalisé par Marie Plessz.

Projet d'article basé sur le chapitre 6 de mon HDR [https://hal.inrae.fr/tel-03436087v1] .

Données Constances extraites le 24/07/2020. Les données ne peuvent pas être publiées.

## Objectif 

Analyse prospective : 

- évolution des consommations (alimentation, boissons, tabac) 
- corpulence pour les pers qui perdent leur emploi comparées aux personnes qui restent en emploi

### différences avec chapitre d'HDR : 

- pas d'analyse sur les chômeurs à l'inclusion
- pas santé et obésité

## Principes généraux d'organisation

J'ai utilise R et Stata version 15. Dans R j'utilise `Renv` pour sauver les packages 
utilisés à la date du travail.

Les fichiers en `00_` créent les liens vers le dossier contenant les données source (si nécessaire)
et les macro stata qui contiennent les chemins vers les dossiers.

Les programmes R sont dans le dossier racine.

Les programmes stata sont dans 2 sous-dossiers : 
- `1-Do-Generique` contient les recodages des données d'inclusion que j'utilise pour bcp de projets sur Constances
- `2-Do` contient les préparations de données et analyses spécifiques à ce projet.

Tous les résultats sont dans le dossier `Resultats`, sauf s'il s'agit de tableaux html produits dans un `Rmd`avec `knitr` (par exemple les tableaux produits avec `gtsummary`).

Les fichiers produits par un programme portent un nom numéroté d'après le programme, voire les deux noms sont identiques.
Pour cela je définis souvent au début du programme un `tag' qui est une macro locale (dans stata) ou un objet (dans R) contenant le nom du programme.

## Les grandes étapes

- préparation des données : Stata (1-Do-Generique et 2-Do/ jusqu'au N° 4)
- Flowchart pour l'analyse prospective : R (N°5) d'après les effectifs calculés dans Stata (4).
- Stats descriptives prospectives : R (5b et 6)
- Appariement : Stata (5)
- modèles en Double différence, graphes des effets marginaux : Stata (6)