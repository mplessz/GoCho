/*---------------------------------------------------------------------------*/
*	Marie Plessz
*	2020-11-30
*	projet : HDR6
/*	tache : 
* coder les variables dépendantes dans le suivi de 2017 pour l'analyse prospective
coder  emploi_sui et chomeur_sui
*/


/*
Convention pour le nommage des variables : 
_c_ : variable continue régression linéaire
_n_ : nombre de... pour oi de poisson
_o_ : ordonnée pour ordered logits
_p_ : est-ce que la personne pratique?
_i_ : intensité de la pratique

_inc : à l'inclusion
_sui : pendant le suivi (2017)

	4. liste définitive des vars dépendantes : 
		1. logits: alcolabus, fume, _r_
		2. ologits: fréq légumes, fréq fruits, fréq poisson, fréq sodas, freq restorapide santé perçue _o_
		3. (loi de) poisson : nb de cigarettes (fumeurs et ex-fumeurs), nb de verres (ever drink?) _n_
		4. linéaires : bmi _c_

J'ai pas fait les fruits
j'ai tenté l'activité physique hors travail mais les q°r suivi et inclusion sont 
trop différents.		
		
*/

local tag "2b_HDR6_t_depvar_sui.do"

use using "$source/data_mdv_sv.dta" if suivi_phase  ==  "S2017", clear
count 
* 113,285 indv dans le fichier de suivi

************	ALCOOL	*****************

* nb verres alcool
gen alc_n_sui = aq_comport_alcconsojour_i 
label var alc_n_sui "Alcool nb verres"
note alc_n_sui: attention seul le semainier est collecté. `tag'

* pratique
gen alc_p_sui = aq_comport_alcconsojour_i >0
replace alc_p_sui = . if aq_comport_alcconsojour_i ==.
label var alc_p_sui "Alcool: consomme (semaine passée)"
note alc_p_sui : aq_comport_alcconsojour_i > 0. pas d'autre info. `tag'

* intensité : je prends le seuil calculé, qui est différent pour les hommes et les femmes
gen alc_i_sui =  aq_comport_alcconsojour_i>=2
replace alc_i_sui = . if aq_comport_alcconsojour_i == .
label var alc_i_sui "Alcool: intense (2 v/j)"
note alc_i_sui : 1 si aq_comport_alcconsojour_i>=2 . `tag'


*************	TABAC    ******************

* à risque, cad fumeur
gen fum_p_sui = aq_comport_tcactfume_n
recode fum_p_sui (2 = 0)
label var fum_p_sui "Fume"
note fum_p_sui : recodé aq_comport_tcactfume_n. `tag'


* nb de cigarettes
gen fum_n_sui = round(aq_comport_tccigtjnb_n)
replace fum_n_sui = 0 if fum_p_sui == 0 // 0 pour les ex-fumeurs
* manquant pour ceux qui n'ont jamais fumé ou si nb de paquet est manquant
label var fum_n_sui "Fume: Nb cig/j"
note fum_n_sui:  `tag'


*************	Alimentation 	**************
* je pars sur des logits ordonnés.

label def Lfreqconso 1 "Jamais" 	///
	2 "<1/semaine" 	///
	3 "1/semaine" 	///
	4 "2-3/semaine"	///
	5 "4-6/semaine"	///
	6 "Min 1/jour", modify

* Poisson
gen poi_o_sui = aq_alim_freqconspoiss_n
recode poi_o_sui (5 6 = 4)
label def poi_o_sui  1 "Jamais" 	///
	2 "<1/semaine" 	///
	3 "1/semaine" 	///
	4 "Min 2/semaine", modify
label val poi_o_sui poi_o_sui
label var poi_o_sui "Poisson freq"
note poi_o_sui : `tag'

