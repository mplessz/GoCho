*******************************************************************************
*	Marie Plessz
*	19/10/2017
*	projet : CLC2
* Tache : préparer data Calendrier pro 
/*
		- éliminer indv qui n'ont pas répondu
		- recoder épisodes chômage et santé
		- jamais travaillé
*/
******************************************************************************
local tag "dm06b_cprofp_v2"


*-----------    calendrier pro, partie en-tête    ------------------*
* ouvrir le calendrier pro, partie en-tête.
use "$cree/DATA_CP", clear
tab suivi_env_cp, mis
tab suivi_rep_cp, mis
	*  329 indv ont reçu CP mais l'ont pas renvoyé.

tab  aq_cprof_dejatrav, mis
	
* dates de remplissage :
sum aq_cprof_dtrempl, det format
	/* il ya des erreurs (2000, 2024) mais j'ai vérifié : tout "merge ac mes
	données MDV 
	*/

*-----------    calendrier pro, Episodes   ------------------*	
* ouvrir le calendrier pro, partie avec les épisodes successifs.
use "$cree/DATA_CPPER", clear

* caractéristiques base de données
count
tab aq_cprofp_numemploi, mis	// nombre d'individus?
tab aq_cprofp_refdoc		// une ou plusieurs versions du questionnaire?
sum aq_cprof_dtrempl, format 	//date min et max de remplissage


/*renommer les variables
rename aq_cprofp_* *
rename refdoc aq_cprofp_refdoc
rename dtrempl aq_cprof_dtrempl
*/

* identifier ligne dernier emploi
bys proj_isp (aq_cprofp_numemploi): gen last= _n==_N
tab last


* nb total interruptions 6 mois et plus: attention pls motifs peuvent être cochés 
egen s = rowtotal(aq_cprofp_interupmotif1 aq_cprofp_interupmotif2 aq_cprofp_interupmotif3)
recode s (0=0) (else= 1) 
bys proj_isp : egen nstop= sum(s)
label var nstop "cp: nombre arrêts>6mois declarés"
tab nstop if last==1
drop s

*@ question : est-ce que des femmes ont mis congés mat dans santé? auquel cas on peut pas les exclure !!!!!


* recoder les épisodes autres
count if aq_cprofp_interupmotif3==1
*maternité
cap drop m-s2

foreach typo in GROCESSE GROSESSE GROSSECE GROSSES GROSSESE GROSSESSSE GROSSES {
	replace aq_cprofp_interupmotifps= subinstr(aq_cprofp_interupmotifps,"`typo'","GROSSESSE", .)
}

gen m=1 if	strpos(aq_cprofp_interupmotifps, "MATER") |  ///
	strpos(aq_cprofp_interupmotifps, "GROSSESSE") | strpos(aq_cprofp_interupmotifps, "ENFANT") | ///
	strpos(aq_cprofp_interupmotifps, "CONGE MAT") | strpos(aq_cprofp_interupmotifps, "BEBE") | ///
	strpos(aq_cprofp_interupmotifps, "PARENTAL") |  strpos(aq_cprofp_interupmotifps, "AU FOYER") ///
	|  strpos(aq_cprofp_interupmotifps, "ENCEINTE") | strpos(aq_cprofp_interupmotifps, "NAISSANCE") ///
	| strpos(aq_cprofp_interupmotifps, "CONGES MAT") | strpos(aq_cprofp_interupmotifps, "ACCOUCHE") ///
	| strpos(aq_cprofp_interupmotifps, "ADOPTION") | strpos(aq_cprofp_interupmotifps, "ELEVE") ///
	| strpos(aq_cprofp_interupmotifps, "CONGES PAR") | strpos(aq_cprofp_interupmotifps, "ELEVE")

