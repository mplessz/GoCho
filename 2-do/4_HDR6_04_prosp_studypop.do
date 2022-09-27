/*---------------------------------------------------------------------------*/
*	Marie Plessz
*	2020-11-30
*	projet : HDR6
*	tache : 
*		sélectionner la population d'étude
*		chiffres pour le flowchart
*---------------------------------------------------------------------------*/

use "$cree/HDR6_03_prospectif.dta", clear

* année d'inclusion en chiffres
gen  y = substr(fm_per_inclusion  , -4, 4)
destring y, replace
label var y "Année d'inclusion"

* population de départ
count
	* 199,711
	
tab traitt if  emploi_inc == 1, mi
/*

Perdu emploi |
    en 2017? |      Freq.     Percent        Cum.
-------------+-----------------------------------
   En emploi |     39,191       30.43       30.43
Perdu emploi |      1,062        0.82       31.26
           . |     88,533       68.74      100.00
-------------+-----------------------------------
       Total |    128,786      100.00

	   ==> 1062 indv en emploi à l'inclusion et chômeurs en 2017 parmi les 199702.
*/

	

**************	Critères sur données à l'inclusion	*****************

* individus inclus avant 2017
count if y < 2017
* 114,642

keep if y < 2017
*exclus:(85,069 observations deleted)

* âge 18-60
count if fm_incluage <= 60
	*==> 88,039 inclus
 
keep if  fm_incluage <= 60
* ==>(26,603 observations deleted)

* edit label to match age max
label define  age_cl 50 "50-60 ans", modify

* vérification
table age_cl, c(max fm_incluage)
/*

		-------------------------
		Classe    |
		d'age     |
		inclusion | max(fm_inc~e)
		----------+--------------
		18-29 ans |            30
		30-39 ans |            40
		40-49 ans |            50
		50-60 ans |            60 // c'est bon.
		-------------------------
*/

* en emploi

count if emploi_inc == .
*  3,010 manquants

 count if emploi_inc !=1 & emploi_inc <.
*  16,870 autres situations qu'emploi à l'inclusion

count if emploi_inc == 1
* 68,159 gardés

 keep if emploi_inc == 1
*(19,880 observations deleted)

count
* ==> sélectionnés sur les critères à l'inclusion :   68,159

*************	Critères sur données de Suivi	************
*parmi ceux que j'ai déjà sélectionnés

* questionnaire pas (encore) en base
count if suivi_rep_mdv ==.
*   23,365 non reçu

* drop people whose follow-up questionaire is not received (yet)
drop if suivi_rep_mdv==.
*-->(23,365  observations deleted)

count
* 44,794 q°r 2017 reçu

drop if emploi_sui == . 
* (1,780 observations deleted)

*keep only people who are employed or jobseekers in 2017
keep if emploi_sui == 1 | emploi_sui == 2
*-->(3,442  observations deleted)

count
* 39,572 inclus 

* treated et controls  avant exclusion des manquantes
tab emploi_sui, mis

/*
     emploi |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     38,523       97.35       97.35
          2 |      1,049        2.65      100.00
------------+-----------------------------------
      Total |     39,572      100.00
*/


***********	Variables de contrôle manquantes **********

global varex homme age_cl traitt typmen avecenf01 aveccouple01
global varex $varex conjemploi diplome3 inde prive cspvol traveffr tuu2012_cl
global varex $varex diffinnow  astopsante astopcho entrain

misstable sum $varex 	 , all

misstable sum $varex  if traitt == 1, all

*  logistic traitt ib3.cspvol prive traveffr
/*==> cette régression montre que c TRES important de contrôler prive et cspvol, 
mais que traveffr n'est pas indispensable
inde n'est pas utile non plus si on a prive et cspvol
*/

global varexkeep homme age_cl traitt avecenf01 aveccouple01 diplome3 prive cspvol tuu2012_cl diffinnow  astopsante astopcho

egen ccex = rowmiss($varexkeep )
recode ccex (0=1) (else = 0)

**********   état des variables dépendantes  ********

global depkeep alc_p_inc fum_p_inc san_i_inc


egen ccdep = rowmiss($depkeep ) 
recode ccdep (0=1) (else = 0)

gen cc = ccdep * ccex ==1
label var cc "Complet sur vars de contrôle et appariement"

misstable sum $varexkeep $depkeep

tab cc traitt
/*
   Complet |
  sur vars |
        de |
  contrôle |
        et |
appariemen | Perdu emploi en 2017?
         t | En emploi  Perdu emp |     Total
-----------+----------------------+----------
         0 |     8,680        331 |     9,011 
         1 |    29,843        718 |    30,561 
-----------+----------------------+----------
     Total |    38,523      1,049 |    39,572 

*/

***********		Selection pop étude : complete sur vars de contrôle 

keep if cc == 1

misstable sum *_p_* *_n_* *_c_* *_o_* *_control_* if traitt ==1
misstable sum *_p_* *_n_* *_c_* *_o_* *_control_* if traitt ==0


