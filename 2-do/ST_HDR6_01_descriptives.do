
/*---------------------------------------------------------------------------*/
*******************************************************************************
*	Marie Plessz
*	2020-10-07
*	projet : HDR6
/*	tache : 
* stats desc comparant les chômeurs aux pers en emploi, et les chômeurs complets et incomplets
	
*/
/*---------------------------------------------------------------------------*/

***stats desc cho/emploi

use "$cree/HDR6_01_tous", clear



* Garder emploi ou chomage à l'inclusion
keep if (emploi == 1 | emploi == 2)

*générer variable : emploi, cho complet, cho mi

gen chocomplet = .
replace chocomplet = 1 if emploi == 2 & nmiss == 0 
replace chocomplet = 0 if emploi == 2 & (nmiss >0 )
label def chocomplet 0 "Chomage avec non-reponse" 1 "Chomage cascomplet"
label value chocomplet chocomplet


* macro locales

local tag "ST_HDR6_01_descriptives"
local vardesc "homme  age_cl conjemploi avecenf01 diplome3  cp_jmstrav  astopsante "
local vardesc "`vardesc'  cspvol   csppereado2 rorigresproch rorigreschom diffinnow  revuc_mi "
local vardesc "`vardesc'  entrain tuu2012_cl   nmiss mdv_annee "
di "`vardesc'"

tabout  `vardesc' ///
	 emploi using "$res/`tag'_1.csv"	///
	, replace style(semi)  cell( col) f(1c) npos(col) /*stats(chi2)  */	///
	h1(Caractéristiques des personnes en emploi et au chômage à l'inclusion dans Constances)
	
tabout  `vardesc' ///
	  chocomplet  using "$res/`tag'_2.csv"	///
	, replace style(semi)  cell( col) f(1c) npos(col) /* stats(chi2) */ 	///
	h1(Chômage à l'inclusion dans Constances: comparaison des cas complets et incomplets)	
	
exit, clear	
