local tag "dm04b_paraclin_v2"

/*----------------------------------------------------------------------------*/
*	Marie Plessz
*	19/10/2017
*	projet : CLC2
*	tache : préparer data bmi

* v2: dans cette extraction je n'ai pas le BMI calculé par constances.

/*----------------------------------------------------------------------------*/

use "$cree/DATA_PARACLIN_01.dta", clear

gen bmi = paracl_poi_mespoi / (paracl_hau_mestail/100)^2
note bmi: calculé par moi. paracl_poi_mespoi / (paracl_hau_mestail/100)^2. `tag'
label var bmi "BMI"

gen taille_inc = paracl_hau_mestail
label var taille_inc "Taille inclusion (paraclinique)"
	
compress	
sort proj_isp
save "$temp/t_paraclin", replace
	
/* si BMI calculé : 
rename	paracl_ind_bmi bmi
label var bmi "BMI mesure"
note bmi: paracl_ind_bmi. indicateur calculé par l'UMS à partir des mesures ///
	faites lors de l'examen de santé. `tag'

keep proj_isp suivi_rep_para bmi 
*/
