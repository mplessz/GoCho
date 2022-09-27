

/*---------------------------------------------------------------------------------*/
*	Marie Plessz
*	06/11/2018
*	dofile: dm01_extrait
*	projet : CMP
/*	tache : 
copie utilisable des fichiers utiles dans $cree
-les fichiers ont été transformés en unicode par statransfer (dans les options)
-description des fichiers sauvée dans un log
-pour chaque fichier, 
	-mettre les noms des vars en minuscules
	-supprimer les vars originales quand existe recodée
		j'ai fait une belle boucle qui sert pas à grand chose...
		mais qui est belle
	-compress, sort	
	-sauve dans cree
	
*2020-10-07 : pas de fichier EXPOCAR donc les lignes correspondantes sont mises en commentaire
	
*/
/*---------------------------------------------------------------------------------*/
set more off


local tag "dm01_extrait"
local extdate "2020-07-24"

/*--------------------- C/ décrire les fichiers extraits  -------------------*/
cap log close
log  using "$res/`tag'", replace text	
set linesize 250
	//	DATA_POP
use "$source\DATA_POP", clear
describe, fullnames
	//	MDV
use "$source\DATA_MDV", clear
describe, fullnames
	//	INDGEO
use "$source\DATA_INDGEO", clear
describe, fullnames
	//	EXPO
use "$source\DATA_EXPO", clear
describe, fullnames

/* ==> pas de fichier expocar dans cette extraction
	//	EXPOCAR
use "$source\DATA_EXPOCAR", clear
describe, fullnames
*/

	//	PARACLIN
use "$source\DATA_PARACLIN", clear
describe, fullnames
	// DATA_CP_PER
use "$source\DATA_CPPER", clear
describe, fullnames
log off


	//	ENLEVER LES VARS originales quand il en existe une version nettoyée
* pour l'instant seul MDV contient des vars nettoyées.

use "$source\DATA_MDV", clear
rename *, lower 
describe, short 
local avant = r(k)		//stocke nb vars avant
local i=0				//compteur vars supprimees

//supprimer les vars qui existent en version nettoyée
cap ds *_n
local t=r(varlist)	// verifier qu'il y a bien des vars à nettoyer
display " var à sup : `t'"
if "`t'"!="." {
	foreach var of varlist *_n {
		local ++i
		*display "`var'"
		local v=reverse(substr(reverse("`var'"), 3,.))	//nom sans le _n
		display "`v'"
		drop `v'
	} 
}	
describe, short 	//nv fichier, ou identique si pas nettoyage
display  "NB var apres: `r(k)'"
display  "NB var supprimees: `i'"
display  "NB var avant: `avant'"

//	transformer en numériques les vars sur l'alcool
*rename aq_comport_alc* alc*
encode aq_comport_alcrecommandation_i , gen(alcreco)
label var alcreco "Alcool: Recommandation selon la conso/j"
note alcreco:encode aq_comport_alcrecommandation_i . `tag'

encode  aq_comport_alcclasseaudit_i , gen(alcaudit)	
label var alcaudit "Alcool: Classe Score AUDIT"
note alcaudit:encode aq_comport_alcclasseaudit_i . `tag'

clonevar alcvj=aq_comport_alcconsojour_i
note alcvj: clonevar alcvj=aq_comport_alcconsojour_i. `tag'

// enlever les questions demandées par PM et dont je n'ai pas besoin
cap drop aq_diabete_*
cap drop aq_handicap_*
cap drop aq_vietrav_*
cap drop aq_tmsq_*
cap drop aq_comport_alc*	

sort proj_isp 
quietly compress
note _dta: MDV. j'ai suppr les vars originales qd existe var ///
	nettoyée.`tag'.
	

save "$cree/DATA_MDV_01", replace 	// sauve dans cree/
cap log off



*=====> autres fichiers : sort, compress
	//	DATA_POP
use "$source\DATA_POP", clear
rename *, lower 
*destring , replace
sort proj_isp 
compress
note _dta: donnees extraites le `extdate'. destring. `tag'.
save "$cree/DATA_POP_01", replace 

	//	DATA_INDGEO
use "$source\DATA_INDGEO", clear
rename *, lower 
*destring , replace
sort proj_isp 
compress
note _dta: donnees extraites le `extdate'. destring. `tag'.
save "$cree/DATA_INDGEO_01", replace 

	//	EXPO
use "$source\DATA_EXPO", clear
rename *, lower 
*destring , replace
sort proj_isp 
compress
note _dta: donnees extraites le `extdate'. destring. `tag'.
save "$cree/DATA_EXPO_01", replace 

/*
	//	EXPOCAR
use "$source\DATA_EXPOCAR", clear
rename *, lower 
*destring , replace
sort proj_isp 
compress
note _dta: donnees extraites le `extdate'. destring. `tag'.
save "$cree/DATA_EXPOCAR_01", replace 
*/

	//	PARACLINQ (pour BMI)
use "$source\DATA_PARACLIN", clear
rename *, lower 
*destring , replace
sort proj_isp 
compress
note _dta: donnees extraites le `extdate'. destring. `tag'.
save "$cree/DATA_PARACLIN_01", replace 

	// DATA_CP
use "$source\DATA_CP", clear
rename *, lower 
*destring , replace
sort proj_isp 
compress
note _dta: donnees extraites le `extdate'. destring. `tag'.
save "$cree/DATA_CP", replace 
	
	// DATA_CP_PER
use "$source\DATA_CPPER", clear
rename *, lower 
*destring , replace
sort proj_isp 
compress
local extdate "2020-07-24"
note _dta: donnees extraites le `extdate'. destring. `tag'.
save "$cree/DATA_CPPER", replace 

log close
 exit
 

