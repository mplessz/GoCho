# MP projet HDR6
# statistiques descriptives


# début -----
library(haven)
library(tidyverse)
library(knitr)
library(questionr)
library(arsenal)
library(knitr)
library(table1)


options(OutDec= ","  ,
				encoding = "utf-8") 

# options(digits = 2, OutDec = ",")

# données ----

data_orig <- read_dta("Data/Cree/HDR6_01_tous.dta")

# préparation

df <- data_orig %>% 
	filter(emploi == 1 | emploi ==2) %>% 
	mutate_if(is.numeric, as_factor) %>% 
	select(-age, -revuc_cho) %>% 
	mutate(emploi = fct_recode(emploi, "Chômage" = "Demandeur d'emploi sans emploi")) %>% 
	mutate(cc = case_when(nmiss == 0 ~ "Complet",
												TRUE ~"Incomplet")) %>% 
	mutate_if(is.factor, fct_drop) # se débarrasser des levels vides

# labels -----------
mylabels <- list(homme = "Homme", 
								 aveccouple01 = "Vit en couple",
								 avecenf01 = "Vit avec enfant(s)",
								 diffinnow = "Difficultés financières",
								 conjemploi = "Conjoint",
								 cp_jmstrav = "Jamais travaillé +6mois (CP)",
								 revuc_mi = "Revenu mensuel/UC",
								 age_cl = "Tranche d'âge",
								 tuu2012_cl = "Taille unité urbaine",
								 cc = "Cas complet"
								 )
var_label(df) <- mylabels
# Tableau 1 :emploi vs chômage --------

t1 <- tableby(data = df, emploi ~ 
								homme+ age_cl+ 	conjemploi+ avecenf01+ 
							  diplome3+ cp_jmstrav+ cspvol+
							  diffinnow+ revuc_mi+  rorigreschom+ rorigresproch+
							  astopsante+  entrain+ tuu2012_cl+ cc,
							  test = FALSE, 
							total = FALSE,
							control = tableby.control(cat.stats = c("countpct", "Nmiss"),
																				stats.labels = list(Nmiss = "N manquantes"),
																				cat.simplify = TRUE) ) 

summary(t1, text = TRUE) 

write2word(t1, "test",
					 labelTranslations = mylabels,
					 title = "Caractéristiques des participants en emploi et au chômage dans Constances (inclusion)")

# Tableau 2 : cc versus incomplet parmi les chomeurs --------

t2 <- tableby(data = df  %>% filter(emploi == "Chômage"), cc ~ 
								homme+ age_cl+ 	conjemploi+ avecenf01+ 
								diplome3+ cp_jmstrav+ cspvol+
								diffinnow+ revuc_mi+  rorigreschom+ rorigresproch+
								astopsante+  entrain+ tuu2012_cl,
							test = TRUE, 
							total = FALSE,
							control = tableby.control(cat.stats = c("countpct"),
																				cat.simplify = TRUE) ) 

summary(t2, text = TRUE) 

write2word(t2, "3-R-ACM/02_tableau-statdesc-2.doc",
					 labelTranslations = mylabels,
					 title = "Caractéristiques des cas complets et incomplets parmi les participants à Constances en recherche d'emploi (inclusion)")

# essai avec package table1 ------
# afficher % sans NA :	https://github.com/benjaminrich/table1/issues/21

# Custom function to render missing values
render.missing <- function(x, ..., newlabel="Manquante") {
	setNames(render.missing.default(x, ...), newlabel)
}

# table


 table1(data = df,
 			 ~ homme+ age_cl+ 	conjemploi+ avecenf01+ 
 			 	diplome3+ cp_jmstrav+ cspvol+
 			 	diffinnow+ revuc_mi+  rorigreschom+ rorigresproch+
 			 	astopsante+  entrain+ tuu2012_cl | emploi ,
				overall = "Ensemble",	 
				render.categorical="PCTnoNA%",
				render.missing=render.missing,
			 topclass="Rtable1-zebra" 
				) 

 
 
# TESTs afficher test chi2 : echec
 set.seed(123)
 
 dat <- data.frame(foo=rep(LETTERS[1:3], times=sample(20:200, 3)))
 
 dat$y <- sample(LETTERS[4:7], nrow(dat), replace=T, prob=c(0.1, 0.2, 0.3, 0.4))

 
dat$foo <- factor(dat$foo, labels=c("A", "B", "P-value")) 
 
 render.categorical <- function(x, ...) {
 	c("", sapply(stats.apply.rounding(stats.default(x)), function(y) with(y,
 																																				sprintf("%s (%s%%)", prettyNum(FREQ, big.mark=" "), PCT))))
 }
 
 
 rndr <- function(x, name, ...) {
 	if (length(x) == 0) {
 		y <- dat[[name]]
 		s <- rep("", length(render.default(x=y, name=name, ...)))
 		if (is.numeric(y)) {
 			p <- t.test(y ~ dat$foo)$p.value
 		} else {
 			p <- chisq.test(table(y, droplevels(dat$foo)))$p.value
 		}
 		s[2] <- sub("<", "&lt;", format.pval(p, digits=3, eps=0.001))
 		s
 	} else {
 		render.default(x=x, name=name, ...)
 	}
 }
 
 
 rndr.strat <- function(label, n, ...) {
 	ifelse(n==0, label, render.strat.default(label, n, ...))
 }
 
 table1(~ y | foo, data=dat,  render.strat= rndr.strat ,
 			  overall = F, droplevels=F ,
 			 render=rndr
 			 )
 
## test du package gtsummary 
library(gtsummary)
 
 set_gtsummary_theme(theme_gtsummary_compact())

df %>%  select(revuc_mi, age_cl, homme, avecenf01, emploi) %>% 
		tbl_summary(
			by = emploi,
			missing_text = "N manquantes",
					) %>% 
	add_p()



tbl_merge(
	tbls = list(t1, t2),
	tab_spanner = c("**Ensemble**", "**Parmi les chômeurs**")
)  %>% as_gt() %>% 
	gtsave(filename = "02_tableau_1.html", path = "3-R-ACM")
 