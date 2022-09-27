cap log close
set more off
local tag "dm03_pnnsI2_v1"
*	log  using `tag', replace text

/*---------------------------------------------------------------------------------*/
*	Marie Plessz
*	_DATE_
*	projet : CL1
/*	tache : 
* simplifie les noms de vars
* cree les composantes et le score pnns pour le questionnaire inclusion version2.
ce score est identique en tous points à celui publié dans le BEH en 2016.
seules différences : 
-les vars utilisées sont les vars aq_alim_freqconsoALIM_n nettoyées par 
	constances. dans BEH ces vars nettoyées s'appelaient aq_alim_freqconsoALIM2
	et il est possible qu'elles soient légèrement différentes;
-pour l'alcool j'ai utilisé la conso calculée par l'UMS (pour BEH cette partie
	du questionnaire n'avait pas été nettoyée ou du moins, l'indicateur n'était
	pas dispo).
-rappel : la population ici a moins de 65 ans.	

-corrigé erreur dans alcool : les alcreco non calculés étaient évalués comme validés.
*/
/*---------------------------------------------------------------------------------*/
use "$temp/t_foyvie01", clear
tab aq_modvie_refdoc
keep if aq_modvie_refdoc=="I2"
keep proj_isp age homme aq_modvie* aq_comport* aq_alim* aq_actphy* alc*	///
	age10 diplome4

save "$temp\t_i2alim01", replace

/*------------------------------    Preparation     ---------------------------*/


// 	donner des noms potables aux vars 

*simplifier le nom des vars activité physique
rename aq_actphy* actphy*

* simplifier le nom des variables freqcons
rename aq_alim_* *
rename freqcons*  f_*

*	
*nettoyage huile selon les consignes du document sur le nettoyage des données
lookfor huilpj_n			// verifier que var nettoyee exite pas
if "`r(varlist)'"=="" {
	clonevar f_huilpj_n= f_huilpj
	replace f_huilpj_n=. if f_huilpj>80

	clonevar f_huil_n= f_huil
	replace f_huil_n=6 if f_huil> 6 & f_huilpj_n<.
	recode f_huil_n (914= 2) (924 925=3) (934=4) (945 946=5) (956=5)
	replace f_huil_n=. if f_huil_n>9
	label var f_huil_n "AQ-Alimentation-Habituellement freq conso huile (nettoyee)"
	label var f_huilpj_n "AQ-Alimentation-par jour freq conso huile (nettoyee)"
}

* nettoyer typgras
lookfor typgras_n			// verifier que var nettoyee exite pas
if "`r(varlist)'"=="" {
	clonevar typgras_n=typgras
		recode typgras_n (912=1) (934=3) (935 945 9135 9145 9345=5)
	replace typgras_n=. if typgras_n>9
	replace typgras_n=4 if typgras_n==. & magarin<.		//recodage ascendant
	label var typgras_n "AQ-Alimentation-matière grasse + svt cuire (nettoyee)"
}

*label valeur frequentiel
label def Lfreqconso 1 "Jamais" 	///
	2 "<1/semaine" 	///
	3 "1/semaine" 	///
	4 "2-3/semaine"	///
	5 "4-6/semaine"	///
	6 "1/jour ou +", modify


/*------------------------------    recodage vars ffq    ---------------------------*/
***	2	création de variables de nombre moyen de conso par jour à partir
* des vars de fréquence
***		pour I2 seulement


*nom des items du FFQ I2
global v2 " viande volail poiss oeuf char lait from pain pate fruitc legcru "
global v2 " $v2 legsec bis chips plat fast patis cafe the jus sodag energ"
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

/*
Les variables finissant par "_n" ont éténettoyées par Constances: 
ces bouts de codes que j'avais avant sont devenus inutiles :
	replace s`var'=1 if `var'==6 & `var'pj==.		
		/* on suppose que les gens qui ont dit tous les jours et pas mis de 
		chiffre pensaient 1/jour	*/
	replace s`var'=. if `var'pj2>30 &  `var'pj2<.	// les codes bizarres 
	sont manquants
