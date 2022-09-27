cap log close
set more off
local tag "dm05_expopro_v2"


/*----------------------------------------------------------------------------*/
*	Marie Plessz
*	19/10/2017
*	projet : CLC2
*	tache :recodages expopro contraintes organisationnelles
/*
v2 : laisser manquantes les infos manquantes. tjs temps de considérer que c des
faux zéros.
*/
/*----------------------------------------------------------------------------*/

/*--------------- récupérer dates de passation des questionnaire --------*/
* le questionnaire expo pro est passé au CES, donc date de l'examen de santé
use "$cree/DATA_PARACLIN_01.dta", clear
desc 
keep proj_isp paracl_soc_datexam
sort proj_isp
save "$temp/t_paraclin_datexam", replace

* moi ce qui m'intéresse c la date de l'AQ mode de vie.
use "$cree\DATA_MDV_01", clear
keep proj_isp aq_modvie_dtremp_n
sort proj_isp
save "$temp/t_MDV_dtremp_n", replace

/*--------------- ajouter dates de passation des questionnaires --------*/

use "$cree\DATA_EXPOCAR_01", clear
sort proj_isp
merge m:1 proj_isp using "$temp/t_paraclin_datexam"
 
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                         3,011
        from master                     1,454  (_merge==1)
        from using                      1,557  (_merge==2)

    matched                           485,812  (_merge==3)
    -----------------------------------------
*/
rename _merge datexam_merge
merge m:1 proj_isp using  "$temp/t_MDV_dtremp_n"

/*
    Result                           # of obs.
    -----------------------------------------
    not matched                             7
        from master                         0  (_merge==1)
        from using                          7  (_merge==2)

    matched                           488,823  (_merge==3)
    -----------------------------------------
*/

rename _merge dtremp_merge


* variables années à partir des dates
gen annee_exam=year(paracl_soc_datexam)
label var annee_exam "annee examen sante"
note annee_exam: year(paracl_soc_datexam). `tag'
gen annee_remp=year(aq_modvie_dtremp_n)
label var annee_remp "annee remplissage MDV nettoyee"
note annee_remp: year(aq_modvie_dtremp_n). `tag'

*	/!\ modifier label des vars pour éviter d'être induite en erreur
label var aq_expocar_rang		"Si concerné(e) par cette contrainte, rang période importante"
label var aq_expocar_periodde	"Si concerné(e) par cette contrainte, année de début de cete période"
label var aq_expocar_perioda	"Si concerné(e) par cette contrainte, année de fin de cete période"

/*--------------- sélectionner les expositions qui m'intéressent ------------*/
 
/*
1. A03 Avez-vous (ou avez-vous eu) des horaires de travail et temps de trajet 
	vous obligeant souvent à vous coucher après minuit (au moins 50 jours par an).
2. A04 Avez-vous (ou avez-vous eu) des horaires de travail et temps de trajet 
	vous obligeant souvent à vous lever avant 5h du matin (au moins 50 jours par an).
3. A05 Avez-vous (ou avez-vous eu) des horaires de travail et temps de trajet 
	vous obligeant souvent à ne pas dormir la nuit (au moins 50 jours par an).
4. A06 Avez-vous (ou avez-vous eu) un temps de travail journalier supérieur 
	à 10 heures (au moins 50 jours par an).
5. A07 Avez-vous (ou avez-vous eu) un emploi où vous deviez travailler plus 
	d’un samedi sur deux dans l’année.
6. A08 Avez-vous (ou avez-vous eu) un emploi oû vous deviez travailler plus 
	d’un dimanche sur deux dans l’année.
7. A09 Avez-vous (ou avez-vous eu) régulièrement moins de 48 heures 
	consécutives de repos par semaine.
8. A10 Avez-vous (ou avez-vous eu) un travail répétitif sous contrainte 
	de temps (à la chaîne, produit ou pièce qui se déplace, machine à cadence
	automatique, rythme imposé par une norme stricte...).
9. A11 Avez-vous (ou avez-vous eu) un travail posté en horaires alternants
	(par équipes, brigades, roulements...)
*/


/* ==> ppales expositions : 
A05 Travail de nuit
A11 Horaires alternants

"Moins exposé"
A03 tard coucher apres minuit
A04 tôt lever avant5h
*/
keep if inlist(dico_aq_expo_ordre, "A03", "A04", "A05", "A11")
drop aq_expocar_autresps aq_expocar_autresps2 aq_expocar_autresps3

sort proj_isp dico_aq_expo_ordre aq_expocar_rang

clist proj_isp dico_aq_expo_ordre aq_expocar_ouinon aq_expocar_rang 	///
	aq_expocar_periodde aq_expocar_perioda paracl_soc_datexam annee_exam ///
	if proj_isp =="2015A0621000004"
	


label data "expo pro : nuit, alternant, tard, tôt"

save "$temp/t_expopro01"	, replace

/*---------------------Nettoyer les donnees ---------------------------------*/
 use  "$temp/t_expopro01", clear
 
