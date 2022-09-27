

* rhs = c("homme", "age_cl", "aveccouple01","avecenf01",  "astopcho", "cspvol", "diffinnow",
* "prive" , "astopcho" ,"edu", "aq_modvie_refdoc", "tuu2012_cl" )
 

use  "$cree/HDR6_04_prosp_studypop.dta", clear

gen fum_tjs_inc = fum_p_inc
replace fum_tjs_inc = . if fum_control_inc ==.

gen fum_tjs_sui = fum_p_sui
replace fum_tjs_sui = . if fum_control_inc ==.


* recodages communs tout fichier
rename emploi_inc  emploi0
rename emploi_sui  emploi1

rename san_c_inc santepercu

assert (santepercu !=.)

* pour le cem il faut des variables dans le bonne ordre
recode cspvol (3 = 0) (6 = 6), gen(cemcsp)

gen cemaq = 0
replace cemaq = 1 if aq_modvie_refdoc == "I3"



global  rhs "homme i.age_cl aveccouple01 avecenf01  astopcho  diffinnow prive i.edu santepercu i.cspvol i.y  i.tuu2012_cl "
global cemvars "homme(#0) age_cl(#0) aveccouple01(#0) avecenf01(#1) tuu2012_cl(#1) astopcho(#0)  diffinnow(#0) prive(#0) edu(#3) santepercu(6.5) cemcsp( 2 4.5) cemaq(#0)"
global imbvars "homme age_cl aveccouple01 avecenf01 tuu2012_cl astopcho  diffinnow prive edu santepercu cemcsp cemaq"

* rename les données pour une var dep
rename fum_tjs_inc dep0
rename fum_tjs_sui dep1

rename fum_o_inc depcem  /* appariement sur la variable en tranches */

*supprimer les jamais fumeurs
drop if fum_control_inc ==0
* ==> (15,301 observations deleted)

drop if dep0 == .  | dep1 == .

drop *inc *sui

* appariement
* imb  dep0 $imbvars, treatment(traitt)
cem  depcem $cemvars, treatment(traitt) showbreaks

* ====> DID agrégée
gen dif = dep1 - dep0

mean dif [iw = cem_weight], over(traitt)

quietly reg dif traitt [iw = cem_weight]
eststo ols_dif_norhs

quietly reg dif traitt $rhs [iw = cem_weight]
eststo ols_dif


* reshape

reshape long dep emploi, i(proj_isp) j(phase)

quietly reg dep i.phase##i.traitt $rhs  [iw = cem_weight], cluster(proj_isp) 
eststo ols_clust


drop if dep == .
quietly logit dep i.phase##i.traitt $rhs  [iw = cem_weight], cluster(proj_isp) 
eststo log_fum_tjs


esttab ols* log_fum_tjs , not p keep(*traitt *phase _cons) title("Parmi les fumeurs et ex-fumeurs à l'inclusion")