* légumes
gen leg_o_sui = aq_alim_freqconslegcru_n
*replace leg_o_sui = 7 if  aq_alim_freqconslegcrupj_n >=2 & aq_alim_freqconslegcrupj_n < .
recode leg_o_sui (1 2 = 3)
label copy Lfreqconso leg_o_sui, replace
label def leg_o_sui 3 "Max 1/semaine" , modify
label val leg_o_sui leg_o_sui
label var leg_o_sui "Légumes freq"
note leg_o_sui : `tag'

* viande rouge
gen vro_o_sui = aq_alim_freqconsviande_n
recode vro_o_sui (1 2 = 2) (5 6 = 5)
label copy Lfreqconso vro_o_sui, replace
label def vro_o_sui 2 "< 1/semaine" 5 "Min 4/semaine", modify
label val vro_o_sui vro_o_sui
label var vro_o_sui "Viande rouge freq"
note vro_o_sui : non codée pour I1 car mélangée avec volaille. `tag'

* soda
gen sod_o_sui =  aq_alim_freqconssodaa_n
recode sod_o_sui (3/6 = 3)
label def sod_o_sui 1 "Jamais" 	///
	2 "<1/semaine" 	///
	3 "Min 1/semaine" 	, modify
label val sod_o_sui sod_o_sui
label var sod_o_sui "Boissons sucrées freq"
note sod_o_sui : `tag'

* resto rapide
gen fas_o_sui = aq_alim_freqconsfast_n
recode fas_o_sui (3/6 = 3)
label val fas_o_sui sod_o_sui
label var fas_o_sui "Restauration rapide freq"
note fas_o_sui : Attention absent du questionnaire I1. `tag'

*******  	SANTE	********

* santé perçue
gen san_c_sui = 9 - aq_sante_etatgeneral_n
label var san_c_sui "Santé perçue 2017 (8 = max)"

gen san_o_sui = aq_sante_etatgeneral_n
recode san_o_sui (1=8) (2 = 7) (3= 6) (4 = 5) (5/8 = 4)
label var san_o_sui "Sante perçue"
label def san_o_sui 8 "8/8 (excellente)" 7 "7/8" 6 "6/8" 5 "5/8" 4 "1-4/8", modify
label val san_o_sui san_o_sui
note san_o_sui : aq_sante_etatgeneral_n codée à l'envers `tag'


* bmi
	* Attention variables peu nettoyées par moi.

	merge 1:1 proj_isp using "$temp/t_paraclin" ,  keepusing(taille_inc)

	/*

    Result                           # of obs.
    -----------------------------------------
    not matched                        86,248
        from master                       198  (_merge==1)
        from using                     86,050  (_merge==2)

    matched                           113,087  (_merge==3)
    -----------------------------------------

	*/
	drop if _merge ==2 // le vire les individus qui ne sont pas dans le suivi

	gen bmi_c_sui = aq_sante_poids / ((taille_inc/100)^2)
	replace bmi_c_sui = . if aq_sante_poids > 160
	replace bmi_c_sui = 15 if bmi < 15
	replace bmi_c_sui = 45 if bmi > 45 & bmi < .
	label var bmi_c_sui "Corpulence"
	note bmi_c_sui : bmi borné à 17-45. `tag'



******************	EMPLOI	***************

tostring (aq_foyvie_sitempl aq_foyvie_sitdem aq_foyvie_sitretr aq_foyvie_sitform ///
	aq_foyvie_sitsant aq_foyvie_sitfoy aq_foyvie_sitaut), gen (sp1 sp2 sp3 sp4 sp5 sp6 sp9)
replace sp1= "E" if sp1=="1"		
	label var sp1 "sit. prof: emploi coche"
replace sp2= "C" if sp2=="1"		
	label var sp2 "sit. prof: dmdeur d'emploi coche"
replace sp3= "R" if sp3=="1"		
	label var sp3 "sit. prof: retraite coche"
replace sp4= "F" if sp4=="1"		
	label var sp4 "sit. prof: Formation étudiant coche"
replace sp5= "S" if sp5=="1"		
	label var sp5 "sit. prof: Ne travaille pas pour santé coche"
replace sp6= "I" if sp6=="1"	
	label var sp6 "sit. prof: sans activité professionnelle coche"
replace sp9= "a" if sp9=="1"	
		label var sp9 "sit. prof: autre, précisez-coche"
gen  spcomb=sp1+ sp2+ sp3+ sp4+ sp5+ sp6 + sp9
label var spcomb "Sit.prof: combinaison reponses"
note spcomb: combinaison des réponses aux sitprof1 à 9. `tag'