*/


/*--------------------- SAUVE le fichier	--------------------------------------*/

label data "temp: alimentation+alcool+actphy pour score PNNS sur I2"
save "$temp\t_i2alim02", replace

/*-------------------------    Composantes PNNS     ---------------------------*/

*	fruits et legumes
**********************

	/*NB : Kesse et al divisent les grammes consommes par 80 pour obtenir le nb de "portions", 
	elles arrivent à un taux de "guideline respectée très haut par rapport à moi ce qui est
	logique. il faudra peut etre changer les limites
	j'ai RETIRE les jus
	*/
	
cap drop s
gen s=sf_fruitc + sf_legcru 

gen pnns_fl=0 if s<3.5
replace pnns_fl=0.5 if s>=3.5 
replace pnns_fl=1 if s>=5  
replace pnns_fl=2 if s>=7.5 
replace pnns_fl=. if s==.

label var pnns_fl "PNNSi2 Fruits légumes pas jus"
note pnns_fl:  1 si fruits (pas jus) + legumes >=5/j. 2 si >=7.5 /j.  `tag'

rename s fpj_fl
label var fpj_fl "PNNSi2: Fruits légumes fréquence"
note fpj_fl: fruits (pas jus) + legumes nb de fois par jour. `tag'



* pain cereales legumes secs
****************************
gen s=sf_pain + sf_legsec + sf_pate + 1/3*sf_plat + 1/3*sf_fast

gen pnns_fec=0 			if s<1
replace pnns_fec=0.5 	if s>=1 & s<3 
replace pnns_fec=1		if s>=3 & s<6
replace pnns_fec=0.5 	if s>=6 
replace pnns_fec=. if s==.
rename s fpj_fec
label var pnns_fec "PNNSi2 feculents"
note pnns_fec: pain+pates/riz/pdt + legumes secs>=3 & <6/j. `tag'
label var fpj_fec "PNNSi2 feculents freq/j"
note fpj_fec : sf_pain + sf_legsec + sf_pate + 1/3*sf_plat + 1/3*sf_fast. `tag'

	
* produits laitiers
*******************
gen s= sf_lait + sf_from

gen pnns_lai=0			if s<1
replace pnns_lai=0.5 	if s>=1 & s<2.5
replace pnns_lai=1		if s>=2.5 & s<=3.5
replace pnns_lai=0		if s>3.5 
replace pnns_lai=1		if s>=2.5 & s<=4.5 	& age>54 & age<.
replace pnns_lai=0		if s>4.5 			& age>54 & age<.
replace pnns_lai=.		if s==.

label var pnns_lai "PNNSi2 produits laitiers"
note pnns_lai: produits laitiers >=3.5/j. 4.5 si age>54. attention ///
	sans doute sous estimation des desserts lactés `tag'
note pnns_lai: exclu les desserts lactés car dans ENNS ils ne figurent pas ds ///
	liste produits laitiers. 

rename s fpj_lai
label var fpj_lai "PNNSi2 produits laitiers freq/j" 
note fpj_lai : sf_lait + sf_from. `tag'	
	
* VPO : viandes, poisson, oeuf
*********
gen s= sf_viande + sf_volail+ sf_poiss +sf_oeuf + 1/3*sf_plat

gen pnns_vpo = 0		if s==0
replace pnns_vpo=0.5	if s>0 & s<1
replace pnns_vpo=1	if s>=1 & s<=2
replace pnns_vpo=0	if s>2 
replace pnns_vpo=. if s==.
label var pnns_vpo "PNNSi2 VPO"
note pnns_vpo: viande, volaille, poisson, oeuf 1 ou 2/j. charcuteries exclues. `tag'

rename s fpj_vpo
label var fpj_vpo "PNNSi2: VPO freq/j"
note fpj_vpo: sf_viande + sf_volail+ sf_poiss +sf_oeuf + 1/3*sf_plat. `tag'

* poisson
*********