*formation	
gen f=1 if	strpos(aq_cprofp_interupmotifps, "ETUDE") |  ///
	strpos(aq_cprofp_interupmotifps, "FORMATION") | strpos(aq_cprofp_interupmotifps, "CONCOURS") |  ///
	strpos(aq_cprofp_interupmotifps, "DIPLOME") | strpos(aq_cprofp_interupmotifps, "ETUDI") ///
	| strpos(aq_cprofp_interupmotifps, "LYCEE")  | strpos(aq_cprofp_interupmotifps, "STAGE") ///
	| strpos(aq_cprofp_interupmotifps, "ECOLE")  | strpos(aq_cprofp_interupmotifps, "UNIV") ///
	| strpos(aq_cprofp_interupmotifps, "SCOLA") 	| strpos(aq_cprofp_interupmotifps, "AFPA") ///
		| strpos(aq_cprofp_interupmotifps, "COURS") 	| strpos(aq_cprofp_interupmotifps, "BTS")
* service militaire
gen mil=1 if	strpos(aq_cprofp_interupmotifps, "ARMEE") |  strpos(aq_cprofp_interupmotifps, "ARME") ///
	| strpos(aq_cprofp_interupmotifps, "MILITAIRE") | strpos(aq_cprofp_interupmotifps, "DRAPEAUX") ///
	| strpos(aq_cprofp_interupmotifps, "CONTINGENT") | strpos(aq_cprofp_interupmotifps, "SERVICE NATIONAL")  ///
	| strpos(aq_cprofp_interupmotifps, "SERVICE MIL") 	| strpos(aq_cprofp_interupmotifps, "SERVICE CIVI") 

*chomage	
gen c=1 if 	strpos(aq_cprofp_interupmotifps, "CHOMAGE") | strpos(aq_cprofp_interupmotifps, "ANPE") ///
	| (strpos(aq_cprofp_interupmotifps, "DEMANDEUR") &  strpos(aq_cprofp_interupmotifps, "EMPLOI")) ///
	| (strpos(aq_cprofp_interupmotifps, "CHERCHE") &  strpos(aq_cprofp_interupmotifps, "EMPLOI")) ///
	| strpos(aq_cprofp_interupmotifps, "LICENCI") | strpos(aq_cprofp_interupmotifps, "LICENSI")  ///
	| strpos(aq_cprofp_interupmotifps, "RECHERCHE TRAVAIL")
/* je ne reclasse pas en chômage les "fin contrat", "licenciement économique".... car on ne peut pas
savoir si les gens ont été chômeurs ou inactifs après
*/
	
*sante
gen s2=1 if	strpos(aq_cprofp_interupmotifps, "ACCIDENT") |  ///
	strpos(aq_cprofp_interupmotifps, "ALD") | strpos(aq_cprofp_interupmotifps, "OPERATION") ///
	| strpos(aq_cprofp_interupmotifps, "MALADIE") | strpos(aq_cprofp_interupmotifps, "TRAUMA")  ///
	| strpos(aq_cprofp_interupmotifps, "AGRESSION") | strpos(aq_cprofp_interupmotifps, "OTAGE") ///
	| strpos(aq_cprofp_interupmotifps, "CANCER") | strpos(aq_cprofp_interupmotifps, "HOSPITAL") ///
	| strpos(aq_cprofp_interupmotifps, "DEPRESSION") | strpos(aq_cprofp_interupmotifps, "AVP") ///
	| aq_cprofp_interupmotifps=="AT" | aq_cprofp_interupmotifps=="A T"  | strpos(aq_cprofp_interupmotifps, "AT ")==1  ///
	| strpos(aq_cprofp_interupmotifps, "A T ")	| strpos(aq_cprofp_interupmotifps, "COTOREP") ///
	| strpos(aq_cprofp_interupmotifps, "DECES")	| strpos(aq_cprofp_interupmotifps, "BURN OUT")  ///
	| strpos(aq_cprofp_interupmotifps, "HARCELEMENT")	| strpos(aq_cprofp_interupmotifps, "ALLERGIE")  ///
	| strpos(aq_cprofp_interupmotifps, "CANAL CARPIEN")	| strpos(aq_cprofp_interupmotifps, "FRACTURE")  ///
	| strpos(aq_cprofp_interupmotifps, "PROBLEME DOS")	| strpos(aq_cprofp_interupmotifps, "TUBERCULOSE")  ///
	| strpos(aq_cprofp_interupmotifps, "SANTE")	| strpos(aq_cprofp_interupmotifps, "AVC") 

	
