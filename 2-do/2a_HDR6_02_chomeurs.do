
local tag "2_HDR6_02_chomeurs.do"


/*---------------------------------------------------------------------------*/
*******************************************************************************
*	Marie Plessz
*	2020-10-07
*	projet : HDR6
/*	tache : 
* fichier selection population ACM sur les chômeurs 
	
*/
/*---------------------------------------------------------------------------*/

use "$cree/HDR6_01_tous", clear


***************** Selection des chômeurs à l'inclusion ******************

tab emploi if emploi ==1 | emploi ==2, mi 
/*
                  Sit. emploi |      Freq.     Percent        Cum.
-------------------------------+-----------------------------------
                     En emploi |    128,263       92.30       92.30
Demandeur d'emploi sans emploi |     10,703        7.70      100.00
-------------------------------+-----------------------------------
                         Total |    138,966      100.00
*/

* emploi manquant
drop if emploi == .
* ==> (6,647 observations deleted)

tab age_cl homme 
tab age_cl homme if emploi==2




* chômeurs seulement
keep if emploi==2
* ==> (159,457 observations deleted)

****************** Quartiles Revenus/UC/mois *************
* xtile revuc4cl= revenuuc, nquantiles(4) 
	/*ligne utilisée pour calculer les quartiles de revenus/UC/mois */

misstable sum rorigresproch rorigreschom  revuc_mi astopsante diplome3 cp_jmstrav avecenf01 conjemploi age_cl  homme  region cspvol diffinnow entrain 


tab1 rorigresproch rorigreschom  revuc_cho astopsante diplome3 cp_jmstrav avecenf01 conjemploi age_cl  homme  region cspvol diffinnow entrain nmiss , mis	



	
***********  Finir **************
compress
count
note _dta: Constances, données à l'inclusion, chômeurs 18-64 ans à l'inclusion. recodages spécifiques projets et sélection pop faits. N= 10,703. `tag'
label data "Constances inclusion chomeurs 18-64 ans"
save "$cree/HDR6_02_chomeurs", replace

exit


