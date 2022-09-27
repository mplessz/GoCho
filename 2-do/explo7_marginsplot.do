 use  "$temp/t_05_cem_leg_o.dta", clear


reshape long dep emploi, i(proj_isp) j(phase)

label var phase "Phase"
label def phase 0 "Inclusion" 1 "2017", modify
label val phase phase	
 
*modèle
quietly ologit dep i.phase#i.traitt i.traitt i.phase $rhs  [iw = cem_weight], cluster(proj_isp)


	
global margopts " title(Poisson) ytitle(Probabilité) ylabel(0(.05)0.35 ,format(%5.2fc)) scheme(s1mono) noci ytick(0(.05)0.35) "
sum(dep)
local max = r(max)
margins i.phase#i.traitt, predict(outcome(`max'))	
marginsplot, saving("$res/test", replace) $margopts


******* pour la boucle foreach	***********
local stub "leg_o"


* vars de contrôle pour modèles
global  rhs "homme i.age_cl aveccouple01 avecenf01  astopcho  diffinnow prive  i.edu santepercu i.cspvol i.y  i.tuu2012_cl "

local title_leg_o	"Légumes : 1/jour (p=0,031)"
local title_poi_o	"Poisson : 2/semaine (p=0,037)"
local title_vro_o	"Viande rouge : 4/semaine (p=0,021)"
local title_fas_o	"Fastfood : 1/semaine (p=0,004)"
local title_sod_o	"Sodas : 1/semaine (n.s.)"
local title_alc_o	"Alcool : 2 verres/jour (n.s.)"
local title_fum_o	"Cigarette : 10/jour (p=0,067)"
local title_bmi_o	"Corpulence : obèse (n.s.)"
local title_san_o	"Santé perçue : 8/8 (n.s.)"

global margopts " ytitle(Probabilité) ylabel(0(.05)0.35 ,format(%5.2fc)) scheme(s1mono) noci ytick(0(.05)0.35) nodraw "


* macro pour les sorties outreg2	
global outopts " nor2 excel stats(coef pval) dec(2) pdec(3) noparen "

local replace replace  // à la première occurence outreg2 remplace le fichier de résultats

eststo clear


use "$temp/t_05_cem_`stub'.dta", clear
* alléger le fichier de toutes les autres vars appariées
drop *inc *sui

*===>  DID en prédisant la différence : DID est le coef de "traitt" (traitement)
	* variable à prédire
	gen dif = dep1 - dep0

	quietly reg dif traitt $rhs [iw = cem_weight] // avec vars de contrôle (rés très proches)
	eststo `stub'_dif, title(`stub' OLS)
	outreg2 using "$res/5-stata_cemdidmodels.xls", $outopts ///
	keep(traitt ) `replace' ///
	ctitle( `stub' OLS) 

*===> DID sur données en panel
	* reshape
	reshape long dep emploi, i(proj_isp) j(phase)
	
	label var phase "Phase"
	label def phase 0 "Inclusion" 1 "2017", modify
	label val phase phase	

	* le coef DID est l'interaction phase#traitt
		* avec mesure de la variance robuste aux clusters que sont les indv
	quietly ologit dep i.phase#i.traitt i.traitt i.phase $rhs  [iw = cem_weight], cluster(proj_isp) 
	eststo `stub'_ologit, title(`stub' olog)
	outreg2 using "$res/5-stata_cemdidmodels.xls", $outopts ///
	keep(1.phase#1.traitt 1.phase) nocons ///
	ctitle(`stub' ologit) 

* tableau de résultats
di as result "------ `stub' - tableau récap -------"
esttab `stub'* , not p keep(*traitt *phase _cons)
 
local replace // on "replace" outreg2 que la première fois

* graphique margins
display " `title_`stub' '" 	
quietly sum dep
local max = r(max)
di `max' 	
quietly margins i.phase#i.traitt, predict(outcome(`max'))
quietly marginsplot, 	$margopts ///
	saving("$res/margins_`stub'", replace)  title(" `title_`stub' '" )

	
****** fin de la boucle ******	
graph use "$res/margins_`stub'"
exit 
 
 graph use "$res/test"
 
grc1leg "$res/test" "$res/test" ,  legendfrom("$res/test" )  span scheme(s1mono)
 
 
 * macros pour les titres des graphes	// pvalues prises dans les résultats du 02/02/2021. fichier excel "résultats retravaillés 2"
	local title_leg_o	"Légumes (p=0,031)"
	local title_poi_o	"Poisson (p=0,037)"
	local title_vro_o	"Viande rouge (p=0,021)"
	local title_fas_o	"Fastfood (p=0,004)"
	local title_sod_o	"Soda (n.s.)"
	local title_alc_o	"Alcool (n.s.)"
	local title_fum_o	"Cigarette (p=0,067)"
	local title_bmi_o	"Corpulence (n.s)"
	local title_san_o	"Santé perçue (n.s)"


* macro options pour les graphiques
global margopts " title(" `title_`stub' '") ytitle(Probabilité) ylabel(0(.05)0.35 ,format(%5.2fc)) scheme(s1mono) noci ytick(0(.05)0.35) nodraw saving("$res/mar_`stub'", replace)"

quietly marginsplot , $margopts

	
	exit

local title_san_c	"Santé perçue (continue) (n.s)"
local title_bmi_c	"Corpulence (continue) (n.s)"
local title_fum_p	"Fume (si déjà fumé) (p=0,066)"

	local max_leg_o	"6"
	local max_poi_o	"4"
	local max_vro_o	"5"
	local max_fas_o	"3"
	local max_sod_o	"3"
	local max_alc_o	"3"
	local max_fum_o	"2"
	local max_bmi_o	"3"
	local max_san_o	"8"

local title_leg_o	"Légumes : 1/jour"
local title_poi_o	"Poisson : 2/semaine"
local title_vro_o	"Viande rouge : 4/semaine"
local title_fas_o	"Fastfood : 1/semaine"
local title_sod_o	"Sodas : 1/semaine (n.s.)"
local title_alc_o	"Alcool : 2 verres/jour (n.s.)"
local title_fum_o	"Cigarettes : 10/jour"
local title_bmi_o	"Corpulence : obèse (n.s.)"
local title_san_o	"Santé perçue : 8/8 (n.s.)"
