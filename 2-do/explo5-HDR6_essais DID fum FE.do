
use  "$cree/HDR6_04_prosp_studypop.dta", clear

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
rename fum_n_inc dep0
rename fum_n_sui dep1

rename fum_o_inc depcem  /* appariement sur la variable en tranches */

*supprimer les jamais fumeurs
drop if fum_control_inc ==0
* ==> (15,301 observations deleted)



drop *inc *sui

* appariement en gardant 1 témoins par cas
* imb  dep0 $imbvars, treatment(traitt)
cem  depcem $cemvars, treatment(traitt) showbreaks k2k // option k2k

*modèle à effets fixes


reshape long dep emploi, i(proj_isp) j(phase)
encode(proj_isp), gen(id)
xtset id phase
keep if cem_matched ==1
xtreg dep i.traitt##i.phase  , fe
