cap log close
set more off
local tag "dm02_foyvie"
*	log  using _nomprogramme_, replace text

/*----------------------------------------------------------------------------*/
*	Marie Plessz
*	06/11/2018
*	projet : CMP
*	tache :recodages caracteristiques sociodemo

*V2 : vars sociodemo ont été nettoyées.
/*si pas nettoyées revenir à V1	*/
/*----------------------------------------------------------------------------*/

use "$cree\DATA_MDV_01", clear

/*---------------------- ajouter sexe et age de pop--------------*/
merge 1:1 proj_isp using "$cree\DATA_POP_01"

/*
    Result                           # of obs.
    -----------------------------------------
    not matched                            32
        from master                         0  (_merge==1)
        from using                         32  (_merge==2)

    matched                            58,578  (_merge==3)
    -----------------------------------------
*/

tab _merge suivi_rep_mdv, mis
/*

                      |   SUIVI-AQ Mode de
                      |       vie-Reçu
               _merge |       Oui          . |     Total
----------------------+----------------------+----------
       using only (2) |         0         32 |        32 
          matched (3) |    58,578          0 |    58,578 
----------------------+----------------------+----------
                Total |    58,578         32 |    58,610 
*/
*==> 32 obs sont foireuses, même la var "MDV envoyé" n'est pas remplie.
* virer les 32 obs foireuses. l'échantillon qui était de 50 000 est now de 58 000
keep if _merge==3
count 
* ==>  58,578

drop _merge

/*---------------------   age et sexe  -------------------*/

clonevar age=fm_incluage
label var age "Age inclusion"
note age : =fm_incluage. `tag'

*	age10 : Classes d'age
gen age10=int(age/10)*10
recode age10(10=20) 

label var age10 "Classe d'age inclusion"
label def age10 	///
	20 "18-29 ans"	///
	30 "30-39 ans"	///
	40 "40-49 ans"	///
	50 "50-59 ans"	///
	60 "60-69 ans"	///	
	70 "70-79 ans" ///
	, modify
label val age10 age10
note age10 : recodage en classes de 10 ans de la variable age. attention si des pers depassent 79 ans. `tag'

*	homme : sexe en 0 1
clonevar homme=fm_sexe
recode homme (2=0)
label var homme "Sexe: homme?"
label def homme 1 "Homme" 0 "Femme", modify
label val homme homme
note homme: recode de fm_sexe, hommes toujours 1, femmes 0.  `tag'

local vardrop "fm_incluage fm_sexe "


********    REVENU PAR unité de consommation du foyer   ***************
/* voir mon document du 13/07/2016 transmis à l'UMS*/
*	http://www.insee.fr/fr/methodes/default.asp?page=definitions/unite-consommation.htm

/*	#1	recoder les tranches de revenu : 
je prends la borne sup de la tranche la plus basse
le milieu des tranches intermédiaires
1.5 fois la borne inf de la tranche la plus haute, après avoir comparé avec 
	d'autres alternatives (1 fois la borne inf; une approximation par la courbe
	de pareto qui valait 7796 euros dans mon échantillon
*/
gen r=aq_foyvie_revenumont_n
recode r(1=450) 	/// tranche basse : borne sup
	(2= 725) (3 =1250) (4 =  1800) (5 = 2450) (6 = 3500) 	///
	(7=6750)	/// tranche haute : 1.5 fois la borne inf
	(8 9=.)

*	#2	 nombre d'enfants: 
/* dans l'échelle de l'OCDE les enfants sont les membres du foyer âgés de moins
de 14 ans. je n'ai pas l'info sur l'âge des enfants donc je considère tous les 
"enfants" vivant dans le ménage comme des enfants.
*/

gen enf=aq_foyvie_avecenfnb_n
replace enf=0 if aq_foyvie_avecenf_n==2

*	#3	nombre d'adultes en dehors de l'enquêté
* les ascendants sont forcément des adultes.
gen a1=aq_foyvie_avecascnb_n
replace a1=0 if aq_foyvie_avecascnb_n==.

* je considère toutes les "autres pers" comme des adultes
gen a2=aq_foyvie_avecautnb_n
replace a2=0 if aq_foyvie_avecautnb_n==.
replace a2=10 if aq_foyvie_avecautnb_n>10 & aq_foyvie_avecautnb_n<.
*si quelqu'un a coché "oui" à avecautre mais n'a indiqué aucun chiffre, a1 + a2 =0
* le nb de cohabitants hors enfants, conjoints et ascendants est borné à 10

* présence d'un conjoint:
gen a3=aq_foyvie_aveccouple_n
recode a3 (1=1) (2=0)

* nb d'adultes en dehors de l'enquêté: conjoint + éventuels ascendants et autres.
gen adu= a1 +a2 +a3

/* 	#4	Nombre d'UC dans le ménage
échelle OCDE (employée aussi par l'insee, voir lien plus haut).
1er adulte (ici l'enquêté) : 1
autres adultes : 0.5
enfants 0.3
(en théorie enfant doit être <14 ans. enfants >= 14 ans sont considérés comme adultes.
*/
gen uc=1+0.5*(adu)+0.3*enf 

*	#5	Revenu par unité de consommation
gen revenuuc= r/uc	
label var revenuuc "Revenu du ménage par unité de consommation (euros/mois)"
note revenuuc: tranche inf = borne sup. tranche sup = 1,5* borne inf. UC : ///
	échelle OCDE (utilisée par insee): 1 +0.5* autres adultes + 0.3* autres enfants. `tag'

