cap log close
set more off
local tag "dm03_pnnsI3_v2"
*	log  using `tag', replace text

/*---------------------------------------------------------------------------------*/
*	Marie Plessz
*	_DATE_
*	projet : CL1
/*	tache : 

* simplifie les noms de vars
* cree les composantes et le score pnns pour le questionnaire inclusion version3.
ce score est différent de celui publié dans le BEH en 2016.
différences : 
-les vars utilisées sont les vars aq_alim_freqconsoALIM_n nettoyées par 
	constances. dans BEH ces vars nettoyées s'appelaient aq_alim_freqconsoALIM2
	et il est possible qu'elles soient légèrement différentes;
-pour l'alcool j'ai utilisé la conso calculée par l'UMS (pour BEH cette partie
	du questionnaire n'avait pas été nettoyée ou du moins, l'indicateur n'était
	pas dispo).
-un certain nombre d'items ne contiennent plus les aliments allégés (produits 
	laitiers, biscuits fromages, plats cuisinés sodas)
-pour les féculents et pain on a séparé les produits complets des autres
-des items ont été ajoutés dans le fréquentiel : desserts lactés sucrés, céréales
	pdj biscuits aliments frits
-le codage des produits gras a été complètement revu
-le codage des boissons a été légèrement revu
-les fruits incluent les fruits pressés mais pas les jus ni les fruits cuits.
-on a ajouté des questions sur sel et sucre ajoutés.	

-rappel : la population dans CALICO a moins de 65 ans.	
-corrigé erreur dans alcool : les alcreco non calculés étaient évalués comme validés.
*/
*/
/*---------------------------------------------------------------------------------*/
use "$temp/t_foyvie01", clear
tab aq_modvie_refdoc
keep if aq_modvie_refdoc=="I3"
keep proj_isp age homme aq_modvie* aq_comport* aq_alim* aq_actphy* alc*	///
	age10 diplome4

save "$temp\t_i3alim01", replace

/*------------------------------    Preparation     ---------------------------*/


// 	donner des noms potables aux vars 

*simplifier le nom des vars activité physique
rename aq_actphy* actphy*

* simplifier le nom des variables freqcons
rename aq_alim_* *
rename freqcons*  f_*

*	@
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
***	2	créion de variables de nombre moyen de conso par jour à partir des vars de fréquence
***		pour I3 seulement


*nom des items du FFQ I3 seult
global v3 " viande volail poiss oeuf char laits plait dess plaital froms fromal " 
global v3 " $v3 painb  painc cereal pate riz legcru legsec" 
global v3 " $v3 fruif plac placal alfrit bissal fast patis bisc biscal beurm huil"
global v3 " $v3	cafe the jus sodaa sodaal energ"
	di "$v3"		
	
global varffq ""	
foreach k in $v3	{  // @ changer les vars sur lesquelles je fais tourner
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
Les variables finissant par "_n" ont été nettoyé par Constances: 
ces bouts de codes que j'avais avant sont devenus inutiles :
	replace s`var'=1 if `var'==6 & `var'pj==.		
		/* on suppose que les gens qui ont dit tous les jours et pas mis de 
		chiffre pensaient 1/jour	*/
	replace s`var'=. if `var'pj2>30 &  `var'pj2<.	// les codes bizarres sont manquants
*/


/*--------------------- SAUVE le fichier	--------------------------------------*/

label data "temp: alimentation+alcool+actphy pour score PNNS sur I3"
save "$temp\t_i3alim02", replace

/*-------------------------    Composantes PNNS     ---------------------------*/

*	fruits et legumes
**********************

	/*NB : Kesse et al divisent les grammes consommes par 80 pour obtenir le nb de "portions", 
	elles arrivent ࡵn taux de "guideline respectée" haut par rapport à moi ce qui est
	logique. il faudra pê changer les limites
	j'ai RETIRE les jus
	*/
	
cap drop s
gen s=sf_fruif + sf_legcru

gen pnns_fl=0 if s<3.5
replace pnns_fl=0.5 if s>=3.5 
replace pnns_fl=1 if s>=5  
replace pnns_fl=2 if s>=7.5 
replace pnns_fl=. if s==.
rename s fpj_fl
label var fpj_fl "PNNSi3: Fruits légumes fréquence"
note fpj_fl: fruits frais y compris fruits presses + legumes nb de fois par jour. `tag'