count if aq_cprofp_interupmotif3==1
count if  aq_cprofp_interupmotifps!="" & f==. & m==. & mil==.	& s2==. & c==.
tab aq_cprofp_interupmotifps if aq_cprofp_interupmotifps!="" & f==. & m==. & mil==. & c==. & s2==. , sort
 	
tab aq_cprofp_interupmotifps if aq_cprofp_interupmotifps=="AT" | strpos(aq_cprofp_interupmotifps, "AT ")==1 , sort

*** Chomage

recode aq_cprofp_interupmotif2 (1=1) (.=0), gen (t)
gen s=1 if t==1 | c==1
bys proj_isp : egen nstopcho= sum(s)
label var nstopcho "Chômage: nb arrets travail>6mois"
note nstopcho: nombre de 1 dans aq_cprofp_interupmotif2. `tag'
tab nstopcho if last==1, mis
* ==> 48 716 jamais d'arret chômage déclaré

gen astopcho= nstopcho!=0
label var astopcho "Chômage: declare min 1 arret>6mois"
label val astopcho lon01
note astopcho: a partir de nstopcho. `tag'
tab astopcho s, mis
* ==> toutes les lignes pour qui s vaut 1 ont astopcho qui vaut 1
tab astopcho s if last==1 , mis
* ==> 48 716 jamais d'arret chômage déclaré
drop s t



*** Sante

* recoder les épisodes d'arrêt travail pour raison santé
count if aq_cprofp_interupmotif1==1

recode aq_cprofp_interupmotif1 (1=1) (.=0), gen (s)
replace s=1 if s==0 & s2==1
bys proj_isp : egen nstopsante= sum(s)
label var nstopsante "Santé: nb arrets travail>6mois"
note nstopsante: nombre de 1 dans aq_cprofp_interupmotif1. `tag'
tab nstopsante if last==1, mis

gen astopsante= nstopsante!=0
label var astopsante "Santé: declare min 1 arret>6mois"
label val astopsante lon01
note astopsante: a partir de nstopsante. `tag'
tab astopsante s, mis
drop s

*-----------------garder la dernière ligne de chaque indv ---------------*
/* pour garder le dernier emploi occupé je garde uniquement la dernière ligne
tout ce qui nécessite des calculs sur plusieurs lignes doit être effectué avant
*/

* keep
bys proj_isp: gen nl=_N		// nb de ligne par indv

keep if last==1

*-----------------Merge avec entete ---------------*

merge 1:1 proj_isp using "$cree/DATA_CP"

/* je le ferai au moment de sélectionner les inclus.

*-----------------Effacer les lignes des non-répondants CP ---------------*
/* individus qui ont reçu CP mais ne l'ont pas renvoyé.il faut se baser sur
suivi_rep_cp dans l'en-tête (fichier data_cp) car dans la partie épisodes la
var est vide */
count if suivi_rep_cp==.
drop if suivi_rep_cp==.

note _dta: supprimé individus qui n'ont pas rendu CP. `tag'
*/

*-----------------NB de jobs et last job d'après episodes ---------------*

* nb de jobs dans les épisodes
gen njobs= aq_cprofp_numemploi
recode njobs (.=0)
label var njobs "cp: nombre emplois declarés"
tab njobs

*corriger une erreur manifeste
/*
          proj_isp   aq_cpro dtrempl aq_cperiodde   periodada  
  171.   2015A0621000171   24jul2014       2006      20114  
*/
  
