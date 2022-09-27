*0_Master_2_projetGoCho

* Lance tous les programmes stata pour le chap 6 de l'HDR, dans l'ordre


*-----		Pour analyse transversale inclusion 	--------
do "$projet/2-do/1_HDR6_01_tous.do" 
* do "$projet/2-do/2a_HDR6_02_chomeurs.do"


*------		Pour analyse prospective		--------
do "$projet/2-do/2b_HDR6_t_depvar_inc.do"
do "$projet/2-do/2b_HDR6_t_depvar_sui.do"
do "$projet/2-do/3_HDR6_03_prospectif.do"
do "$projet/2-do/4_HDR6_04_prosp_studypop.do"

*------		Appariements, modèles, résultats --------

do "$projet/2-do/5_appariements_modeles.do"
do "$projet/2-do/6_modeles_plots.do"
do "$projet/2-do/7_cem_effectifs.do"

exit 