label var pnns_fl "PNNSi3: fruits légumes note. fruits frais yc presses"
note pnns_fl: fruits frais y compris fruits presses + legumes  (pas jus)>=5/j. `tag'


* pain c곩ales legumes secs
****************************
gen s=sf_painb + sf_painc + sf_legsec + sf_pate + sf_cereal + sf_riz 	///
	+ 1/3*sf_plac +  1/3*sf_placal +  1/3*sf_fast

gen pnns_fec=0 			if s<1
replace pnns_fec=0.5 	if s>=1 & s<3 
replace pnns_fec=1		if s>=3 & s<6
replace pnns_fec=0.5 	if s>=6 
replace pnns_fec=. if s==.
rename s fpj_fec
label var fpj_fec "PNNSi3: féculents fréquence"
note fpj_fec: sf_painb + sf_painc + sf_legsec + sf_pate + sf_cereal + sf_riz 	///
	+ 1/3*sf_plac +  1/3*sf_placal +  1/3*sf_fast. nb de fois par jour. `tag'

label var pnns_fec "PNNSi3 feculents"
note pnns_fec: sf_painb + sf_painc + sf_legsec + sf_pate + sf_cereal + sf_riz 	///
	+ 1/3*sf_plac +  1/3*sf_placal +  1/3*sf_fast>=3 & <6/j. `tag'

/* j'ai vérifié que l'accumulation d'items ne modifiait pas artificiellement
la note pnns_fec	*/	
	
* produits laitiers
*******************
gen s= sf_laits + sf_plait  /* + sf_dess */ + sf_plaital + sf_froms  + sf_fromal
gen pnns_lai=0			if s<1
replace pnns_lai=0.5 	if s>=1 & s<2.5
replace pnns_lai=1		if s>=2.5 & s<=3.5
replace pnns_lai=0		if s>3.5 
replace pnns_lai=1		if s>=2.5 & s<=4.5 	& age>54 & age<.
replace pnns_lai=0		if s>4.5 			& age>54 & age<.
replace pnns_lai=.		if s==.

rename s fpj_lai
label var fpj_lai "PNNSi3: produits laitiers fréquence"
note fpj_lai: sf_laits + sf_plait  /* + sf_dess */ + sf_plaital + sf_froms 	///
	+ sf_fromal. `tag'
label var pnns_lai "PNNSi3 produits laitiers"
note pnns_lai: produits laitiers >=3.5/j. 4.5 si age>54. ///
	sf_laits + sf_plait /* + sf_dess */ + sf_plaital + sf_froms  + sf_fromal.  `tag'
note pnns_lai: exclu les desserts lactés car dans ENNS ils ne figurent pas ds ///
	liste produits laitiers. 

* VPO : viandes, poisson, oeuf
*********
gen s= sf_viande + sf_volail+ sf_poiss +sf_oeuf + 1/3*sf_plac + 1/3*sf_placal

gen pnns_vpo = 0		if s==0
replace pnns_vpo=0.5	if s>0 & s<1
replace pnns_vpo=1	if s>=1 & s<=2
replace pnns_vpo=0	if s>2 
replace pnns_vpo=. if s==.
rename s fpj_vpo
label var fpj_vpo "PNNSi3: VPO fréquence"
note fpj_vpo: sf_viande + sf_volail+ sf_poiss +sf_oeuf + 1/3*sf_plac 	///
	+ 1/3*sf_placal. `tag'
label var pnns_vpo "PNNSi3 VPO"
note pnns_vpo: viande, volaille, poisson, oeuf 1 à 2/j. charcuteries exclues. `tag'
* poisson
*********

gen pnns_poi=0		if f_poiss_n<4
replace pnns_poi=1	if f_poiss_n>=4 & f_poiss_n<9
replace pnns_poi=. if f_poiss_n==.
	/* attention je code par rapport f_poi, la variable sur les fréquences< 
	1 fois par jour.	*/
label var pnns_poi "PNNSi3 poisson"
note pnns_poi : poisson 2 fois/semaine. `tag'

* sucres provenant des aliments sucres
**************************************
/* ==> j'ai retire les boissons	
*/
recode nbsucre_n (1 2=0) (3 4=1), gen(nbsuc3plus)
gen s=sf_bisc + sf_patis + sf_dess  + nbsuc3plus

	*je ne peux pas utiliser la norme d'Emmanuelle Kesse (en % des EI); 
	*je propose
	*0 si >1 produits sucres/jour et -0.5 si >2 produits sucres / jour
	* i3 : inclure sucre en morceaux (3 ou plus = 1 produit sucre)
gen pnns_suc=1 			if s<1
replace pnns_suc=0 		if s>=1 & s<.
replace pnns_suc=-0.5	if s>2
replace pnns_suc=. 		if s==.
rename s fpj_suc
label var fpj_suc "PNNSi3: alim sucre frequence"
note fpj_suc : sf_bisc + sf_patis + sf_dess + nbsuc3plus. 	///
	nbsuc3plus=1 si nbsucre_n=3 ou 4. `tag'
label var pnns_suc "PNNSi3 alim sucre"
note pnns_suc: produits sucres<1/j. sf_bisc + sf_patis + sf_dess. `tag'
drop nbsuc3plus


