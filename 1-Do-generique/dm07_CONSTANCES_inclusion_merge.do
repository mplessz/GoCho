cap log close
set more off
local tag "dm07_HDR6_01_merge"
*	log  using `tag', replace text

/*---------------------------------------------------------------------------*/
*******************************************************************************
*	Marie Plessz
*	19/10/2017
*	projet : CLC2
/*	tache : 
* merge les recodages des différents fichiers
*/
/*---------------------------------------------------------------------------*/

use "$temp/t_foyvie01", clear
cap drop _merge


 merge 1:1 proj_isp using "$temp/t_i2alim03"
tab _merge aq_modvie_refdoc
/*


                      |   AQ-Mode de Vie-Référence AQ
               _merge |        I1         I2         I3 |     Total
----------------------+---------------------------------+----------
      master only (1) |    14,556          0     94,173 |   108,729 
          matched (3) |         0     42,478          0 |    42,478 
----------------------+---------------------------------+----------
                Total |    14,556     42,478     94,173 |   151,207 

*/

drop _merge


merge 1:1 proj_isp using "$temp/t_i3alim03"
tab _merge aq_modvie_refdoc
/*

                      |   AQ-Mode de Vie-Référence AQ
               _merge |        I1         I2         I3 |     Total
----------------------+---------------------------------+----------
      master only (1) |    14,556     42,478          0 |    57,034 
          matched (3) |         0          0     94,173 |    94,173 
----------------------+---------------------------------+----------
                Total |    14,556     42,478     94,173 |   151,207 

				
				

*/
drop _merge


merge 1:1 proj_isp using "$temp\t_i1alim02"
tab _merge aq_modvie_refdoc
/*
                    |   AQ-Mode de Vie-Référence AQ
               _merge |        I1         I2         I3 |     Total
----------------------+---------------------------------+----------
      master only (1) |         0     42,478     94,173 |   136,651 
          matched (3) |    14,556          0          0 |    14,556 
----------------------+---------------------------------+----------
                Total |    14,556     42,478     94,173 |   151,207 
*/

drop _merge

merge 1:1 proj_isp using "$temp/t_indgeo01"
drop _merge
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                             0
    matched                           155,241  (_merge==3)
    -----------------------------------------
*/

merge 1:1 proj_isp using "$temp/t_expoact01"
drop _merge
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                             0
    matched                           155,241  (_merge==3)
    -----------------------------------------
*/	

/* pas de bout en provenance de EXPOCAR

merge 1:1 proj_isp using "$temp/t_expopro03"
tab suivi_rep_exp _merge, mis
drop _merge

*/






merge 1:1 proj_isp using "$temp/t_paraclin"
/*

    Result                           # of obs.
    -----------------------------------------
    not matched                           607
        from master                       607  (_merge==1)
        from using                          0  (_merge==2)

    matched                           154,634  (_merge==3)
    -----------------------------------------


*/
drop _merge 


merge 1:1 proj_isp using  "$temp/t_cprof"
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                             0
    matched                           155,241  (_merge==3)
    -----------------------------------------

* les individus pour lesquels le CP n'a pas été reçu sont matchés quand même. Attention.
	*/

drop _merge

****************************    FIN    *********************************
compress
label data "Constances Inclusion extraction 20/10/2017"
note _dta: "CONSTANCES_inclusion_merge.dta réunit les bouts. Inclusion seulement. nb cas = 199.711 extraction 20/10/2017"
save "$cree/CONSTANCES_inclusion_merge", replace
