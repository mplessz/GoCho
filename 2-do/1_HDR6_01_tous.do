local tag "1_HDR6_01_tous.do"


/*---------------------------------------------------------------------------*/
*******************************************************************************
*	Marie Plessz
*	2020-10-07
*	projet : HDR6
/*	tache : 
* fichier propre pour analyses à l'inclusion
	* recodages
	* selection variables
*/
/*---------------------------------------------------------------------------*/

use "$cree/CONSTANCES_inclusion_merge.dta", clear

*Variables pour ACM

	* origines des revenus
gen rorigreschom=origreschom==1
label var rorigreschom "Revenus du chomage: coché"
label val rorigreschom Lon01 
 
gen rorigresaidfam=origresaidfam==1
label var rorigresaidfam "Alloc fam/paje: coché"
label val rorigresaidfam Lon01

gen rorigresproch= origresproch==1
label var rorigresproch "Revenus de proches/fam: coché" 
label val  rorigresproch Lon01

	* revenus en 4 gpes équilibrés + missing
gen revuc_cho = 1 if revenuuc < 700
replace revuc_cho = 2 if revenuuc >= 700 & revenuuc < 1200
replace revuc_cho = 3 if revenuuc >= 1200 & revenuuc < 1800
replace revuc_cho = 4 if revenuuc >= 1800 & revenuuc < .
replace revuc_cho = 5 if revenuuc ==.

label def revuc_cho ///
	1 "RevUC_-700E" ///
	2 "RevUC_700-1200E" ///
	3 "RevUC_1200-1800E" ///
	4 "RevUC_1800+E" ///
	5 "RevUC_manquant", modify
	
label value revuc_cho revuc_cho
label var revuc_cho "Revenu mensuel/UC"	
note revuc_cho: revenu mensuel par uc en Euros. calculé à l'aide des quartiles ///
	de la distribution parmi les chômeurs à l'inclusion. `tag'
	
	* revenus avec les manquantes manquantes
clonevar revuc_mi =revuc_cho 
recode revuc_mi (5 = .)
label var revuc_mi "Revenu mensuel/UC (mis=.)" 	

		* age : 50-64 ans ensemble
clonevar age_cl = age10
replace age_cl = 50 if age>50 & age<.
label copy age10 age_cl , replace
label def age_cl 50 "50 ans et plus", modify
label value age_cl age_cl

note age_cl : recodé pour les 18-64 ans. `tag'


	* taille unite urbaine
gen tuu2012_cl = tuu2012
recode tuu2012_cl (0 1 2 = 1) (3 4 5 6 = 2) 
label def tuu2012_cl 1 "TailleUrb<10k" 2 "TailleUrb_10k-100k" ///
	7 "TailleUrb_200k-2millions" 8 "Paris_Agglo", modify
label value tuu2012_cl tuu2012_cl
label var tuu2012_cl "Taille U. urbaine"
note tuu2012_cl: recode de tuu2012. `tag'

*vars du cesd
gen entrain = aq_cesd_q20_n  
recode entrain (4 = 3)
label var entrain "Senti que je n'avais pas d'entrain? (CESD)"
label def entrain 1 "JMSPasEntrain" 2 "PFSPasEntrain" 3 "SVTPasEntrain"
label val entrain entrain
note entrain: recodage de aq_cesd_q20_n  . `tag' 

* Labels pour ACM
label def acm_sante 0 "AStopSantéNON" 1 "AStopSantéOUI"	, modify
label def acm_diffin 0 "DiffFinMoisNON" 1 "DiffFinMoisOUI" , modify
label def acm_avecenf01 0 "EnfantNON" 1 "EnfantOUI" , modify
label def acm_aveccou 0 "CoupleNON" 1 "CoupleOUI" , modify
label def acm_cp_jmstrav 0 "DejaTrav" 1 "JmsTrav" , modify
label def acm_proch 0 "ArgentFamNON" 1 "ArgentFamOUI" , modify
label def acm_chom 0 "AllocChoNON" 1 "AllocChoOUI" , modify
label def acm_cesd08 1 "JMSPasEntrain" 2 "_"  3 "_" 4 "PasEntrainTJS" , modify
label def acm_cesd20 1 "JMSConfFutur" 2 "_"  3 "_" 4 "ConfFuturTJS" , modify


label val astopsante acm_sante
label val diffinnow acm_diffin
label val avecenf01 acm_avecenf01
label val aveccouple01 acm_aveccou
label val cp_jmstrav acm_cp_jmstrav
label val rorigresproch acm_proch 
label val rorigreschom acm_chom 
label val aq_cesd_q08_n  acm_cesd08
label val aq_cesd_q20_n acm_cesd20

* stats desc vérification

tab2 emploi conjemploi /*aveccouple01*/ rorigresproch rorigreschom diffinnow ///
	astopsante diplome3  avecenf01  age_cl  homme cp_jmstrav region prive  ///
	aq_cesd_q08_n   if emploi ==1 | emploi ==2, mi first 

egen nmiss =  rowmiss(rorigresproch rorigreschom  revuc_mi astopsante diplome3 ///
	cp_jmstrav avecenf01 conjemploi age_cl  homme  region cspvol diffinnow entrain tuu2012_cl )
label var nmiss "Nb valeurs manquantes hors rev"

**********	 sélection variables	**********************
keep proj_isp suivi_phase aq_modvie_refdoc mdv_annee emploi conjemploi  ///
	aveccouple01 rorigresproch rorigreschom diffinnow  revuc_cho revuc_mi ///
	astopsante diplome3 prive inde typmen traveff ///
	avecenf01  age_cl age  homme cp_jmstrav region csppereado2 cspmereado2 ///
	cspvol entrain nmiss tuu2012_cl astopcho



****** Age <65 ans  ************
count
tab emploi, mi

label data "Constances recode pour HDR6 n=199,711"
save "$cree/HDR6_01_tous_tousages", replace

* individus 18-64 ans
keep if age<65
	* pas de raison de garder les moins de 60 ans comme dans les analyses panel,
	* car ce n'est pas la même population de départ (emploi) et en panel ils 
	* vieillissent (jusqu'à 65 ans max).
	* inclut les 64.5 ans

count	
* ==> (22,904 observations deleted) n =   176,807

	
***************** Finir *****************
label data "Constances recode pour HDR6 age<65 n=176,807"
save "$cree/HDR6_01_tous", replace

exit