* graisses ajoutees
*******************
gen s=sf_huil + sf_beurm

gen pnns_gra=1 			if s<=2
replace pnns_gra=0 if s>2
replace pnns_gra=. 		if s==.
rename s fpj_gra
label var fpj_gra "PNNSi3: graisses ajoutees frequence"
note fpj_gra: sf_huil + sf_beurm. les produits gras ne sont pas inclus dans  ///
	le score pnns-gs. `tag'
label var pnns_gra "PNNSi3 limiter graisses ajoutees"	
note pnns_gra: sf_huil + sf_beurm<=2/j. les produits gras ne sont pas inclus dans  ///
	le score pnns-gs. dans ENNS 90% des adultes ont des apports en graisses ajoutes ///
 conformes aux reco. `tag'


* graisses vegetales
********************
/* c très compliqué : on a une var pour la mat grasse préférée pour la cuisson
et 2 vars de fréquence mais le beurre et la margarine ont été mis ensemble, vs huile.
*/

gen gvec= typgras_n>2 
replace gvec=. if  typgras_n >9

gen gvef=sf_beurm<=sf_huil
replace gvef=. if sf_beurm==.
replace gvef=. if sf_huil==.

gen pnns_gve=gvec * gvef==1
replace pnns_gve=. if gvec==. | gvef==.

label var pnns_gve "PNNSi3 pref graisse vegetale"
note pnns_gve: vaut 1 si [typgras_n (mat grasse cuisson) pas beurre ni beurre ///
	allege] ET [sf_beurm<=sf_huil]. compliqué : on a une var pour la mat 	///
	grasse préférée pour la cuisson et 2 vars de fréquence mais le beurre ///
	et la margarine ont été mis ensemble, vs huile. `tag'.

drop gvec gvef

* boissons sucrees
**********
	*soda, jus de fruits et boissons energisantes
	
gen s=sf_sodaa + sf_energ + sf_jus
gen pnns_boi=1 			if s<1
replace pnns_boi=0 		if s>=1 
replace pnns_boi=. 		if s==.
rename s fpj_boi
label var pnns_boi "PNNSi3 boissons sucrees"
note pnns_boi: boissons sucrees (soda, nrj, jus) <1/jour. sodas light exclus. `tag'
label var fpj_boi "PNNSi3 boissons sucrees freq/j"
note fpj_boi: sf_sodaa + sf_energ + sf_jus. sodas light exclus. `tag'

* alcool
********
gen pnns_alc=alcreco
recode pnns_alc (1=1) (2=0.8) (3=0) (4=.)
/* alcreco est la copie numérique de aq_comport_alcrecommandation_i */
label val pnns_alc
label var pnns_alc "PNNSi3 alcool"
note pnns_alc: copie de alcrecommandation_i avec les valeurs pour score ///
	pnns. (1=1) (2=0.8) (3=0)  (4=.) classe reco correspond aux reco du pnns-gs. `tag'
	
gen fpj_alc=alcvj
label var fpj_alc "PNNSi3: nb verres moy/j au minimum"
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
	*  Sebastien czernichow: sel ajoute	=20% apports en sel.
	* 1 = pas tous les jours des aliments sal곉
gen s=sf_char +  sf_froms + sf_bissal + sf_fast

gen pnns_sel	=1		if s<1
replace pnns_sel=0	if  s>=1 
replace pnns_sel=. if s==.
replace pnns_sel=0 if mangesale_n==1		//specifiq i3 : sel ajoute

label var pnns_sel "PNNSi3 sel"
note pnns_sel: PNNSi3 charcuterie+fromage+biscuitssales+fastfood: <1/j ET	///
	mangesale_n<1. `tag'
rename s fpj_sel
label var fpj_sel "PNNSi3: alim tres sales frequence"
note fpj_sel: PNNSi3 : fréq conso alim tres sales. attention repere tient ///
	aussi compte du sel ajoute. sf_char + sf_froms + sf_bissal + sf_fast. `tag'
	
*activite physique hors travail
*******************************

	* trajets, sports, bricolage
	* j'essaie de calculer un temps d'activite physique par semaine.
		*trajets	
