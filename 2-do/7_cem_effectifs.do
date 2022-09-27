/*---------------------------------------------------------------------------*/
*	Marie Plessz
*	2021-02-01
*	projet : HDR6
*	tache : 
*		tableau des effectifs appariés par CEM
*		
*---------------------------------------------------------------------------*/

local tag "7_cem_effectifs_stata"

local append
di "voici : `append'"

foreach stub in  leg_o poi_o vro_o fas_o  sod_o alc_o fum_o  bmi_o san_o  { 

	use "$temp/t_05_cem_`stub'.dta" , clear

	table cem_matched traitt, replace
	rename table1 n
	reshape wide n, i(traitt) j(cem_matched)
	gen vardep = "`stub'"
	
	di "voici:  `append'"
	
	`append'
	
	save "t_07_cemtable.dta" , replace
	
	local append " append using t_07_cemtable.dta" 
		di "voici : `append'"
} 	

	
gen n_matched = n1 
gen  n_unmatched = n0 
gen available = (n_matched + n_unmatched)
gen p = n_matched / available  *100
gen pct_matched = string(p , "%3.1fc")

gen Traitement = "Cas" if traitt ==1
replace Traitement = "Témoins" if traitt ==0
drop traitt n1 n0 p
order vardep Traitement available n_unmatched n_matched pct_matched
sort Traitement vardep 	

export delimited using "$res/`tag'.csv",  replace	delimiter(";")	
clear
cap erase "t_07_cemtable.dta" 
