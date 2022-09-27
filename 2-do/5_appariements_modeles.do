/*---------------------------------------------------------------------------*/
*	Marie Plessz
*	2021-02-01
*	projet : HDR6
*	tache : 
*		appariement par CEM
*		modèles
*---------------------------------------------------------------------------*/

/*NB sur les choix pour l'appariement
- j'ai ajouté santé perçue : en 2 gp (<7 vs 7-8). ya pas de solution équilibrée en 3 gp)
- du coup pour sauver un peu la taille d'échantillon, j'ai  
	coarsened education : en 3 niveaux (regrouper les 2 plus bas) au lieu de 4
- avecenf et tuu en 1 seul gp comme avant
- pour les vars continues : apparier sur la var ordonnée (bla_o_inc).
- la façon dont j'ai codé cemcsp permet de la garder dans le tableau 
de dissimilarité mais voir commentaire plus bas

pour les tranches (il faut choisir une valeur qui est "entre" 2 variables par ex : 4.5 est entre 4 et 5

- la cigarette est appariée séparément car il faut aussi apparier différemnt les gens qui 
ont déjà fumé ou jamais fumé parmi les non-fumeurs à l'inclusion.

*/


local tag "5_appariements_modeles"

*=================	Derniers recodages 	============================*

use  "$cree/HDR6_04_prosp_studypop.dta", clear

* corriger la variable santé ordonnée pour appariement
recode san_o_inc (5 = 4)
recode san_o_sui (5 = 4)


* préparer les variables qui vont devoir subir reshape_long
rename emploi_inc  emploi0
rename emploi_sui  emploi1

*renommer santé pour que reste dans fichier
gen santepercu =  san_c_inc 
* vérifier que pas de manquante
assert (santepercu !=.)

* pour le cem il faut des variables dans le bonne ordre
recode cspvol (3 = 0) (6 = 6), gen(cemcsp)

gen cemaq = 0
replace cemaq = 1 if aq_modvie_refdoc == "I3"

* ==== > fichier qu'on va utiliser

save "$cree/HDR6_05_prosp_pourcem.dta", replace

*=================	MACROS pour les appariements	========================*

* rappel :  vars de contrôle pour modèles
global  rhs "homme i.age_cl aveccouple01 avecenf01  astopcho  diffinnow prive  i.edu santepercu i.cspvol i.y  i.tuu2012_cl "

* vars pour l'appariement, avec leur grouping (les modifiées à la fin)
global cemvars "homme(#0) age_cl(#0) aveccouple01(#0) avecenf01(#1) tuu2012_cl(#1) astopcho(#0)  diffinnow(#0) prive(#0) edu(#3) santepercu(6.5) cemcsp( 2 4.5) cemaq(#0)"

* vars de l'appariement sans grouping pour vérif de l'imbalance
global imbvars "homme age_cl aveccouple01 avecenf01 tuu2012_cl astopcho  diffinnow prive edu santepercu cemcsp cemaq"
/* NB : la commande "imb" avec la liste de vars non groupées permet de voir l'imbalance
	qui reste après appariement. PB les vars sont toutes traitées comme si continues 
	donc l'imbalance n'est pas très utile */

eststo clear

********* Début de la boucle ************
	
foreach stub in  leg_o poi_o vro_o fas_o  sod_o alc_o bmi_o san_o  { 
	di as result "------ `stub' - début ------" 
	use  "$cree/HDR6_05_prosp_pourcem.dta", clear

	* rename les données pour une var dep
	rename `stub'_inc dep0
	rename `stub'_sui dep1

	* enlever les données manquantes (sinon cem les apparie)
	drop if dep0 == . | dep1 == .
	count

	* appariement
	*imb  dep0 $imbvars, treatment(traitt)
	cem  dep0(#0) $cemvars, treatment(traitt) showbreaks
	
	* sauver les données appariées pour cette var
	label data "données appariées sur `stub'"
	save  "$temp/t_05_cem_`stub'.dta", replace

*/	
}

************ Fin de la boucle ************

*==================== TABAC  ====================*
* pour le tabac il faut apparier sur le statut tabagique à l'inclusion

	use  "$cree/HDR6_05_prosp_pourcem.dta", clear

	* rename les données pour une var dep
	rename fum_o_inc dep0
	rename fum_o_sui dep1

	* enlever les données manquantes (sinon cem les apparie)
	drop if dep0 == . | dep1 == .
	count

	gen depcem = dep0
	replace depcem = -1 if fum_control_inc ==0
	
	* appariement
	*imb  dep0 $imbvars, treatment(traitt)
	cem  depcem (#0) $cemvars, treatment(traitt) showbreaks
	
	* sauver les données appariées pour cette var
	label data "données appariées sur fum_o + jamais fumé"
	save  "$temp/t_05_cem_fum_o.dta", replace

	