// la var emploi proprement dite
cap drop emploi
gen emploi=-9
	//nr
replace emploi=. if inlist(spcomb, "......." , "......a")
	//emploi
replace emploi=1 if inlist(spcomb,  "E......" )
	//chomage
replace emploi=2 if inlist(spcomb,  ".C.....", ".C.F...", ".C.F..a" ,".C.F.I.")
replace emploi=2 if inlist(spcomb,".C.F...", ".C...I.",	".C.F..a", ".C.F.Ia"  )
	// sans activité professionnelle
replace emploi=3 if inlist(spcomb, ".....I." , "....S.." , "....SI.", 	///
		".C...Ia", ".C..S..", ".C..S.a", ".C..SI.", ".C..SIa", ".C.FSI." ) 
	// chomage+emploi
replace emploi=4 if inlist(spcomb, ".C....a",  "EC.....", "EC....a", ///
		"EC...I.", "EC..S..", "EC.F...", "EC.FS..", "EC.F..a", "EC..SI.")
replace emploi=4 if inlist(spcomb, 	"E.....a", "E....I.", "E...S..", "E...SI.", "EC...Ia")
		//retraite y compris chô : tous codes contenant R
replace emploi=-1 if inlist(spcomb,	 "..R....", "..R...a", "..R..I.", "..R.S..", ///
		"..R.SI.", "..RF...",  ".CR....",  "..R.S.a")
replace emploi=-1 if inlist(spcomb, "..RF..a", ".CR.S.a", ".CRF...", ".CRF..a")
replace emploi=-1 if inlist(spcomb, "E.RF...", "E.R..I.", "E.R.S..",  "ECR...a", "ECR.SIa", "ECRF...")		
replace emploi=-1 if inlist(spcomb,	".CR...a", ".CR..I.", ".CR.S..", "ECR....", ///
"E.R....",  "E.R...a", "E.R.SI.")
replace emploi=-1 if inlist(spcomb, "..R..Ia", ".CRF.I.", "..R.S.a" )
	//formation non demandeur d'emploi
replace emploi=-2 if inlist(spcomb, "...F...",  "...F..a",  "...F.I.", "...F.Ia", ///
		"...FS.." , "E..F...", "E..F..a", " EC..S.a", "EC..S.a")
	//autre
replace emploi=-3 if inlist(spcomb, ".....Ia",  "....S.a", "....SIa", ".C.FS..", "E...S.a", "E....Ia" )
*replace emploi=-3 if inlist(spcomb,	 )

tab emploi
tab spcomb emploi, mis
	// verifie qu'aucune modalité de spcomb n'a été oubliee.
count if spcomb !="" & (emploi==-9)
assert r(N)==0 	//  erreur si oubli.

****** 	Variable détaillée suivi
rename emploi emploi_sui
label def emploi 1 "En emploi" 2 "Demandeur d'emploi sans emploi" ///
	3 "Sans act.pro" 4 "Emploi+cho/sansempl"	///
	-1 "Retraite" -2 "Etudiant sf dmd emploi" -3 "Autre" , modify
label val emploi_sui emploi
label var emploi_sui "Emploi 2017 détaillé"


**********	 VARIABLE "Traitement"
recode emploi (1 = 0 "En emploi") (2 = 1 "Perdu emploi") (else = .), gen(traitt)
label var traitt "Perdu emploi en 2017?"
note traitt : manquant si ni emploi ni chômage. utiliser emploi_sui pour le détail. 

keep proj_isp suivi_phase suivi_env_mdv suivi_rep_mdv *_sui  traitt
compress
save "$temp/t_depvar_sui.dta", replace
