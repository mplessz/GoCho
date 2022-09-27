
# setup -----
library(haven)
library(tidyverse)
library(knitr)
library(labelled)
library(questionr)
library(glue)
library(stargazer)
library(broom)

list_ordre_freq <- c( "Jamais", 
											"<1/semaine", 
											"Max 1/semaine" ,
											"Min 1/semaine",
											"2-3/semaine",
											"Min 2/semaine" ,
											"Min 4/semaine",
											"4-6/semaine" , 
											"Min 1/jour"   
)


rhs = c("homme", "age_cl", "aveccouple01","avecenf01",  "astopcho", "cspvol", "diffinnow", "prive" , "astopcho" ,"edu", "aq_modvie_refdoc", "tuu2012_cl" )

data_orig <- readRDS( "Data/Cree/HDR6_05b-cc-vardep-long.Rds") %>% 
	filter(vardep == "poi_o") %>% 
	dplyr::select(proj_isp, vardep, inc, sui, traitt, annee, all_of(rhs))  %>% 
	filter(str_detect(vardep, "_o") )	%>%
	mutate(vardep = droplevels(vardep)) %>% 
	mutate_at(vars(sui, inc), as.factor) %>%
	mutate_at(vars(sui, inc),  ~fct_recode (., "<1/semaine" = "< 1/semaine")) %>% 
	mutate_at(vars(sui, inc),  ~fct_relevel(., list_ordre_freq )) 


# ce que j'ai fait -------
# avec un modele linéaire pour pouvoir comparer
dfw <- data_orig %>% 
	mutate(inc = as.numeric(as.factor(inc)),
				 sui = as.numeric(as.factor(sui))
				 )


form_old <- arsenal::formulize(y = "sui",
																 x = c("inc", "traitt", rhs ))																 			

res_old <- lm(formula = form_old, data = dfw)

# ce que j'aurais du faire ------

dfl <- data_orig %>% 
	pivot_longer(cols = c(inc, sui), names_to = "Phase", values_to = "value") %>% 	
	mutate_at(vars(vardep), as.factor)	%>% 
	mutate(phase01 = as.numeric(Phase =="sui")) %>% 
	mutate(traitt01 = as.numeric(traitt == "Perdu emploi")) %>% 
  mutate(did = phase01 * traitt01) %>% 
	mutate(value = as.numeric(as.factor(value)))

	
form_vrai <- arsenal::formulize(y = "value",
								x = c("did", "phase01", "traitt01", rhs ))

res_vrai <- lm(formula = form_vrai, data = dfl)

# différence à la main
dfw <- dfw %>% 
	mutate(dif = sui - inc)

form_dif <- arsenal::formulize(y = "dif",
																 x = c( "traitt", rhs ))

res_dif <- lm(formula = form_dif, data = dfw)

f_coefs<- function(mod) {
	return(
		broom::tidy(mod) %>% 
		filter( str_detect(term, "traitt") | term == "did" ) %>% 
		select(term, estimate, p.value)
	)
}

f_coefs(res_vrai) 
f_coefs(res_dif)
f_coefs(res_old)

# sur les données CEM ------
# cem_nest vient du fichier 08c
cem_orig<- cem_nest$data_cem

cemw<- cem_nest$data_cem[[1]] # la premiere ligne c le poisson
cemw<- cem_nest$data_cem[[5]] # fastfood
cemw<- cem_nest$data_cem[[3]] # viande rouge

ceml <- cemw %>% 
	dplyr::select(proj_isp, inc, sui, traitt, annee, weights, all_of(rhs))  %>% 
	mutate_at(vars(sui, inc), as.factor) %>%
		mutate_at(vars(sui, inc),  ~fct_relevel(., list_ordre_freq )) %>% 
pivot_longer(cols = c(inc, sui), names_to = "Phase", values_to = "value") %>% 	
	mutate(phase01 = as.numeric(Phase =="sui")) %>% 
	mutate(traitt01 = as.numeric(traitt == "Perdu emploi")) %>% 
	mutate(did = phase01 * traitt01) %>% 
	mutate(value_f = value) %>% 
	mutate(value = as.numeric(as.factor(value)))

form_vrai_lin <- arsenal::formulize(y = "value",
																x = c("did", "phase01", "traitt01", rhs ))
form_vrai_ol <- arsenal::formulize(y = "value_f",
																x = c("did", "phase01", "traitt01", rhs ))

form_vieux_ol <- arsenal::formulize(y = "sui",
																	 x = c("inc",  "traitt", rhs ))

cem_did_lin <- lm(formula = form_vrai_lin, data = ceml, weights = weights)



cem_did_ol <- polr(formula = form_vrai_ol, data = ceml , Hess = TRUE, weights = weights)

cem_vieux <- polr(formula = form_vieux_ol, data = cemw , Hess = TRUE, weights = weights)

stargazer(cem_vieux, cem_did_ol, type = "text", omit = rhs,
					report=('vc*p'))