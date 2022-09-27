local tag "dm04b_paraclin_v1"

/*----------------------------------------------------------------------------*/
*	Marie Plessz
*	19/10/2017
*	projet : CLC2
*	tache : préparer data bmi
/*----------------------------------------------------------------------------*/

use "$cree/DATA_PARACLIN_01.dta", clear

rename	paracl_ind_bmi bmi
label var bmi "BMI mesure"
note bmi: paracl_ind_bmi. indicateur calculé par l'UMS à partir des mesures ///
	faites lors de l'examen de santé. `tag'

keep proj_isp suivi_rep_para bmi 
	
compress	
sort proj_isp
save "$temp/t_paraclin", replace
	
