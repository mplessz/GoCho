/*---------------------------------------------------------------------------*/
*	Marie Plessz
*	2021-02-03
*	projet : GoCho
*	tache : 
*		modèles
*		sortir les coefs intéressants (outreg2)
*		plots des probabilités prédites (atmeans)


* ==> CHECK : réestimer les modèles seulement sur les pers qui ont répondu à la version I3 de l'AQ, cad inclus à partir du 04/2015
* j'ai essayé avec 2016 mais effectifs vraiment faibles

/* Comment j'ai expliqué mes modèles à Sehar : 

-	On wide data, compute the difference between Y_2017 and Y_inclusion, call it DIF
Run  a linear regression : 
DIF = i.Treated + right-hand-side variables.

->add weights for CEM
->coefficient for i.Treated is our DID estimator.
->Very simple. 
-> Works very well for number of drinks and cigs, and bmi and health.
->BUT not the best specification when our outcome is an ordinal and not a continuous variable. but informative. 
-> spec of right-hand-side variables dont not change much the results in our case because they are all time-independent. You can run the model with no variable except Treated and find close results.

=======> Sorties dans le fichier _regdif.txt

-	On long data, you have an additional variable, Phase= 0 if inclusion and 1 if  2017.
Run the model : 
Y = i.phase i.Treated i.phase#i.Treated + right-hand-side variables, cluster(proj_isp)

->you add your weights for CEM
->You can choose whatever model for y : linear, ordinal whatever. So you respect the fact that our y is probably ordinal. 
-> option cluster(proj_isp) means that the variance estimation is ajusted for culsters of observations (since we have 2 lines / individual). Is probably not as good as a fixed-effect but it does the job.
-> the DID coefficient is the interaction term, i.phase#i.Treated
-> i think Marcus did that on the paper from 2014 : he says : « I use robust standard errors from the weighted regressions. »
-> after the model you can run margins and marginsplot to see how the trends differ accross groups.

=======> Sorties dans le fichier _panel.txt



Concernant les margins : 
sur les modèles en panel, pour l'outcome le plus élevé (ou pour la prédiction linéaire)
prédications moyennes aux valeurs des rhs des individus (cad : si tous étaient cas? si tous étaient témoins?)
c'est valable ici parce qu'on a apparié sur les rhs à l'inclusion et qu'on n'a pas de rhs dépendante du temps. 
sinon il faudrait préciser at() (atmeans ou à des valeurs définies des facteurs).
le fait qu'à l'inclusion les 2 points sont quasi superposés est la preuve qu'on a bien apparié (cf les graphes bivariés avant appariement).


*/


*---------------------------------------------------------------------------*/

*================   PREPARER LES MACROS  ==========================*
set dp comma

local tag "check6_modeles_aqI3"

* vars de contrôle pour modèles
global  rhs "homme i.age_cl aveccouple01 avecenf01  astopcho  diffinnow prive  i.edu santepercu i.cspvol i.y  i.tuu2012_cl "

* titres de colonnes pour les modèles
local mtitle_leg_o	"Légumes" 
local mtitle_poi_o	"Poisson"
local mtitle_vro_o	"Viande rouge" 
local mtitle_fas_o	"Fastfood"
local mtitle_sod_o	"Boissons sucrées" 
local mtitle_alc_o	"Alcool" 
local mtitle_fum_o	"Cigarette" 
local mtitle_bmi_o	"Corpulence" 
local mtitle_san_o	"Santé perçue" 

*titres des graphiques "marginsplot"
local title_leg_o	"Légumes : 1/jour "
local title_poi_o	"Poisson : 2/semaine"
local title_vro_o	"Viande rouge : 4/semaine"
local title_fas_o	"Fastfood : 1/semaine "
local title_sod_o	"Boissons sucrées : 1/semaine"
local title_alc_o	"Alcool : 2 verres/jour"
local title_fum_o	"Cigarette : 10/jour "


* labels pour la variable phase dans les graphiques
label def phase 0 "Inclusion" 1 "2017", modify

