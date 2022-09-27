qui {
	// program: 00_HDR6_debut.do
	// task: lancer le projet "analyses pour le chapitre 6 de l'HDR"
	// project: HDR et CALICO
	// author: MP le 07/10/2020
	version 14
	clear all
	set linesize 100
	set mem 16g
	
	global np "HDR6 - Constances extraction 2020-07-24"



	global projet "$startd/CONSTANCES/_STATS/2020-HDR6"
	global datapath "$projet/Data"
	global do "$projet/2-do"
	global source "$datapath/source" //données originales, ne pas modifier
	global cree "$datapath/cree" //datasets créés
	global temp "$datapath/temp" //datasets temporaires, étapes, essais etc
	global res "$projet/resultats"
cd "$projet"
}
disp as text "$S_DATE: Bonjour, projet $np"
*disp as text "Données cryptées dans " "$datapath"
exit
