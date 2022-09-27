/*---------------------------------------------------------------------------*/
*	Marie Plessz
*	2020-11-30
*	projet : HDR6
/*	tache : 
* coder les variables dépendantes à l'inclusion pour l'analyse prospective
renommer emploi en emploi_inc
*/

/*
Convention pour le nommage des variables : 
_c_ : variable continue régression linéaire
_n_ : nombre de... pour loi de poisson // pas entier pour Alcool
_o_ : ordonnée pour ordered logits
_p_ : exposé. pour des logits sur alcool et tabac
_i_ : pratique "intense". Intensité est relative sln fréquence de la pratique.

_inc : à l'inclusion
_sui : pendant le suivi (2017)

	liste définitive des vars dépendantes : 
		1. logits: alcool> reco (différentes pour hommes et femmes), fume, _p_
		2. ologits: fréq légumes, fréq fruits, fréq poisson, fréq sodas, freq restorapide santé perçue _o_
		// RENONCE à CA 3. (loi de) poisson : nb de cigarettes (fumeurs et ex-fumeurs), nb de verres (ever drink?) _n_
		4. linéaires : bmi _c_

==> je renonce à l'activité physique car les questionnaires inclusion et suivi sont incommensurables
==> j'ai laissé tombé les fruits, il faudrait aller chercher les différentes variables...		
		*/


local tag "2b_HDR6_t_depvar_inc.do"

use "$cree/CONSTANCES_inclusion_merge.dta", clear


************	ALCOOL	*****************
*récupérer le statut alcool à vie

merge 1:1 proj_isp using "$source\DATA_MDV",  keepusing(aq_comport_alcvie_n aq_comport_alchbfrq_n) 
 /*
     Result                           # of obs.
    -----------------------------------------
    not matched                             0
    matched                           199,711  (_merge==3)
    -----------------------------------------
*/
drop _merge

recode aq_comport_alcvie_n (2 = 0 ), gen(alc_control_inc)
label var alc_control_inc "Déjà bu alcool?"


* nb verres alcool
gen alc_n_inc = alcvj
replace alc_n_inc = 0 if alc_control_inc == 0 & alc_n_inc == .
*manquant pour ceux qui n'ont jamais bu
replace alc_n_inc = . if alc_control_inc ==0
label var alc_n_inc "Alcool nb (verres/j)"
note alc_n_inc:   alcvj. 0 inclut les pratiquants occasionnels(<1 v/j). ///
	alcvj= alcconsojour_i calculé par constances. `tag'

* pratique
gen alc_p_inc = alcvj >0
replace alc_p_inc = . if alcvj ==.
replace alc_p_inc = 0 if alcvj ==. & aq_comport_alchbfrq_n== 4
replace alc_p_inc = 0 if alcvj ==. & aq_comport_alchbfrq_n== 3
replace alc_p_inc = 0 if alcvj ==. & aq_comport_alchbfrq_n== 2
label var alc_p_inc "Alcool: pratique (semaine passée)"
note alc_p_inc : alcvj > 0 ou manquant et aq_comport_alchbfrq_n ==2 3 ou 4. ///
  alcvj = aq_comport_alcconsojour_i `tag'

* intensité : je prends le seuil calculé, qui est différent pour les hommes et les femmes
gen alc_i_inc =  alcvj>=2
replace alc_i_inc = . if alcvj == .
label var alc_i_inc "Alcool: intense (min 2 v/j)"
note alc_i_inc : 1 si alcvj>=2 . `tag'

*************	TABAC    ******************

* pratique ? cad fumeur
gen fum_p_inc = aq_comport_tcstatut_i
recode fum_p_inc (1 = 1) (0 2 =0)
label var fum_p_inc "Fumer: pratique"
note fum_p_inc : recodé aq_comport_tcstatut_i `tag'

* var pour sélectionner les pers qui ont déjà fumé : 
clonevar fum_control_inc = aq_comport_tcstatut_i  
label var  fum_control_inc "Statut tabagique inclusion"
note fum_control_inc : recodé aq_comport_tcstatut_i `tag'

* nb de cigarettes
gen fum_n_inc = round(aq_comport_tccigtjnb_n)
replace fum_n_inc = . if  aq_comport_tccigt1j_n ==1 //
replace fum_n_inc = 0 if aq_comport_tcstatut_i  == 2 // 0 pour les ex-fumeurs
* manquant pour ceux qui n'ont jamais fumé ou si nb de paquet est manquant
label var fum_n_inc "Fume: Nb cig/j moyen jsq inclusion"
note fum_n_inc: "moyenne depuis que fumme au moment d'inclusion aq_comport_tccigtjnb_n". ///
	manquant si aq_comport_tcstatutglobal_i ==jamais fumé. `tag'


	