gen logrevuc=ln(revenuuc)
label var logrevuc  "Log du revenu ménage/UC"
note logrevuc: =ln(revenuuc). `tag'

/* revenu médian par UC en 2013 : 20 000/12=1666
http://www.insee.fr/fr/themes/tableau.asp?reg_id=0&ref_id=NATTEF04267
*/
gen revuccent=revenuuc-1666
label var revuccent "Revenu/UC du ménage centré sur mediane Fce 2013"
note revuccent : revenuuc-1666. revenu médian par UC en Fce en 2013 (INSEE).`tag'

gen logrevuccent=logrevuc - log(1666)
label var logrevuccent "Log du revenu/UC moins log mediane Fce 2013"
note logrevuccent : logrevuc - log(1666) `tag'
drop r a1 a2 a3 enf adu uc


/*---------------------   renommer variables  -------------------*/


desc, fullnames
unab foyvie:  aq_foyvie_*
rename aq_foyvie_* *
describe, fullnames

/*-----------------  recodages sociodemographiques sur foyvie  -----------------*/

/*------------------------      Labels pas encore utilises    ------------------------*/

label define Lon01 /// Pour toutes les questions avec comme réponses : oui 1 / non 0 
	1 "Oui"	///
	0 "Non"	///
	, modify 


label define Lcsp	///
1   "Agriculteur exploitant"						///
2   "Artisant, commercant, chef d'entreprise"		///
3   "Cadre, profession intellectuelle superieure"	///
4   "Profession intermediaire"						///
5   "Employe" 										///
6   "Ouvrier" 										///
7   "Sans profession" 								///
8   "Autres"										///
9   "Ne peut pas repondre"							///
, modify 
/*-------------------------------      SOCIO-DEMO     ----------------------------*/

*	type de ménage
gen typmen=10*aveccouple_n+ avecenf_n
recode typmen(11=1) (12=2)(21=3) (22=4)
replace typmen=5 if avecautre_n==1 

label var typmen "Type de menage"
label def typmen 		///
		1 	"Couple + enfant(s)"	///
		2	"Couple sans enfant" 	///
		3	"Celib avec enfant"	///
		4	"Celib sans enfant"	///
		5	"Menage complexe"	///
		, modify
label val typmen typmen 
note typmen : type de menage : avec ou sans enfant, vit en couple ou non. ///
	si vit avec d'autres 	pers, forcément ménage complexe. `tag'

* aveccouple01  : vit en couple 01
gen aveccouple01=aveccouple_n
recode aveccouple01 (2=0)
label var aveccouple01 "Vit en couple? 0/1"
label val aveccouple01 Lon01
note aveccouple01: `tag' 

*avecenf01 : vit ac des enfants en 01
gen avecenf01=avecenf_n
recode	avecenf01 (2=0)
label var avecenf01 "Vit avec enfants? 0/1"
label val avecenf01 Lon01
note avecenf01: `tag' 

	
local vardrop "`vardrop' sitfam_n avecenf_n avecautre_n aveccouple_n  "

