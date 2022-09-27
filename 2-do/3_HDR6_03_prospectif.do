/*---------------------------------------------------------------------------*/
*	Marie Plessz
*	2020-11-30
*	projet : HDR6
/*	tache : 
* fusionner toutes les données pour l'analyse prospective.
*/



local tag "3_HDR6_03_prospectif"


* Toute la population de Constances
/* je repars de data_pop pour être sûre que j'ai tous les inclus au moment de l'extraction */

use  proj_isp fm_per_inclusion fm_incluage fm_per_deces  using "$source/data_pop.dta", clear
count
* ==> N = 199,711 j'ai bien toute la cohorte  

* J'ajoute mes recodages sur les données d'inclusion
merge 1:1 proj_isp using "$cree/HDR6_01_tous"

/*
   Result                           # of obs.
    -----------------------------------------
    not matched                        22,904
        from master                    22,904  (_merge==1)
        from using                          0  (_merge==2)

    matched                           176,807  (_merge==3)
    -----------------------------------------
*/
* les 22,904 non mergés sont les >65 ans qui ne sont plus dans "tous". 
* pour l'instant je garde tout le monde, je ferai la selection au prochain programme.

drop _merge


*-------		Recodages	sur les vars non dépdtes du temps	----------

recode diplome3 (0 1 = 1), gen(edu)
label copy diplome3 edu
label def edu 0 "" 1 "< Bac", modify
label val edu edu
label var edu "Diplôme"
note edu: recodé d'après diplome3. `tag'

gen traveffr = traveff - 6
label var traveffr "Effort physique au travail (max=14)"
*label val traveffr
note traveffr: recodé traveff pour commencer à 1

drop  traveff
drop emploi

		
*--------		Ajouter les vars dépendantes du temps   ------------

* J'ajoute les variables dépendantes et l'emploi à l'inclusion

merge 1:1 proj_isp using "$temp/t_depvar_inc.dta"

/*

    Result                           # of obs.
    -----------------------------------------
    not matched                             0
    matched                           199,711  (_merge==3)
    -----------------------------------------

*/
drop _merge

*J'ajoute les variables du suivi

merge 1:1 proj_isp using  "$temp/t_depvar_sui.dta" 

/*
   Result                           # of obs.
    -----------------------------------------
    not matched                        86,426
        from master                    86,426  (_merge==1)
        from using                          0  (_merge==2)

    matched                           113,285  (_merge==3)
    -----------------------------------------
*/
* ==> 113 285 c'est bien le nombre d'individus dans le suivi 2017
drop _merge


* ------	recodages au format long	-------------


reshape long alc_n   alc_i   fum_n   leg_o   sod_o   san_c   bmi_c ///
	alc_p   fum_p   poi_o   vro_o   fas_o   san_o   emploi ///
	, i(proj_isp) j(phase, string)


gen san_i = san_c
recode san_i (1/5 = 1) (nonmissing = 0)
label var san_i "Santé: mauvaise (1-5/8)"

gen san_f = san_c
recode san_f (8=1) (nonmissing = 0)
label var san_f "Santé: excellente(8/8)"

gen bmi_i = bmi_c >=30
replace bmi_i = . if bmi_c ==.
label var bmi_i "Corpulence: obèse (bmi>=30)"




* intensité
gen fum_i = 	fum_n >= 10 & fum_n < .
replace fum_i = . if fum_p == .
label var fum_i "Cigarette: intense (10/j)"
note fum_i : 1 si fum_n >=10 et fum_p non manquante . `tag'

foreach var in leg sod  poi vro fas { 
	gen `var'_i = `var'_o
	recode `var'_i (max = 1) (nonmissing = 0)
}

label var leg_i "Légumes: intense (min 1/j)"
label var sod_i "Sodas: intense (min 1/sem)"
label var poi_i "Poisson: intense (min 2/sem)"
label var vro_i "Viande rouge: intense (min 4/sem)"
label var fas_i "Fastfood: intense (min 1/sem)"


* variables ordonnées manquantes
gen bmi_o = .
replace bmi_o = 1 if bmi_c < 25
replace bmi_o = 2 if bmi_c >=25 & bmi_c < 30
replace bmi_o = 3 if bmi_c >30 & bmi_c < .

gen fum_o = fum_p
replace fum_o = 2 if fum_i ==1

gen alc_o = alc_p
replace alc_o = 1 if alc_n >0 & alc_n<1
replace alc_o = 2 if alc_n >=1 & alc_n<2
replace alc_o = 3 if alc_i ==1

*faible conso

foreach var in leg sod  vro fas { 
	gen `var'_f = `var'_o
	recode `var'_f (min = 1) (nonmissing = 0)
}

recode fum_p (1 = 0) (0 = 1), gen(fum_f)
recode alc_p (1 = 0) (0 = 1), gen(alc_f)

recode poi_o (1 2 = 1) (nonmissing = 0), gen(poi_f)

label var leg_f "Légumes: faible (max 1/sem)"
label var sod_f "Sodas: faible (jamais)"
label var poi_f "Poisson: faible (<1/sem)"
label var vro_f "Viande rouge: faible (<1/sem)"
label var fas_f "Fast-food: faible (jamais)"

reshape wide alc_n   alc_i   fum_n   leg_o   sod_o   san_c   bmi_c ///
	alc_p   fum_p   poi_o   vro_o   fas_o   san_o   emploi san_i-poi_f ///
	, i(proj_isp) j(phase, string)
	
	

**********	Finir ******
count
*  199,711 j'ai le bon nombre de lignes

compress
label data "Données Constances pour étude prospective, wide, recodée"
save "$cree/HDR6_03_prospectif.dta", replace