/*
                                                                Obs<.
                                                +------------------------------
               |                                | Unique
      Variable |     Obs=.     Obs>.     Obs<.  | values        Min         Max
  -------------+--------------------------------+------------------------------
     alc_p_sui |        15                 703  |      2          0           1
     fum_p_sui |         4                 714  |      2          0           1
     alc_n_inc |        33                 685  |     12          0          14
     fum_n_inc |       549                 169  |     19          0          40
     alc_n_sui |        15                 703  |     12          0          13
     fum_n_sui |         9                 709  |     18          0          40
     bmi_c_inc |         8                 710  |   >500         17    43.85802
     san_c_sui |        19                 699  |      7          2           8
     bmi_c_sui |        32                 686  |   >500         15    42.67642
     poi_o_inc |         8                 710  |      4          1           4
     leg_o_inc |        10                 708  |      5          3           7
     vro_o_inc |        83                 635  |      4          2           5
     sod_o_inc |         6                 712  |      3          1           3
     fas_o_inc |        81                 637  |      3          1           3
     poi_o_sui |        17                 701  |      4          1           4
     leg_o_sui |        12                 706  |      5          3           7
     vro_o_sui |        15                 703  |      4          2           5
     sod_o_sui |        25                 693  |      3          1           3
     fas_o_sui |        18                 700  |      3          1           3
     san_o_sui |        19                 699  |      5          4           8
  -----------------------------------------------------------------------------

. misstable sum *_p_* *_n_* *_c_* *_o_* *_control_* if traitt ==0
                                                               Obs<.
                                                +------------------------------
               |                                | Unique
      Variable |     Obs=.     Obs>.     Obs<.  | values        Min         Max
  -------------+--------------------------------+------------------------------
     alc_p_sui |       278              29,565  |      2          0           1
     fum_p_sui |       163              29,680  |      2          0           1
     alc_n_inc |     1,388              28,455  |     22          0          32
     fum_n_inc |    25,025               4,818  |     30          0          60
     alc_n_sui |       278              29,565  |     23          0          32
     fum_n_sui |       273              29,570  |     28          0          40
     bmi_c_inc |       499              29,344  |   >500         17          45
     san_c_sui |       453              29,390  |      8          1           8
     bmi_c_sui |     1,359              28,484  |   >500         15          45
     poi_o_inc |       429              29,414  |      4          1           4
     leg_o_inc |       391              29,452  |      5          3           7
     vro_o_inc |     3,742              26,101  |      4          2           5
     sod_o_inc |       454              29,389  |      3          1           3
     fas_o_inc |     3,700              26,143  |      3          1           3
     poi_o_sui |       484              29,359  |      4          1           4
     leg_o_sui |       558              29,285  |      5          3           7
     vro_o_sui |       390              29,453  |      4          2           5
     sod_o_sui |       840              29,003  |      3          1           3
     fas_o_sui |       510              29,333  |      3          1           3
     san_o_sui |       453              29,390  |      5          4           8
  alc_contro~c |         5              29,838  |      2          0           1
  -----------------------------------------------------------------------------
*/


count
*==>  30,561 cas complets sur les variables de contrôle et appariement

/*

rename fum_n_inc truc
egen ccstrict = rowmiss(  *_inc *_sui  $varexkeep $depkeep ) 
rename  truc fum_n_inc
recode ccstrict (0=1) (else = 0)
 tab ccstrict traitt  


           | Perdu emploi en 2017?
  ccstrict | En emploi  Perdu emp |     Total
-----------+----------------------+----------
         0 |     6,776        166 |     6,942 
         1 |    22,396        541 |    22,937 
-----------+----------------------+----------
     Total |    29,172        707 |    29,879 
*541 traités ont absolument toutes les vars observées 
*hors fum_n_inc qui a des manquantes volontairement

*/ 
 
foreach g in alc_p alc_n fum_p fum_n sod_o san_o poi_o fas_o bmi_c leg_o vro_o {
	cap drop cdep
	egen cdep = rowmiss(`g'_inc `g'_sui)
	quietly count if cdep ==0
		local  tot = `"`r(N)'"'
	quietly count if cdep ==0 & traitt ==1
	local  tra = `"`r(N)'"'
	di " Variable `g' : `tot' complets , `tra' complets parmi les traités"
	
}

/*


 Variable alc_p : 30268 complets , 703 complets parmi les traités
 Variable alc_n : 28899 complets , 673 complets parmi les traités
 Variable fum_p : 30394 complets , 714 complets parmi les traités
 Variable fum_n : 14258 complets , 413 complets parmi les traités
 Variable sod_o : 29260 complets , 687 complets parmi les traités
 Variable san_o : 30089 complets , 699 complets parmi les traités
 Variable poi_o : 29633 complets , 693 complets parmi les traités
 Variable fas_o : 26311 complets , 621 complets parmi les traités
 Variable bmi_c : 29170 complets , 686 complets parmi les traités
 Variable leg_o : 29605 complets , 696 complets parmi les traités
 Variable vro_o : 26384 complets , 623 complets parmi les traités
*/
 
*********** FINIR *************

keep proj_isp fm_per_inclusion aq_modvie_refdoc y traitt ///
	homme age_cl  avecenf01 aveccouple01 conjemploi age typmen ///
	diplome3 edu inde prive cspvol  traveffr tuu2012_cl diffinnow  astopsante ///
	astopcho entrain *_inc *_sui 


	
compress

label data "Données prospectives studypop wide n = 30,561"
save  "$cree/HDR6_04_prosp_studypop.dta", replace