gen st=actphy_12mtrjpdbychbd_n
replace st=21 if st>21		
	/* plus de 21 trajets par semaine paraﴠirrꢬiste	*/
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
note h_trajet: Trajets: calcul d'activité physique ramenée à un nombre d'heures par semaine pour le pnns. `tag'
note h_sport: Sport: calcul d'activité physique ramenée à un nombre d'heures par semaine pour le pnns. `tag'
note h_odd: Odd-jobs: calcul d'activité physique ramenée à un nombre d'heures par semaine pour le pnns. `tag'
note h_ap: h_ap=h_trajet + h_sport + h_odd	. `tag'

label var pnns_ap "PNNSi3 activite physique"
note  pnns_ap: base sur une mesure qualitative construite ࡰartir des trajets, 	///
	du sport et des travaux domestiques. `tag'
drop st // h_*

*cereales completes
*******************************
*reco : 1/3 des cereales completes.
gen s=sf_riz + sf_painc

gen t=(s)/ fpj_fec
gen pnns_comp=t>1/3
replace pnns_comp=. if t==.
label var pnns_comp "PNNSi3: 1/3 cereales completes"
note pnns_comp: (sf_riz + sf_painc)/ fpj_fec >1/3. `tag'

rename s fpj_comp
label var fpj_comp "PNNSi3: cereales completes freq/j"
note fpj_comp: sf_riz + sf_painc. `tag'

drop t

/*-------------------------    score PNNS-GS     ------------------------*/	
gen pnnsgs= pnns_fl + pnns_lai +  pnns_poi +   pnns_suc  +    pnns_alc      ///
		 + pnns_ap + pnns_fec + pnns_vpo + pnns_gve + pnns_boi + pnns_sel ///
		 + pnns_comp + pnns_gra
		 
		 
**********************************************************************		 
/*----------------  items "convenience"  --------------------*/		 
**********************************************************************	

	// dans I3
* grignotage	
	gen s= sf_bisc + sf_bissal
gen npnns_gri= 1 if s<1
replace npnns_gri = 0 if s>=1 & s<.
label var npnns_gri "i3 hors PNNS grignotage"
rename s fpj_gri
note npnns_gri:biscuits + chips <1/j. hors allégé pas dans le pnns mais 	///
	mesure la tendance au grignotage `tag'
note fpj_gri:biscuits + chips hors allégé. pas dans le pnns mais mesure 	///
	la tendance au grignotage `tag'

*plats preparés
gen s= sf_plac + sf_fast
gen npnns_pre= 1 if s<0.42
replace npnns_pre = 0 if s>=0.42 & s<.

label var npnns_pre "i3 hors PNNS plat prepare<3/sem"
rename s fpj_pre
note npnns_pre:plats complets hors allégé + fastfood <3/semaine. pas dans	///
	 le pnns mais mesure la tendance a consommer des repas tout prets. `tag'		 
note fpj_pre:plats complets hors allégé + fastfood <3/semaine. pas dans 	///
	le pnns mais mesure la tendance a consommer des repas tout prets. `tag'		 

*light
cap drop l1 l2 l3
gen l1=sf_plaital - (sf_plait + sf_dess)
gen l2=sf_placal - sf_plac
gen l3=sf_biscal - sf_bisc
gen l4= sf_sodaal - sf_sodaa
recode l1 l2 l3 l4 (min / 0=0)(0/ max=1)
gen npnns_lig= (l1==1 | l2==1 | l3==1 | l4==1)
replace npnns_lig=. if ( l1==. & l2==. & l3==. & l4==.)

label var npnns_lig "i3 hors PNNS light"
note npnns_lig: vaut 1 si consomme plus de light que de normal dans au moins 1 ///
	des trois types de produits mesurés: laitagages 	///
	(sf_plaital - (sf_plait + sf_dess); biscuits sucrés; plats préparés; sodas. `tag'

drop l1-l4

**********************************************************************	
/*-------------	noms spécifiques à i3 ----------------	*/
**********************************************************************
rename pnns* pnnsi3*
rename fpj* fpji3*
rename npnns* npnnsi3*

label var pnnsi3gs "Score PNNS-GS sur I3: 13 composantes"	
note pnnsi3gs: calculé sur version i3 du questionnaire inclusion.


/*-------------	manquant si pas questionnaire I3----------------	*/

foreach var of varlist fpji3_fl-pnnsi3gs *pre *gri *_lig	{ 
	replace `var'=. if 	aq_modvie_refdoc !="I3"	
}
save "$temp\t_i3alim02", replace
/*-------------------------    FIN     ------------------------*/	

keep proj_isp fpji3_fl - pnnsi3gs *pre *gri *_lig sf_*
rename sf_* sf3_*
ds
sort proj_isp 
compress
label data "var du pnns i3"
save "$temp\t_i3alim03", replace