replace aq_cprofp_perioda= 2014 if aq_cprofp_perioda==20114

* explorations et vérifiactions sur last job
* @le format de dtrempl permet pas de comparer avec dates perioda et periodde

gen cp_datlast=0
replace cp_datlast=1 if aq_cprofp_perioda!=. & aq_cprofp_periodde !=.
replace cp_datlast=2 if aq_cprofp_perioda==. & aq_cprofp_periodde !=.
replace cp_datlast=3 if aq_cprofp_perioda!=. & aq_cprofp_periodde ==.
replace cp_datlast=4 if aq_cprofp_perioda==. & aq_cprofp_periodde ==.
replace cp_datlast=5 if aq_cprofp_perioda<aq_cprofp_periodde & aq_cprofp_periodde !=.
/* je ne considère pas qu'une date de fin postérieure à la date de remplissage soit
une incohérence: eles gens en CDD pvt indiquer date fin contrat
*/

label var cp_datlast "cp: dates dernier job?"
label def cp_datlast 1 "debut et fin" 2 "debut pas fin" 	///
	3 "pas debut, fin" 4 "ni debut ni fin" 5 "incoherence", modify
label val cp_datlast cp_datlast

tab cp_datlast 	// on s'intéresse aux lignes 1 et 2. à comparer avec data expo prof et mdv

* département dernier job
gen cp_lastdep=aq_cprofp_departement
recode cp_lastdep (99/max = 99)
label var cp_lastdep "Dépt dernier job (CP)"


*-----------------Situation Actuelle d'après CP ---------------*

gen cp_lastsante = aq_cprofp_interupmotif1==1 | s2==1
label var cp_lastsante "last job: coche arret santé>6mois"

gen cp_lastcho = aq_cprofp_interupmotif2==1 | c==1
label var cp_lastcho "last job: coche arret chômage>6mois"

gen cp_laststopaut= aq_cprofp_interupmotif3==1 & s2+c==.
label var cp_laststopau "last job: coche arret autre"

gen cp_retraite=aq_cprof_dtretraite!=.
label var cp_retraite "Date retraite remplie (CP)"
label val cp_lastsante Lon01
label val  cp_lastcho	Lon01
label val  cp_laststopaut Lon01
label val  cp_retraite	Lon01

*------------- Jamais travaillé d'après CP -----------------------*

tab cp_datlast  aq_cprof_dejatrav, mis

gen l=  aq_cprofp_periodde < aq_cprofp_perioda & aq_cprofp_perioda<.

gen cp_jmstrav=0
replace cp_jmstrav=1 if aq_cprof_dejatrav==2
replace cp_jmstrav=0 if aq_cprof_dejatrav==2 & l==1 & cp_lastdep<99

label var cp_jmstrav "Jamais travaillé>6mois (CP)?"
label val cp_jmstrav Lon01

gen chojmstrav = aq_cprof_jamtravrech==1
label var chojmstrav "Jamais trav6mois car rech emploi coché (CP)"

*------------- FIN -----------------------*
note 	njobs	:	`tag'
note 	cp_datlast	:	`tag'
note 	nstop	:	`tag'
note 	cp_lastdep	:	`tag'
note 	cp_lastsante	:	`tag'
note 	cp_lastcho	:	`tag'
note 	cp_laststopaut	:	`tag'
note 	cp_retraite	:	`tag'
note 	cp_jmstrav	:	`tag'
note 	chojmstrav	:	`tag'



keep proj_isp nstop nstopcho astopcho nstopsante astopsante suivi_env_cp  ///
	suivi_rep_cp aq_cprof_dtrempl njobs cp_datlast cp_lastdep cp_lastsante ///
	cp_lastcho cp_laststopaut cp_jmstrav cp_retraite chojmstrav
compress
desc

save "$temp/t_cprof", replace	