*	diplome2 
clonevar diplome2=diplome_n

recode diplome2 (1 2 3=1) (4=2) (5=3) (6 7=4) (8=5)
label define diplome2	///
	1   "< bac"  		///
	2   "Bac"  			///
	3   "Bac +2 ou +3"  /// 
	4   "Bac +4 ou plus"  ///
	5   "Autre diplome"  ///
	, modify 
label value diplome2 diplome2

label var diplome2 "Diplome recodé"
note diplome2: copie de diplome. regroupé les modalités et mis en manquantes les codes multiples. `tag'

clonevar diplome3=diplome_n
recode diplome3 (1 2 8=0 )( 3=1) (4=2) (5=3) (6 7=4) 
label define diplome3	///
	0	"BEPC ou inf"	///
	1   "BEP CAP"  		///
	2   "Bac"  			///
	3   "Bac +2 ou +3"  /// 
	4   "Bac +4 ou plus"  ///
	, modify 
label value diplome3 diplome3

label var diplome3 "Diplome 5 cat bas"
note diplome3: copie de diplome. regroupé les modalités et mis en manquantes les codes multiples. 	///
	2 niveaux sous bac et autres avec le plus faible. `tag'


clonevar diplome4=diplome_n
recode diplome4 (1 2 3 8=1) (4=2) (5=3) (6 7=4) 
label define diplome4	///
	1   "< bac"  		///
	2   "Bac"  			///
	3   "Bac +2 ou +3"  /// 
	4   "Bac +4 ou plus"  ///
	, modify 
label value diplome4 diplome4

label var diplome4 "Diplome"
note diplome4: copie de diplome. regroupé les modalités et mis en manquantes les codes multiples. 	///
	autres diplomes avec les inf au bac. `tag'
	
	
local vardrop "`vardrop' diplome_n "

*	diplomesup
recode diplome2 ( 1 2 5=0) (3 4=1), gen(diplomesup)
label var diplomesup "Diplome > bac?"
label def diplsup 0 "0 =< bac" 1 "1 >Bac", modify
label value diplomesup diplsup
note diplomesup: version dichotomique de diplome2. `tag'


*	difffinmois
label def difffinmois_n 1"Non jamais" 2 "Avant oui" 3 "Oui <1 an" 	///
	4 "Oui pls annees", modify
label val difffinmois_n difffinmois_n

recode difffinmois_n(1 2=0)(3 4=1) (99/max=.), gen(diffinnow)
label val diffinnow Lon01
label var diffinnow "Difficultes financieres actuelt"
note diffinnow: recode de difffinmoins sur difficultés actuelles

* conjemploi
gen conjemploi=.
replace conjemploi=0 if aveccouple01==0
replace conjemploi=1 if conjsitempl==1
replace conjemploi=2 if conjsitdem==1 |   conjsitretr==1 |  conjsitform==1 | ///
	conjsitsant==1 |  conjsitfoy==1
label var conjemploi "Conjoint en emploi?"
label def conjemploi 0 "Sans conjoint" 1 "Cjt en emploi" 	///
	2 "Cjt Sans emploi", modify
label val conjemploi conjemploi
note conjemploi: recode de la Q choix multiple conjsitxxx. si a coche emploi ///
	et autre chose, codé comme autre chose. `tag'
	
*	conjcsp2
recode conjcsp_n (7 8  =7)(.=0), gen(conjcsp2)
replace conjcsp2=7 if conjcsp2==. &	conjemploi==2 
label copy  Lcsp Lcspautre
label def Lcspautre 7 "hors emploi/autre" 0 "Non concerne/mqt", modify
label val conjcsp2 Lcspautre
label var conjcsp2 "CSP conjoint"
note conjcsp2: conjcsp_n. manquantes =0. manquantes =7 si conjemploi==2 `tag'
local vardrop "`vardrop' conjsit* conjcsp_n "