* variable début d'épisode propre : manquante si chiffre <1930 
gen debut=aq_expocar_periodde
recode debut(9999=.) (min / 1930=.)
label var debut "Début expo nettoyee"
note debut: =aq_expocar_periodde (9999=.) (min / 1930=.). `tag'

* variable de fin propre : manquante si 9999 ou <1930
	* = date remplissage si manquante et pas début	
gen fin=aq_expocar_perioda
replace fin= annee_remp if aq_expocar_periodde <=annee_remp & aq_expocar_perioda >=9999
recode fin (9999=.) (min / 1930=.)
label var fin "Fin expo nettoyee"
note fin : =aq_expocar_perioda.  manquante si perioda<=1930 ou ==9999. ///
	mais vaut date remplissage si manquante alors  que periodde est  ///
	renseignee.`tag'

* cohérence début et fin
count if fin<debut  & debut<.
	* 16 incohérences : manquantes
replace fin=. if fin<debut & debut<.
replace debut=. if fin<debut & debut<.

note fin : manquante si fin<debut et debut pas manquant (16 cas).
note debut : manquante si fin<debut et debut pas manquant (16 cas).

* nettoyage remontant de _ouinon
		*expo01 est codé en dummy (0=non)
recode aq_expocar_ouinon (1=1) (2 =0) (999=.) , gen(expo01)
	*nettoyage
	*si une période a une date de début et une date de fin, on peut corriger
recode  expo01 (.=1) if fin!=. & debut!=.
recode  expo01 (0=1) if fin!=. & debut!=.

label var expo01 "exposition : Oui/non 01 nettoyee"
label value expo01 Lon01
note expo01 : recode aq_expocar_ouinon (1=1) (2 =0) (999=.) 	///
	nettoyée : oui si debut et fin non manquants. `tag'

* repère 1° ligne par indv et contrainte
bys proj_isp dico_aq_expo_ordre: gen l1=_n==1
bys proj_isp dico_aq_expo_ordre: gen lmax= _n==_N

/*	82 indv n'ont pas rempli la première ligne mais ont rempli la 2°.
tab expo01 if l1==1 & lmax==0, mis

 exposition |
  : Oui/non |
01 nettoyee |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |         82        0.48        0.48
          1 |     16,820       98.84       99.32
          . |        115        0.68      100.00
------------+-----------------------------------
      Total |     17,017      100.00

clist proj_isp aq_expocar_rang l1 lmax aq_expocar_rang expo01 debut fin 	///
	expo01 if proj_isp =="2015A0621000138"
*/
	
/*--------------- coder si a été exposé dans sa vie  ------------*/
	

*nb de oui à chaque contrainte (max 3)
bys proj_isp dico_aq_expo_ordre: egen nexpo=total(expo01)

* verifier que les 0 sont pas des sommes de manquantes
bys proj_isp dico_aq_expo_ordre: egen q=total(expo01==.) // nb de aexpo01 mqts
bys proj_isp dico_aq_expo_ordre: gen mnexpo= q==_N	//le nb de mqt est égal au nb de lignes

	// compte les variables manquantes :
* ==> a été exposé: 
gen oui= nexpo>0
replace oui=. if mnexpo==1 /* manquant si aexpo01 est manquant sur
 ttes les lignes pour cette xposition.*/

note oui: a été exposé à la contrainte. basé sur expo01, qui est ///
	aq_expocar_ouinon nettoyée. manquant si expo01 tjs manquante. `tag'
drop q mnexpo
tab oui dico_aq_expo_ordre if  l1==1, mis


/*--------------- coder si exposé quand remplit Mode de vie  ------------*/
* vaut 1 si exposé année de dtremp
*	- année de fin sup ou égale à dtremp
*	- année début existe et année de fin manquante
*V2 : utilise les vars nettoyees debut et fin
gen exponow01=-9
replace exponow01=0 if expo01==0
replace exponow01=0 if expo01==1 & fin<annee_remp
replace exponow01=1 if expo01==1 & fin>=annee_remp
replace exponow01=. if  expo01>0 & fin==.
	/* fin n'est mqte que si illisible/incohérent, donc si fin manquante on ne
	peut pas savoir si actuellement exposé.	*/
replace  exponow01=. if debut==. & expo01==.
	/* 4 indv n'ont rempli ni oui-non ni début, mais ont une date de fin. manquants	*/


*nb de oui à chaque contrainte (max 1 :)
bys proj_isp dico_aq_expo_ordre: egen nexponow=total(exponow01)
* manquant si exponow01 mqt à toutes les lignes.
bys proj_isp dico_aq_expo_ordre: egen q=total(exponow01==.) // nb de aexpo01 mqts
bys proj_isp dico_aq_expo_ordre: gen mnexpo= q==_N	//le nb de mqt est égal au nb de lignes

tab nexponow dico_aq_expo_ordre if  l1==1	



* ==> est exposé qd remplit dtremp: 
gen now= nexponow>0
replace now=. if mnexpo==1 
drop q mnexpo

