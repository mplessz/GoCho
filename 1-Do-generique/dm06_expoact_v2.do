cap log close
set more off
local tag "dm06_expoact_v2"
*	log  using _nomprogramme_, replace text

/*---------------------------------------------------------------------------------*/
*	Marie Plessz
*	19/10/2017
*	projet : CLC2
*	tache : recodages de expoact : situation d'emploi et csp volontaire

* v2 : ajouté des combinaisons qui n'existaient pas encore (dans emploi+cho)
/*---------------------------------------------------------------------------------*/

use "$cree\DATA_EXPO_01", clear

/*---------------------	Preparer les variables  ---------------*/

rename (aq_expoact_dtremp aq_expoact_refdoc suivi_rep_exp) (v1	v2 v3)
		
rename aq_expoact_* *
rename (v1	v2 v3)(expoact_dtremp expoact_refdoc suivi_rep_exp)
local varkeep "proj_isp  expoact_dtremp expoact_refdoc  suivi_rep_exp"
	
/*------------------------  situation emploi  ---------------------------*/

// une var très détaillée : chaque combinaison est un code différent
tostring(sitprof1-sitprof9), gen(sp1 sp2 sp3 sp4 sp5 sp6  sp9)
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
		".C...Ia", ".C..S..", ".C..S.a", ".C..SI.", ".C..SIa") 
	// chomage+emploi
replace emploi=4 if inlist(spcomb, ".C....a",  "EC.....", "EC....a", ///
		"EC...I.", "EC..S..", "EC.F...", "EC.FS..", "EC.F..a" )
replace emploi=4 if inlist(spcomb, 	"E.....a", "E....I.", "E...S..", "E...SI.", "EC...Ia", "E...S.a",  ".CRF..a")
		//retraite y compris chô : tous codes contenant R
replace emploi=-1 if inlist(spcomb,	 "..R....", "..R...a", "..R..I.", "..R.S..", ///
		"..R.SI.", "..RF...",  ".CR....",  "..R.S.a"  )
replace emploi=-1 if inlist(spcomb,	".CR...a", ".CR..I.", ".CR.S..", "ECR....", ///
"E.R....",  "E.R...a", "E.R.SI.", "E.RF...")
replace emploi=-1 if inlist(spcomb, "..R..Ia", ".CRF.I.", "..R.S.a" )
	//formation non demandeur d'emploi
replace emploi=-2 if inlist(spcomb, "...F...",  "...F..a",  "...F.I.", "...F.Ia", ///
		"...FS.." , "E..F...", "E..F..a"   )
	//autre
replace emploi=-3 if inlist(spcomb, ".....Ia",  "....S.a", "....SIa", ".C.FS..")
*replace emploi=-3 if inlist(spcomb,	 )
 
replace emploi= 3 if cspactmax ==7 & emploi==1
	// on ne peut pas être sans profession ds csp act ou + lg et en emploi. 
 *(2 real changes made)

label var emploi "Sit. emploi"
label def emploi 1 "En emploi" 2 "Demandeur d'emploi sans emploi" ///
	3 "Sans act.pro" 4 "Emploi+cho/sansempl"	///
	-1 "Retraite" -2 "Etudiant sf dmd emploi" -3 "Autre" , modify
label val emploi emploi

tab emploi
tab spcomb emploi, mis
	// verifie qu'aucune modalité de spcomb n'a été oubliee.
count if spcomb !="" & (emploi==-9)
assert r(N)==0 	//  erreur si oubli.

* sante : à peaufiner quand data cnav/
gen inacsante=sitprof5==1
replace inacsante=. if emploi==.
label var inacsante "Decl. travaille pas car sante?"
label val inacsante Lon01
note inacsante: sitprof5==1. `tag'


/*	CSP	*/
/*gen csp=cspactmax
recode csp (9/max=.)
label var csp "CSP actuelle ou plus longue"
*label val csp Lcsp
note csp: recodage de cspactmax : CSP actuelle ou la plus longuement occupee ///
	si hors emploi. `tag'
*/

gen cspvol=cspactmax
recode cspvol (1 2 8=1) (9/max=.)
label var cspvol "CSP actuelle ou plus longue"
label def cspvol	///
1 "Agric, Indé, Autre"								///
3   "Cadre, prof. intell. sup."	///
4   "Profession intermédiaire"						///
5   "Employé" 										///
6   "Ouvrier" 										///
7   "Sans profession" 								///
, modify 

label val cspvol cspvol
local varkeep "`varkeep'  emploi spcomb  sp1-sp9 cspvol"
note cspvol:  recodage de cspactmax : CSP actuelle ou la plus longuement occupee ///
	si hors emploi. `tag'

/*	caracteristiques emploi	*/
clonevar prive=employeur
recode prive (1/4=0)(5=1) (6/max=.)


label var prive "Employeur prive?"
label def prive 0 "Public ou assimile" 1 "Prive"
label val prive prive
note prive: recode de employeur. tout autre employeur que ///
	"entreprise privee" a ete considere comme public. `tag'

clonevar inde=statut
recode inde (1 2=1) (3=0) (4/max=.)
label var inde "Statut independant?"
label def inde 0 "Salarie" 1 "Independant"
label val inde inde
note inde: recode de statut. `tag'

clonevar partiel=trtpscplet    
recode partiel (2=1)(1=0)(else=.)
label var partiel "Travail: temps partiel?"
label def partiel 1 "Partiel" 0 "Complet"
label val partiel partiel
note partiel: expoact_trtpscplet   . `tag' 
local varkeep "`varkeep' prive inde partiel"


/*	intensite effort physique au travail	*/
clonevar traveff=trevalinteff
recode traveff (21/max=.)
label def traveff 	///
	6  "6_pas deffort du tout"	///
	7  "7_extremement leger"	///
	9  "9_tres leger"	///
	11 "11_leger"	///
	13 "13_un peu dur"	///
	15 "15_dur"	///
	17 "17_tredur"	///
	19 "19_extremement dur"	///
	20 "20_epuisant"	///
	, modify
label val traveff traveff
label var traveff "Travail: intensite effort physique percu"
local varkeep "`varkeep' prive inde partiel traveff "
note traveff : trevalinteff. `tag'


/* horaires contraints */
gen contrainth=1 if trchxh==1
replace contrainth=2 if trchxh==1 & trpointer==1
replace contrainth=3 if trchxh==2 & trpointer==2
replace contrainth=4 if trchxh==2 & trpointer==1
replace contrainth=. if trchxh>9

label var contrainth "Horaires contraints?"
label def contrainth 1 "Choix" 2 "Chx pointer" 3 "Ctraint"  ///
	4 "Ctrt pointer", modify
label val contrainth contrainth
note contrainth: combinaison de trchxh et trpointer. `tag'
local varkeep "`varkeep' trevalinteff contrainth"
/*---------------------- Fin  ----------------------------*/
di "`varkeep'"
keep `varkeep'
sort proj_isp
compress
codebook , compact

save "$temp/t_expoact01", replace
label data "Variables tirees du questionnaire expoact"
note _dta: variables crees a partir du questionnaire expositions professionnelles : `varkeep' / `tag'/ $S_DATE.
