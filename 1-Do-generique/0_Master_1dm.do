*-------------------------------------------------------------*
*		Préparer fichier constances Inclusion générique		  *
*-------------------------------------------------------------*


************ Fichiers communs à de nombreux projets ********************
* toutes mes analyses sur les données d'inclusion Constances ont commencé de la même façon.
*Je m'arrête au stade où je fusionne tous les "petits bouts"


* 1/ sociodemo

do "$projet\1-Do-generique\dm01_extrait" 	//sort, compress, format texte/num.
do "$projet\1-Do-generique\dm02_foyvie"		//recodages sociodemo 
/*	do "$projet\1-Do-generique\st02_foyvie_verif_v1"	// verifie les recodages précédents
cap erase  "$temp\t_foyvie01_verif.dta" 
*/
	/* ce fichier contenait les vars originales et recodées. je le suppr après
	les vérifs */
	
*	==>fichier avec sociodemo : t_foyvie01

* 2/ pnns i2 et i3
do "$projet\1-Do-generique\dm03_pnnsI2_v1" //prépare fichier pour pnnsI2 et fait le recodage. !! PB var manquante 
do "$projet\1-Do-generique\dm03_pnnsI3_v2"	//prépare fichier pour pnnsI3 et fait le recodage.
do "$projet\1-Do-generique\dm03b_alimI1_v1" // vars manquantes de ALIM AQ version I1

* 3/ autres bouts
do "$projet\1-Do-generique\dm04_indgeo_v1"
do "$projet\1-Do-generique\dm04b_paraclin_v2"
* do "$projet\1-Do-generique\dm05_expopro_v2"	// 
do "$projet\1-Do-generique\dm06_expoact_v2"	// !!! PB refaire tourner avec codage trevalinteff -> traveff
do "$projet\1-Do-generique\dm06b_cprofp_v2"


* 4/ fusionner les bouts
do "$projet\1-Do-generique\dm07_CONSTANCES_inclusion_merge"	



***************** à partir de là j'ai des fichiers spécifiques à ce projet **********************
