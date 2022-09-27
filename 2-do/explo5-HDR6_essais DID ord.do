

* rhs = c("homme", "age_cl", "aveccouple01","avecenf01",  "astopcho", "cspvol", "diffinnow",
* "prive" , "astopcho" ,"edu", "aq_modvie_refdoc", "tuu2012_cl" )
 

use  "$cree/HDR6_04_prosp_studypop.dta", clear

* recodages communs tout fichier
rename emploi_inc  emploi0
rename emploi_sui  emploi1

rename san_c_inc santepercu // variable de contrôle dans rhs

assert (santepercu !=.)

* pour le cem il faut des variables dans le bonne ordre
recode cspvol (3 = 0) (6 = 6), gen(cemcsp)

gen cemaq = 0
replace cemaq = 1 if aq_modvie_refdoc == "I3"


* vars de contrôle pour modèles
global  rhs "homme i.age_cl aveccouple01 avecenf01  astopcho  diffinnow prive  i.edu santepercu i.cspvol i.y  i.tuu2012_cl  "

* vars pour l'appariement, avec leur grouping (les modifiées à la fin)
global cemvars "homme(#0) age_cl(#0) aveccouple01(#0) avecenf01(#1) tuu2012_cl(#1) astopcho(#0)  diffinnow(#0) prive(#0) edu(#3) santepercu(6.5) cemcsp( 2 4.5) cemaq(#0)"

* vars de l'appariement sans grouping pour vérif de l'imbalance
global imbvars "homme age_cl aveccouple01 avecenf01 tuu2012_cl astopcho  diffinnow prive edu santepercu cemcsp cemaq"

/*NB sur les choix pour l'appariement
- j'ai ajouté santé perçue : en 2 gp (<7 vs 7-8). ya pas de solution équilibrée en 3 gp)
- du coup pour sauver un peu la taille d'échantillon, j'ai  
	coarsened education : en 3 niveaux (regrouper les 2 plus bas) au lieu de 4
- avecenf et tuu en 1 seul gp comme avant
- pour les vars continues : apparier sur la var ordonnée (bla_o_inc).
- la façon dont j'ai codé cemcsp permet de la garder dans le tableau 
de dissimilarité mais voir commentaire plus bas

pour les tranches (il faut choisir une valeur qui est "entre" 2 variables par ex : 4.5 est entre 4 et 5

*/
*********============***************
* rename les données pour une var dep
rename poi_o_inc dep0
rename poi_o_sui dep1
*********============*************

drop *inc *sui

* enlever les données manquantes (sinon cem les apparie)
drop if dep0 == . | dep1 == .

* appariement
*imb  dep0 $imbvars, treatment(traitt)
cem  dep0(#0) $cemvars, treatment(traitt) showbreaks
		
	count if cem_matched==1 & traitt==1
  local ntm = r(N)
	di " `ntm'"
/* NB : la L1 mesure de la dissimilarité est trompeuse. elle est calculée 
pour des variables ordonnées, voire continues : pour une variable comme la csp 
qui n'est ni l'un ni l'autre, c'est pas bon du tout.
on peut regarder la réduction de la dissimilarité pour la santé , que j'apparie de façon 
grossière, ou  la tuu que je n'apparie pas.

*/

global outopts " nor2 word  stats(coef pval) dec(2) pdec(3)  side cttop(`stub') decmark(,)   "
eststo clear

* ====> DID agrégée
gen dif = dep1 - dep0

mean dif [iw = cem_weight], over(traitt)

*===>  DID en prédisant la différence : DID est le coef de "traitt" (traitement)

quietly reg dif traitt [iw = cem_weight]  // sans vars de contrôle
eststo ols_dif_norhs

	

quietly reg dif traitt $rhs [iw = cem_weight] // avec vars de contrôle (rés très proches)
eststo ols_dif

test (_cons)


outreg2 using "$res/5-stata_cemdidmodels", replace ///
	keep(traitt ) nor2   stats(coef pval) dec(2) pdec(3)  side ///
	cttop(`stub') addtext(Model, "OLS")   decmark(,)  

*===> DID sur données en panel

* reshape

reshape long dep emploi, i(proj_isp) j(phase)

* le coef DID est l'interaction phase#traitt
	* avec mesure de la variance robuste aux clusters que sont les indv
quietly ologit dep i.phase##i.traitt $rhs  [iw = cem_weight], cluster(proj_isp) 
eststo ologit_clust


outreg2 using "$res/5-stata_cemdidmodels", ///
	keep(1.phase#1.traitt 1.phase)  nor2   stats(coef pval) dec(2) pdec(3)  side append ///
	cttop(var) ctitle(truc) addtext(Model, "ologit" )   decmark(,)  
	
	* sans l'option cluster : ça change pas gd chose
quietly ologit dep i.phase##i.traitt $rhs  [iw = cem_weight]
eststo ologit_naif

* tableau de résultats
esttab ols* ologit*, not p keep(*traitt *phase _cons)


*===> mldèles à effets fixes impossibles
/* pas de modèles à effets fixes pour fonctions ordinal logit (sans doute impossible
car trouvé nulle part et impossible pour d'autre smodèles non linéaires comme tobit)
en plus on peut pas pondérer donc le modèle à effets fixes oblige à garder un seul 
témoins par cas.
je l'ai fait pour les vars continues à titre indicatif.
*/

exit 