gen pnns_poi=0		if f_poiss_n<4
replace pnns_poi=1	if f_poiss_n>=4 & f_poiss_n<9
replace pnns_poi=. if f_poiss_n==.
	/* attention je code par rapport f_poi, la variable sur les fréquences< 
	1 fois par jour.	*/
label var pnns_poi "PNNSi2 poisson"
note pnns_poi : poisson 2 fois/semaine. `tag'

* sucres provenant des aliments sucres
**************************************
/* ==> j'ai retire les boissons	
*/
gen s=sf_bis + sf_patis 

	*je ne peux pas utiliser la norme d'Emmanuelle Kesse (en % des EI); je propose
	*0 si >1 produits sucr고/jour et -0.5 si >2 produits sucres / jour
gen pnns_suc=1 			if s<1
replace pnns_suc=0 		if s>=1 & s<.
replace pnns_suc=-0.5	if s>2
replace pnns_suc=. 		if s==.
rename s fpj_suc
label var fpj_suc "PNNSi2: alim sucre freq/j"
note fpj_suc : sf_bis + sf_patis . `tag'

label var pnns_suc "PNNSi2 alim sucre"
note pnns_suc: produits sucres<1/j. `tag'


* graisses ajoutees
*******************
/* non mesurees dans i2	*/

* graisses vegetales
********************

cap drop b2
cap drop gv*
cap drop csvt gvmis  max
cap drop pnns_gra*
/* gv1: vaut 1 si toujours du beurre.	*/
gen gv1=grasbeurre==4

/* gv2 : vaut 1 si beurre souvent ET aucune matiere grasse plus souvent que le beurre	*/

gen gv2=0
replace gv2=1 if grasbeurre==3

gen gv2bis=gv2

gen b2=grasbeurre
recode b2 (.=2)

unab g: *gras*
di "`g'"
local b grasbeurre
local g2: list g-b
di "`g2'"

foreach var of local g2 {
	replace gv2=0    if `var'> b2 & `var'<=4	& b2==3 // si mat grasse + svt que beurre
}