*************	Alimentation 	**************
* je pars sur des logits ordonnés.

label def Lfreqconso 1 "Jamais" 	///
	2 "<1/semaine" 	///
	3 "1/semaine" 	///
	4 "2-3/semaine"	///
	5 "4-6/semaine"	///
	6 "Min 1/jour", modify

* Poisson
gen poi_o_inc = aq_alim_freqconspoiss_n
recode poi_o_inc (5 6 = 4)
label def poi_o_inc  1 "Jamais" 	///
	2 "<1/semaine" 	///
	3 "1/semaine" 	///
	4 "Min 2/semaine", modify
label val poi_o_inc poi_o_inc
label var poi_o_inc "Poisson freq"
note poi_o_inc : `tag'

* légumes
gen leg_o_inc = aq_alim_freqconslegcru_n
*replace leg_o_inc = 7 if  aq_alim_freqconslegcrupj_n >=2 & aq_alim_freqconslegcrupj_n < .
recode leg_o_inc (1 2 = 3)
label copy Lfreqconso leg_o_inc, replace
*label def leg_o_inc 3 "Max 1/semaine" 6 "Tous les jours", modify
label def leg_o_inc 3 "Max 1/semaine" , modify
label val leg_o_inc leg_o_inc
label var leg_o_inc "Légumes freq"
note leg_o_inc : `tag'


* viande rouge
gen vro_o_inc = aq_alim_freqconsviande_n
recode vro_o_inc (1 2 = 2) (5 6 = 5)
label copy Lfreqconso vro_o_inc, replace
label def vro_o_inc 2 "< 1/semaine" 5 "Min 4/semaine", modify
label val vro_o_inc vro_o_inc
label var vro_o_inc "Viande rouge freq"
note vro_o_inc : non codée pour I1 car mélangée avec volaille. `tag'


* soda
gen sod_o_inc =  aq_alim_freqconssoda_n
replace sod_o_inc =  aq_alim_freqconssodaa_n if sod_o_inc == .
replace sod_o_inc =  aq_alim_freqconssodag_n if sod_o_inc == .
recode sod_o_inc (3/6 = 3)
label def sod_o_inc 1 "Jamais" 	///
	2 "<1/semaine" 	///
	3 "Min 1/semaine" 	, modify
label val sod_o_inc sod_o_inc
label var sod_o_inc "Boissons sucrées freq inclusion
note sod_o_inc : `tag'

* resto rapide
gen fas_o_inc = aq_alim_freqconsfast_n
recode fas_o_inc (3/6 = 3)
label val fas_o_inc sod_o_inc
label var fas_o_inc "Restauration rapide freq"
note fas_o_inc : Attention absent du questionnaire I1. `tag'

*******  	SANTE	********

* santé perçue
gen san_c_inc = 9 - aq_sante_etatgeneral_n
label var san_c_inc "Santé perçue inclusion (8 = max)"

gen san_o_inc = aq_sante_etatgeneral_n
recode san_o_inc (1=8) (2 = 7) (3= 6) (4 = 5) (5/8 = 4)
label var san_o_inc "Sante perçue inclusion classes"
label def san_o_inc 8 "8/8 (excellente)" 7 "7/8" 6 "6/8" 5 "5/8" 4 "1-4/8", modify
label val san_o_inc san_o_inc
note san_o_inc : aq_sante_etatgeneral_n codée à l'envers `tag'

/*
* activité physique hors travail
gen act_o_inc = aq_actphy_actphyhorstrv_i
recode act_o_inc (0 1 = 1) ( 6  = 5)
label var act_o_inc "Activité physique hors travail"
label def act_o_inc 1 "0-1/6 Pas actif" 5 "5-6/6 Très actif", modify
label val act_o_inc act_o_inc
note  act_o_inc : `tag'
*/

* bmi
gen bmi_c_inc = bmi
replace bmi_c_inc = 17 if bmi < 17
replace bmi_c_inc = 45 if bmi > 45 & bmi < .
label var bmi_c_inc "Corpulence"
note bmi_c_inc : bmi borné à 17-45. `tag'


***************		Emploi inclusion  ******************
rename emploi emploi_inc

*********** Finir   *************

keep proj_isp *_inc
compress
save "$temp/t_depvar_inc.dta", replace
