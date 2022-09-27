# qui a été apparié sur une var donnée? -----------

source(file = "08-appariements-modeles.Rmd")


# essai sur un seul fichier, faible conso de poisson
foo <- dflong %>%  filter(vardep =="poi_f")

bar <- foo %>%  matchit(formula = form_cem,  method = "cem", 
										 grouping= groupinglist)

# garder tout le monde dans le fichier, pour voir qui n'est pas apparié: option drop.matched = FALSE
barnum <- match.data(bar, data = foo, drop.unmatched = FALSE) %>% 
	mutate(matched = case_when(is.na(subclass) ~ 0,
														 TRUE ~ 1)) %>% 
	filter( traitt == "En emploi") # changer selon qui on veut voir / Perdu emploi

# régression logistique : association entre le fait d'être apparié et toutes les vars de l'appariement
glm(formula = matched ~ inc + homme + age_cl + aveccouple01 + avecenf01 + astopcho + 	cspvol + diffinnow + prive + astopcho + edu + aq_modvie_refdoc + 
			tuu2012_cl, data = barnum, family = binomial ) %>%  odds.ratio

# simple tableau croisé
table(barnum$inc, barnum$matched) %>%  lprop


##  BIDOUILLE-----------
truc <- df_coefs %>% rename_with(~str_replace(., "coefs_", "coefs")) %>%
	pivot_longer(cols =  starts_with("coefs"), 	names_to = c(  "Modele",".value"),
							 names_pattern = "(.+)_(.+)") %>% 
	relocate(Modele, .before = term) %>% 
	arrange(vardep, desc(Modele) ) %>% 
	pivot_wider(id_cols = c(vardep,  term), names_from = "Modele", values_from = )

filter(coefs_did_term == "traittPerdu emploi") %>% 
	mutate(or_cem = exp( coefs_cem_estimate)) %>% 
	select(vardep, ends_with("p.value"), or_cem) %>% 
	mutate(star = case_when(coefs_cem_p.value< 0.01 ~ "***",
													coefs_cem_p.value< 0.05 ~ "**",
													coefs_cem_p.value< 0.1 ~ "*",
													TRUE ~"")) %>%  arrange(vardep) %>% 
	kable(digits = 3)

# ajouter titre aux tableaux
cm = c("traittPerdu emploi" = "Chômage 2017",
			 "inc" = "Conso à l'inclusion")

gm <- modelsummary::gof_map
gm$omit <- TRUE
gm$omit[gm$raw == "nobs"] <- FALSE
gm$clean[gm$raw == "nobs"] <- "n"



f_table <- function(models, title= NULL) {  
	rows <- tribble(~term,  ~"Sans DID", ~"DID", ~"DID et CEM", 
									glue("**{title}**") ,"" ,"" ,"" )
	attr(rows, 'position') <- c(1)
	modelsummary(	models = models,
								title = title,
								coef_map = cm,
								gof_map = gm,
								exponentiate = TRUE ,
							#	coef_omit = "[^traittPerdu emploi|inc]",
								# estimate = "{estimate} ({p.value})",
								statistic = NULL,
								#gof_omit = "[^Num.Obs]",
								stars = TRUE,
							add_rows = rows) 
}

tit <- tribble(~vardep , ~title,
							 "alc_f", "Alccol rare",
							 "alc_i", "Alcool fréquent")

bar <- models_nest %>% filter(vardep =="alc_f"| vardep =="alc_i") %>% left_join(tit, by = "vardep")


bar2 <- bar %>%   
	mutate(models = pmap(list("Sans DID" = model_nodid, "DID" = model_did, "DID et CEM" = model_cem), list )) %>% 

	select(vardep, models, title)

bar3 <- pmap(bar2[,2:3], f_table)

bar3[[1]]

foo<- list("Sans DID" = data_orig$model_nodid[[1]], 
					 "DID" = data_orig$model_did[[1]],
					 "DID et CEM" = data_orig$model_cem[[1]])

modelsummary(models = foo, 
						 coef_map = cm, gof_map = gm, exponentiate = T,
						 stars = TRUE,
						 stars_note = TRUE  )  

library(modelsummary)
library(tidyverse)
packageVersion("modelsummary")
data(mtcars) 

fit <- 	glm(am  ~ wt + cyl  , data = mtcars, family = binomial )  
	modelsummary(fit , exponentiate = TRUE, statistic = NULL, gof_omit = "[^Num.Obs]") 
	
	modelsummary(fit , exponentiate = FALSE, statistic = NULL, gof_omit = "[^Num.Obs]") 

	
cm = c("wt" = "Weight", 
			 "cyl" = "Cylindres",
				"am1" = "truc")


attr(rows, 'position') <- c(1)
rows <- tribble(~term,  ~"Model 1", 
								'vartitre',""  )
attr(rows, 'position') <- c(1)

library(modelsummary)
library(tidyverse)
packageVersion("modelsummary")
data(mtcars) 
mtcars %>%  
	glm(am  ~ wt + cyl  , data = ., family = binomial ) %>%  
	modelsummary( exponentiate = TRUE, stars = TRUE, stars_note = TRUE)

modelsummary

	modelsummary(statistic = NULL, title = "truc", coef_map = cm)
	

	
	
	modelsummary(statistic = NULL, title = "truc", coef_map = cm)


	# Call:
	# 	glm(formula = am ~ wt + cyl, family = binomial, data = mtcars)
	# 
	# Deviance Residuals: 
	# 	Min        1Q    Median        3Q       Max  
	# -1.91155  -0.25974  -0.04161   0.18322   1.95512  
	# 
	# Coefficients:
	# 	Estimate Std. Error z value Pr(>|z|)   
	# (Intercept)   15.749      6.026   2.614  0.00896 **
	# 	wt            -7.864      3.071  -2.561  0.01045 * 
	# 	cyl            1.322      0.789   1.675  0.09390 . 
	# ---
	# 	Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