gen gvmis=0
foreach var of local g {
 	replace gvmis=gvmis+1 if `var'==.
}	

quietly sum gvmis
gen max=r(max)

gen pnns_gve= 1
replace pnns_gve=0 if gv1==1 | gv2==1 
replace pnns_gve=1 if grasbeurre<3
replace pnns_gve=. if gvmis==max
label var pnns_gve "PNNSi2 Graisses végétales"
note pnns_gve: graisses végétales > beurre. `tag'

drop gv1-max


* boissons sucrees
**********
	*soda, jus de fruits et boissons energisantes
	
gen s=sf_sodag + sf_energ + sf_jus
gen pnns_boi=1 			if s<1
replace pnns_boi=0 		if s>=1 
replace pnns_boi=. 		if s==.
rename s fpj_boi
label var pnns_boi "PNNSi2 boissons sucrées"
note pnns_boi: boissons sucrees (soda, nrj, jus) <1/jour. `tag'

label var fpj_boi "PNNSi2 boissons sucrees freq/j"
note fpj_boi: sf_sodag + sf_energ + sf_jus.`tag'

* alcool
********
gen pnns_alc=alcreco
recode pnns_alc (1=1) (2=0.8) (3=0) (4=.)
/* alcreco est la copie numérique de aq_comport_alcrecommandation_i */
label val pnns_alc
label var pnns_alc "PNNSi2 alcool"
note pnns_alc: copie de alcrecommandation_i avec les valeurs pour score ///
	pnns. (1=1) (2=0.8) (3=0) classe reco correspond aux reco du pnns-gs. `tag'
gen fpj_alc=alcvj
label var fpj_alc "PNNSi2: nb verres moy/j au minimum"
note fpj_alc: = alcvj= alcconsojour_i. calculé par constances.

/* classe reco correspond aux reco du pnns-gs. pour le vérifier: 
gen s=alcvj

*seuils pour les hommes
gen 	alch=0.8 if s<=3
replace alch=0 if s>3 & s<.
replace alch=1 if s<1/7 	// moins d'un par semaine
replace alch=. if homme==0
*seuils pour les femmes
gen alcf=0.8 if s<=2 
replace alcf=0 if s>2 & s<. 
replace alcf=1 if s<1/7		// moins d'un par semaine
replace alcf=. if homme==1

*item pnns
egen pnns_alctest=rowtotal(alch  alcf ), mis
tab pnns_alctest alcrecommandation_i
*/


* sel
***** 
	* on peut regarder les items très salé Sebastien czernichow: sel ajoute=20% apports en sel.
	* 1 = pas tous les jours des aliments sal
gen s=sf_char +  sf_from + sf_chips + sf_fast

gen pnns_sel	=1		if s<1
replace pnns_sel=0	if  s>=1 
replace pnns_sel=. if s==.
label var pnns_sel "PNNSi2 sel"
rename s fpj_sel
note pnns_sel: charcuterie+fromage+chips+fastfood: <1/j. `tag'

label var fpj_sel "PNNSi2: alim tres sales frequence"
note fpj_sel: PNNSi2 : fréq conso alim tres sales. sf_char +  sf_from	///
	+ sf_chips + sf_fast. `tag'
	
*activite physique hors travail
*******************************

	* trajets, sports, bricolage
	* j'essaie de calculer un temps d'activite physique par semaine.
		*trajets	
gen st=actphy_12mtrjpdbychbd_n
replace st=21 if st>21		
	/* plus de 21 trajets par semaine parait irrealiste	*/
gen h_trajet=		st	/6 if actphy_12mtrjpdbyc_n==2
	/* 6 trajets<15min=1h d'act phy	*/
replace h_trajet=	st	/3 if actphy_12mtrjpdbyc_n==3
	/*	3 trajets>15min==1h d'act phy	*/
replace h_trajet=0 if actphy_12mtrjpdbyc_n==1

	*sport
gen 	h_sport=0.75 if ( actphy_12msport_n==2 | actphy_12msport_n==.) & 	///
	( actphy_12msporthbd_n==1 | actphy_12msporthbd_n==.)
		/* si sport 1/sem et <2h : 3/4 d'heure.	*/
replace h_sport=1	 if ( actphy_12msport_n==2 | actphy_12msport_n==.) 	///
	& actphy_12msporthbd_n>1 & actphy_12msporthbd_n<3 
		/* si sport<2h mais >1 et <3 fois par sem: 1h	*/
replace h_sport=1.5	 if ( actphy_12msport_n==2 | actphy	_12msport_n==.) 	///
	& actphy_12msporthbd_n>=3 & actphy_12msporthbd_n !=.
		/* si sport<2h mais >=3 fois par sem: 1,5h	*/
replace h_sport=2	 if  actphy_12msport_n==3 & actphy_12msporthbd_n<=2
		/* si sport>=2h et <=2 fois par sem: 2h	*/
replace h_sport=3	 if  actphy_12msport_n==3 & actphy_12msporthbd_n>2 	///
	& actphy_12msporthbd_n<=4 
		/* si sport>=2h et 2.5 ou 4 fois par sem: 3h	*/
replace h_sport=5	 if  actphy_12msport_n==3 & actphy_12msporthbd_n>4 	///
	& actphy_12msporthbd_n<7
replace h_sport=7 	if actphy_12msport_n==3 & actphy_12msporthbd_n>=7
replace h_sport=0	 if actphy_12msport_n	==1
	
	*odd jobs
gen 	h_odd=0 if actphy_12mtrvman_n==1
replace h_odd=0.5 if actphy_12mtrvman_n==2 & actphy_12mtrvmanhbd_n<=2
replace h_odd=0.5 if actphy_12mtrvman_n==. & actphy_12mtrvmanhbd_n !=.
replace h_odd=1 if actphy_12mtrvman_n==2 & actphy_12mtrvmanhbd_n>2
replace h_odd=2 if actphy_12mtrvman_n==3 & actphy_12mtrvmanhbd_n<=2
replace h_odd=3 if actphy_12mtrvman_n==3 & actphy_12mtrvmanhbd_n>2 & actphy_12mtrvmanhbd_n< 5
replace h_odd=5 if actphy_12mtrvman_n==3 & actphy_12mtrvmanhbd_n>=5 & actphy_12mtrvmanhbd_n< .

gen h_ap=h_trajet + h_sport + h_odd		

gen 	pnns_ap	=1 		if h_ap>=3.5 
replace pnns_ap	=1.5 	if h_ap>=7
replace pnns_ap	=0 		if h_ap<3.5
replace pnns_ap	=. 		if h_ap==.

label var h_trajet "Act phy/sem: trajet"
label var h_sport "Act phy/sem: sport"
label var h_odd "Act phy/sem: odd jobs"
label var h_ap "Act phy/sem total"
note h_trajet: Trajets: calcul d'activite physique ramene a un nombre d'heures par semaine pour le pnns. `tag'
note h_sport: Sport: calcul d'activite physique ramene a un nombre d'heures par semaine pour le pnns. `tag'
note h_odd: Odd-jobs: calcul d'activite physique ramene a un nombre d'heures par semaine pour le pnns. `tag'
note h_ap: h_ap=h_trajet + h_sport + h_odd	. `tag'

label var pnns_ap "PNNSi2 activite physique"
note  pnns_ap: base sur une mesure qualitative construite ࡰartir des trajets, 	///
	du sport et des travaux domestiques. `tag'
drop st // h_*

*cereales completes
*******************************
/* non mesure dans i2	*/

/*-------------------------    score PNNS-GS     ------------------------*/	
gen pnnsgs= pnns_fl + pnns_lai +     pnns_poi +   pnns_suc  +    pnns_alc      ///
		 +	pnns_ap + pnns_fec + pnns_vpo + pnns_gve + pnns_boi + pnns_sel

		 
**********************************************************************		 
/*----------------  items "convenience"  --------------------*/		 
**********************************************************************	

	// dans I2
* grignotage	
gen s= sf_bis + sf_chips
gen npnns_gri= 1 if s<1
replace npnns_gri = 0 if s>=1 & s<.

label var npnns_gri "i2 hors PNNS grignotage"
rename s fpj_gri
note npnns_gri:biscuits + chips <1/j. pas dans le pnns mais mesure la tendance au grignotage `tag'
note fpj_gri:biscuits + chips . pas dans le pnns mais mesure la tendance au grignotage `tag'
*plats preparés
gen s= sf_plat + sf_fast
gen npnns_pre= 1 if s<0.42
replace npnns_pre = 0 if s>=0.42 & s<.
replace npnns_pre=. if aq_modvie_refdoc!="I2"

label var npnns_pre "i2 hors PNNS plat prepare<3/sem"
rename s fpj_pre
note npnns_pre:plats complets + fastfood <3/semaine. pas dans le pnns mais mesure la tendance a consommer des repas tout prets. `tag'		 
note fpj_pre:plats complets + fastfood <3/semaine. pas dans le pnns mais mesure la tendance a consommer des repas tout prets. `tag'		 
	
/*-------------	noms spécifiques à i2 ----------------	*/

rename pnns* pnnsi2*
rename npnns* npnnsi2*

rename fpj* fpji2*


label var pnnsi2gs "Score PNNS-GS sur I2:  11 composantes"
note pnnsi2gs: calculé sur version i2 du questionnaire inclusion. cereales 	///
	completes et graisses ajoutees non calculees. `tag'

save "$temp\t_i2alim02", replace

/*-------------	manquant si pas questionnaire I2----------------	*/

foreach var of varlist fpji2_fl-pnnsi2gs *_pre *_gri	{ 
	replace `var'=. if 	aq_modvie_refdoc !="I2"	
}
/*-------------------------    FIN     ------------------------*/	
keep proj_isp fpji2_fl - pnnsi2gs *_pre *_gri sf_*

ds
sort proj_isp
compress
label data "var du pnns i2"
save "$temp\t_i2alim03", replace


