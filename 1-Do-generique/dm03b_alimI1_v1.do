cap log close
set more off
local tag "dm03b_alimI1_v1"
*	log  using `tag', replace text

/*---------------------------------------------------------------------------------*/
*	Marie Plessz
*	_DATE_
*	projet : CMP
/*	tache : 
* simplifie les noms de vars de l'AQ alim 1
*/

use "$temp/t_foyvie01", clear
tab aq_modvie_refdoc
keep if aq_modvie_refdoc=="I1"
keep proj_isp age homme aq_modvie* aq_comport* aq_alim* aq_actphy* alc*	///
	age10 diplome4

save "$temp\t_i1alim01", replace


* simplifier le nom des variables freqcons
rename aq_alim_* *
rename freqcons*  f_*



*nom des items du FFQ I1
global v2 " vian poiss oeuf char lait from pain pate fruit legcru "
global v2 " $v2 legsec   plat   cafe the  soda "
	di "$v2"
			
	
global varffq ""	
foreach k in $v2	{  // @ changer les vars sur lesquelles je fais tourner
	global varffq= "$varffq f_`k'"
	* tab f_`k'_n
}
	
	// création de vars sf_item du ffq : fréq de conso/jour
foreach var in $varffq	{
	di "`var'" 
	gen s`var'=`var'pj_n								// var pour somme par jour
	replace s`var'=0.7 if `var'_n==5					//  4-6 fois/sem = 0.7/jour
	replace s`var'=0.36 if `var'_n==4				//	2-3/sem = 0.36/jour
	replace s`var'=0.15 if `var'_n==3				//	1/sem=0.15/jour
	replace s`var'=0 if `var'_n==1 | `var'_n==2		//  <1/sem = 0/jour
	label var s`var' "`var' moy/jour"
	note s`var' :  si var=1 ou 2, moy par jour si var=3 à 5, varpj si ///
		var==6, mqt si varpj>30. `tag'
}
*-------------- FIN -------------------*
keep proj_isp aq_modvie_refdoc sf_*
ds
sort proj_isp
compress
label data "var alim de i1"
save "$temp\t_i1alim02", replace