global margopts " ytitle(Probabilité) ylabel(0(.1)0.4 ,format(%5.1f))  scheme(s1mono) noci ytick(0(.1)0.4) nodraw xtitle("") xlabel(0 "Inclusion" 1 "2017") ysize(10) xsize(6) "


* macro pour les sorties outreg2	
global outopts " nor2 text stats(coef pval) dec(2) pdec(3) noparen  decmark(,)  fmt(f)  "

local replace replace  // à la première occurence outreg2 remplace le fichier de résultats

eststo clear

*=============	BOUCLE	===================*

* régression linéaire dif = traitt + rhs
* régession logistique en panel logit(y) = traitt##phase + rhs, clustered var
* sorties outreg2
* tableou estout
* graphique avec marginsplot, aux valeurs moyennes des rhs (qui sont les mêmes pour les 2 groupes).

foreach stub in  leg_o  poi_o vro_o fas_o  sod_o alc_o fum_o  { 
	use "$temp/t_05_cem_`stub'.dta", clear
	* alléger le fichier de toutes les autres vars appariées
	drop *inc *sui

	*==> sélection de ceux qui ont répondu à I3 : inclus à partir de 04/2015 <==
	keep if cemaq == 1
	tab dep1 traitt
	
*===>  DID en prédisant la différence : DID est le coef de "traitt" (traitement)
	* variable à prédire
	gen dif = dep1 - dep0

	quietly reg dif traitt $rhs [iw = cem_weight] // avec vars de contrôle (rés très proches)
	eststo `stub'_dif, title(`stub' OLS)
	outreg2 using "$res/`tag'_regdif.txt", $outopts  `replace' ///
	keep(traitt ) 	ctitle( `mtitle_`stub'' ) 
	
	
*===> DID sur données en panel
	* reshape
	reshape long dep emploi, i(proj_isp) j(phase)
	
	label var phase "Phase"
	label val phase phase	

	* le coef DID est l'interaction phase#traitt
		* avec mesure de la variance robuste aux clusters que sont les indv
	quietly ologit dep i.phase#i.traitt i.traitt i.phase $rhs  [iw = cem_weight], cluster(proj_isp) 
	eststo `stub'_ologit, title(`stub' olog)
	outreg2 using "$res/`tag'_panel.txt", $outopts  `replace'  ///
	keep(1.phase#1.traitt 1.phase) nocons ///
	ctitle( `mtitle_`stub'' ) 

* tableau de résultats
di as result "------ `stub' - tableau récap -------"


esttab `stub'* , not p keep(*traitt *phase _cons)
 
local replace // la macro local devient vide. on "replace" outreg2 que la première fois

* graphique margins
display " `title_`stub' '" 	
quietly sum dep
local max = r(max)
di `max' 	
quietly margins i.phase#i.traitt, predict(outcome(`max'))
quietly marginsplot, 	$margopts ///
	saving("$res/margins_`stub'", replace)  title(" `title_`stub' ' - aqI3" )

}
	
****** fin de la boucle ******	

*===========	MODELES et PLOTS SUPPLEMENTAIRES		=============*


*===============	GRAPHIQUE des PROBA PREDITES	===================* 

grc1leg 		///
	"$res/margins_leg_o.gph"     ///
	"$res/margins_poi_o.gph"     ///
	"$res/margins_vro_o.gph"     ///
	"$res/margins_fas_o.gph"     ///
	"$res/margins_sod_o.gph"     ///
	"$res/margins_alc_o.gph"     ///
	"$res/margins_fum_o.gph"     ///
   ,  legendfrom("$res/margins_leg_o.gph" )  span scheme(s1mono) cols(2)  scale(0.5) iscale(1) xcommon imargin(b=0 t=0)
   
  graph display, ysize(8) xsize(6)
  
 graph export "$res/`tag'_graph_combined_margins.eps", preview(on) replace
  graph export "$res/`tag'_graph_combined_margins.png", replace
  
exit


/*	"$res/margins_bmi_c.gph"     ///
	"$res/margins_san_c.gph"     ///   */
