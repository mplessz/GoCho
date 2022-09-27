# Journal du projet HDR6

author : Marie Plessz
Date : 2020-10-16

# Objectif

Analyser les pratiques de consommation (alimentation, tabac, boissons) des personnes qui perdent leur emploi dans Constances

Pour le chapitre 6 de mon HDR

S'appuie sur le projet CALICO, sur le travail de Sehar

Utilise les données Constances

Du stata, et du R...

Et Github sur le Gitlab INRAE
[https://al-dev.versailles-grignon.inra.fr/]

# Organisation des fichiers

## 2020-HDR6 sur mon disque dur d'ordi

Dossier parent du projet.
Contient .Rproj et .git.

## Données

Les données sont sur le disque dur crypté auquel il faut faire correspondre la lettre K:

Un raccourci (symbolic link) pointe vers le dossier Data du lecteur K. Pour le créer 
sur un nouveau poste il faut re-créer le raccourci avec le fichier `0_LinkToData.r`

Tous les fichiers de données vont dans ce dossier pour que les données ne soient stockées que sur le DD externe crypté.

### Données : version 

Au 2020-10-16 je travaille avec l'extraction réalisée le 2020-07-24.

## 1-Do-generique

Mes recodages classiques sur les fichiers Constances à l'inclusion.

finit par un gros merge, garde toutes les variables, y a plus qu'à sélectionner les variables et individus utiles pour chaque (sous) projet.

## 2-do

Préparation sous Stata des fichiers pour l'ACM sur les chômeurs à l'inclusion : 


* recodages spécifiques
* selection variables

==> fichier `HDR6_01_tous.dta`

* selection population
* statistiques descriptives sur les pers en emploi et chômeurs, complets et manquants

==> fichier `HDR6_02_chomeurs.dta`
Actuellement j'ai 10 703 chômeurs

* statistiques descriptives sur les emploi/chomeurs et sur chomeurs complets/manquant

Pour montrer écart entre pers en emploi et chômeurs


## Les programmes R pour l'analyse sont dans le dossier racine
### nom commence par 

	- un chiffre : fichiers ppaux
	- explo : fichiers préparatoires, essais etc
	- helper : compléments tests de robustesse etc.

## analyses transversales à l'inclusion

**à l'inclusion je compare seult les caractéristiques des chô et pers en emploi. les consommations sont dans l'article publié dans _Appetite_.**
### 02-tableaux-descriptives
tableau de stats desc sur HDR6-1-tous. caractéristiques, pas conso

### 03-ACM-cluster
ACM sur les chômeurs à l'inclusion pour montrer la diversité de cette population

Classification HCPC (hierarchical classification on principal components).

Le package factominer utilise toutes les vars du tableau. Les identifiants Proj_ISP doivent être transformés en rawnames juste avant, puis redevenir une variable juste après.
 
 Je m'appuie sur un document fait par Anton Perdoncin  [https://quanti.hypotheses.org/1871](https://quanti.hypotheses.org/1871).
 
 J'ai remplacé `region` par la **`taille d'unité urbaine`**, plus parlante.
 
[x] Il faut traiter les non-réponses (au moins essayer)

** Rq : les résultats sont en partie dus au fait que les vars sociodémo sont actives **
** Rq : je n'ai pas discuté l'effet de l'imputation sur les résultats. pcq je ne sais pas exactement comment ça marche **

### 04-cluster-tableaux
[ ] tableaux descriptifs des clusters. à mettre en annexe du chapitre

## Prospectif
**J'adopte une perspective franchement théorie des pratiques et je laise de côté la perspective santé publique :**

- j'abandonne les notions de "risque" et les variables définies par les épidémios (comme la conso d'alcool non reco qui dépend du sexe).
- Je traite toutes mes vardeps comme des pratiques de consommation, 
les individus peuvent être pratiquants ou non, pratiquer plus ou moins intensément. 
- intensité de la pratique de consommation  = fréquence. mais fréquence est relative, une pratique "intense" n'est pas au même seuil selon la pratique concernée
- fumer des cigarettes n'est qu'une pratique de consommation du tabac parmi d'autres, 
(et il existe des pratiques "fumer" sans tabac). mais je n'entrerai pas dans les détails
- 
### dans stata, dossier 2-do

#### 2b_HDR6_t_depvar_inc
code les vars dépendantes à l'inclusion.
Nom systématique : finit par _inc
[ ] faire un tableau des vars avec leurs définitions

#### 2b_HDR6_t_depvar_sui
pareil sur le suivi 2017

#### 3_HDR6_03_prospectif
ajoute les 2 précédents à HDR6_01_tous
crée les vars de pratique intense

#### 4_HDR6_04_prosp_studypop
sélectionne la population pour l'analyse prospective et récupères les chiffres pour le flowchart

[ ] à mettre à jour en fonction des variables de CEM

### retour dans R

### 05-Flowchart
[ ] à mettre à jour avec les nvx chiffres

### 06- compare tableau
tableau de stats desc qui compare les caractéristiques à l'inclusion en fonction du statut en 2017.
seult les caractéristiques, pas les pratiques à ce stade.

### évolution des pratiques

### CEM

### modèles


