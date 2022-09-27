cap log close
set more off
local tag "dm04_indgeo_v1"
*	log  using _nomprogramme_, replace text

/*---------------------------------------------------------------------------------*/
*	Marie Plessz
*	19/10/2017
*	projet : CLC2
*	tache : examen et recodages indgeo
/*---------------------------------------------------------------------------------*/

use "$cree/DATA_INDGEO_01", clear

	// garder 1 ligne par ménage: celle de l'inclusion si existe.
* ic_adrinvitation contient Y si c la ligne de l'adresse à l'inclusion, rien sinon
* ic_dtmajadr contient la date de mise à jour de l'adresse
* les indicateurs géographiques liés à chauqe adresse apparaissent.

gsort proj_isp -ic_adrinvitation

by proj_isp: gen i=_n
count

keep if i==1
drop i

	// var jolies
clonevar tuu2012=dico_ic_t2u_tuu2012
label var tuu2012 "IC-Tranche unité urbaine (pop 2012)"
label def tuu	1 "2 000 à 4 999 h" 	///
	2 "5 000 à 9 999 h" 	///
	3 "10 000 à 19 999 h" 	///
	4 "20 000 à 49 999 h" 	///
	5 "50 000 à 99 999 h" 	///
	6 "100 000 à 199 999 h" 	///
	7 "200 000 à 1 999 999 h" 8 "Paris", modify
label val tuu2012 tuu
note tuu2012 : copie de ic_t2u_tuu2012, `tag'.

	// finir
keep proj_isp tuu2012 dico_ic_fdep_fdep09  dico_ic_fdep_txchom09
codebook, compact	
sort proj_isp
compress
save "$temp/t_indgeo01", replace