note now: être exposé au moment du questionnaire MDV. ///
	manquante si date de fin incohérente ou si aucune ligne correctement	///
	renseignee. `tag'

tab now dico_aq_expo_ordre if  l1==1	


/*---------------------- durée totale d'exposition------------------ */

*duree des épisodes bien renseignés
gen duree=fin-debut+1		// 2013 à 2013 compte pour 1 an.
replace duree=. if expo01==1 & ( fin==. | debut==.)
replace duree=0 if expo01==0

* pb des périodes qui se chevauchent
bys proj_isp dico_aq_expo_ordre: gen pb1= debut[_n]>=debut[_n+1]  & fin[_n]<= fin[_n+1]
bys proj_isp dico_aq_expo_ordre: replace pb1=1 if debut[_n]<=debut[_n+1]  & fin[_n]>= fin[_n+1]
bys proj_isp dico_aq_expo_ordre: replace pb1=1 if debut[_n]>=debut[_n+2]  & fin[_n]<= fin[_n+2]
bys proj_isp dico_aq_expo_ordre: replace pb1=1 if debut[_n]<=debut[_n+2]  & fin[_n]>= fin[_n+2]
replace pb1=. if missing(debut, fin)

* les premiers épisodes qui se chevauchent ac 1 autre sont réduits à 0
replace duree=0 if pb1==1

* durée totale minimum d'exposition à la contrainte organisationnelle
bys proj_isp dico_aq_expo_ordre: egen durtot=total(duree)
	// minimale parce qu'il y a des épisodes non datés 

* les durées aberrantes sont bornées
recode durtot (45 / max=.)		//78 changements

/* comme les durées les plus courtes ont été recodées à 0,5, un 0 signifie
	qu'il n'y a que des data manquantes dans les dates des périodes. 
	si on sait que la pers a eté exposé c qu'on a aucune idée de la duree.	*/
replace durtot =. if durtot==0 & oui==1 
	/* si on sait que les gens ont été exposés
	et qu'on a une durée totale nulle c que toutes les durées étaient manquantes
	car on a ajouté 1 à toutes les durées calculées */
replace durtot =. if oui==.	
	/* si non ne sait pas si les gens ont été exposés,
	on ne sait pas sur quelle duree	*/

note durtot: somme des durées d'exposition à une contrainte, declarees proprement. j'ai nettoyé ///
	les dates de début et de fin et supprimé les épisodes qui se chevauchaient. ///
	borné à 45 et manquant si 0 alors qu'a été exposé (ou si oui==.) car 	///
	signifie qu'a q des dates manquantes.  `tag'
	
bys oui : tabstat durtot if  l1==1	, by(dico_aq_expo_ordre ) stats( min max p50 mean n)
/*---------------------- generer var claire pour les contraintes------------ */
gen  co=""
replace co="nui_" if 	dico_aq_expo_ordre=="A05"
replace co="alt_" if 	dico_aq_expo_ordre=="A11"
replace co="tar_" if 	dico_aq_expo_ordre=="A03"
replace co="tot_"  if 	dico_aq_expo_ordre=="A04"

save "$temp/t_expopro02"	, replace
/*---------------------- generer des variables "wide" ------------------ */
* pour chaque type d'exposition : a connu, connaît now, duree totale



use  "$temp/t_expopro02", clear
 
keep if l1==1
keep proj_isp oui now durtot co dtremp_merge

*	reshape wide genère les 3 vars pour chaque exposition
reshape wide @oui @now @durtot,  i(proj_isp) j(co) string

*----------------- variables propres ac labels etc --------------------*
label var		alt_oui		"Hor. alternants: a declare?"	
label var		alt_now		"Hor. alternants: au moment AQ?"	
label var		alt_durtot		"Hor. alternants: duree totale declaree"	
label var		nui_oui		"Travail de nuit: a declare?"
label var		nui_now		"Travail de nuit: au moment AQ"
label var		nui_durtot		"Travail de nuit: duree totale declaree"
label var		tar_oui		"Coucher>minuit: a declare?"
label var		tar_now		"Coucher>minuit: au moment AQ?"
label var		tar_durtot		"Coucher>minuit: duree totale declaree"
label var		tot_oui		"Lever<5h: a declare"
label var		tot_now		"Lever<5h: au moment AQ?"
label var		tot_durtot		"Lever<5h: duree totale declaree"

label val 		alt_oui		Lon01
label val 		alt_now		Lon01
label val 		nui_oui		Lon01
label val 		nui_now		Lon01
label val 		tar_oui		Lon01
label val 		tar_now		Lon01
label val 		tot_oui		Lon01
label val 		tot_now		Lon01


compress
sort proj_isp
label data "expositions contraintes organisationnelles temps"
note _dta: expositions au travail de nuit, horaires alternants, obligé levé ///
	5h 50/an obligé couché minuit 50/an. uniqut indv pour lesquels Q°R expo pro reçu. `tag'
save "$temp/t_expopro03"	, replace