*	csppereado2
recode csppereado_n (7 8=7) (9/max . =0), gen(csppereado2)
label val csppereado2 Lcspautre
label var csppereado2 "CSP pere pdt adolescence"
note csppereado2: copie de csppereado_n, modalités 7 8 regroupées, modalités 9xxx regroupées avec les manquantes. `tag'

*	cspmereado2
recode cspmereado_n (7 8=7) (9/max . =0), gen(cspmereado2)
label val cspmereado2 Lcspautre
label var cspmereado2 "CSP mere pdt adolescence"
note cspmereado2: copie de cspmereado_n, modalites 7 8 regroupees, 	///
	modalites 9xxx regroupee avec les manquantes. `tag'

local vardrop "`vardrop'  csppereado_n cspmereado_n conjcspps_n"
local vardrop "`vardrop' csppereadops_n  cspmereadops_n  diplomeps_n "

/** cesnum
/!|\ ne pas utiliser cette méthode : avec l'ajout de ces, l'ordre des modalités change.
Je code directt à partir de la variable string.

encode fm_ces_inclusion , gen(cesnum)
label var cesnum "CES inclusion"
note cesnum:version numerique de fm_ces_inclusion. `tag'
local vardrop "`vardrop' fm_ces_inclusion "

* region
/*cesnum	CES		region	label
1	ANGOULEME		3	Sud-Ouest
2	BORDEAUX		3	Sud-Ouest
3	LILLE			2	Nord Est
4	LYON			4	Sud-Est
5	MARSEILLE		4	Sud-Est
6	NANCY			2	Nord Est
7	NIMES			4	Sud-Est
8	ORLEANS			6	Centre
9	PARIS-CPAM		1	Paris
10	PARIS-IPC		1	Paris
11	PAU				3	Sud-Ouest
12	POITIERS		6	Centre
13	RENNES			5	Ouest
14	SAINT-BRIEUC	5	Ouest
15	SAINT-NAZAIRE	5	Ouest
16	TOULOUSE		3	Sud-Ouest
17	TOURS-LA RICHE	6	Centre
*/
/*
*/
*/
gen region=99
replace region=1 if fm_ces_inclusion =="PARIS-CPAM"
replace region=1 if fm_ces_inclusion =="PARIS-IPC"
replace region=2 if fm_ces_inclusion =="LILLE"
replace region=2 if fm_ces_inclusion =="NANCY"
replace region=3 if fm_ces_inclusion =="ANGOULEME"
replace region=3 if fm_ces_inclusion =="BORDEAUX"
replace region=3 if fm_ces_inclusion =="PAU"
replace region=3 if fm_ces_inclusion =="TOULOUSE"
replace region=4 if fm_ces_inclusion =="LYON"
replace region=4 if fm_ces_inclusion =="MARSEILLE"
replace region=4 if fm_ces_inclusion =="NIMES"
replace region=5 if fm_ces_inclusion =="RENNES"
replace region=5 if fm_ces_inclusion =="SAINT-BRIEUC"
replace region=5 if fm_ces_inclusion =="SAINT-NAZAIRE"
replace region=6 if fm_ces_inclusion =="ORLEANS"
replace region=6 if fm_ces_inclusion =="TOURS-LA RICHE"
replace region=6 if fm_ces_inclusion =="POITIERS"
replace region=6 if fm_ces_inclusion =="LE MANS"
replace region=6 if fm_ces_inclusion =="AUXERRE"
replace region=2 if fm_ces_inclusion =="HAUT-RHIN"
replace region=5 if fm_ces_inclusion =="CAEN"


label def region 1 "Paris" 2 "Nord Est" 3 "Sud-ouest" ///
4 "Sud-Est" 5 "Bretagne" 6 "Centre", modify
label val region region
label var region "Région du CES"

* annee remplissage q°r
gen mdv_annee= year(aq_modvie_dtremp_n)
note mdv_annee: recode de aq_modvie_dtremp_n. `tag' 
label var mdv_annee "MDV dtremp regroupee"	
/*-----------------------------      FIN     ----------------------------*/
save "$temp\t_foyvie01_verif", replace

di "`vardrop'"
 drop `vardrop'  avecascnb_n avecautnb_n  

quietly compress
desc
sort proj_isp
label data "foyvie recode sociodemo"
note _dta: recodage et creation de variables utiles. variables anciennes 	///
	supprimees. `tag'
save "$temp\t_foyvie01", replace
