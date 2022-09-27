# TESTS sur les erreurs et pvalues des odds-ratio

# pb : la plupart des packages ne recalculent pas les SE et pvalues quand ils passent le coef à l'exponentielle.
options(OutDec= ".")

library(questionr)
library(tidyverse)
library(stargazer)
library(gtsummary)

#modèle
data("hdv2003")
fit1 <- glm(sport ~ sexe, data = hdv2003, family = "binomial")

summary(fit1)
				
stargazer(fit1, t.auto=F, type = "text")

# on peut demander à Stargazer l'exponentielle du coeff = l'OR mais les SE, Pvalues et CI ne sont pas recalculés. Et il ne suffit pas de prendre l'exponentielle de l'erreur standard 
# (https://stackoverflow.com/questions/16236560/odds-ratios-instead-of-logits-in-stargazer-latex-output)

stargazer(fit1, apply.coef = exp, t.auto=F,  type = "text")

# modelsummary fait pareil:
modelsummary::modelsummary(fit1, exponentiate = T)

# mais la fonction questionr::odds.ratio() est juste

# calculer la nouvelle standard-error -----

# define a helper function to extract SE from glm output
se.coef <- function(glm.output){sqrt(diag(vcov(glm.output)))}

#Get the odds ratio
OR <- exp(coef(fit1))

# Then, we can get the `StdErr.OR` by multiplying the two:
Std.Error.OR <-  OR * se.coef(fit1)

#and give it to stargazer
stargazer(fit1, coef=list(OR), se = list(Std.Error.OR), t.auto=F, p.auto=F, type = "text")


# pvalues------
# calculer la pvalue
z <- coef(fit1)/se.coef(glm_out)

pvalue <- 2*pnorm(abs(coef(fit1)/se.coef(fit1)), lower.tail = F)

# valeurs obtenues
format(pvalue, scientific = F)

#donner la pvalue à stargazer 
stargazer(fit1, coef=list(OR), se = list(Std.Error.OR), t.auto=F, p= list(pvalue), p.auto = F, type = "text")
# ex :
stargazer(fit1, coef=list(OR), se = list(Std.Error.OR), t.auto=F,
					p= c(0.3, 0.5), p.auto = F, type = "text")

# repartir de odds.ratio() -------
foo <- odds.ratio(fit1) 

foo %>% select(OR, p) %>% 
	mutate(signif = stars.pval(p))
# pb: on ne peut pas retravailler avec kable, etc, sans perdre les petites étoiles...

stargazer(fit1, coef= list(foo$OR), p = list(foo$p),
					p.auto = F, type = "text",  report=('vc*'), single.row = T)
# eh ben on y est presque... sauf qu'on ne peut pas avoir les valeurs de p sur la meme ligne. ou alors il faut faire croire à stargazer que c'est le se et je trouve ça un peu pervers.
# https://stackoverflow.com/questions/62382339/r-stargazer-getting-p-values-into-one-line 

foof <-tbl_regression(fit1, exponentiate = T, show_single_row = sexe ) %>%  bold_p(t = 0.05) %>%  modify_header(update = label ~ "**Characteristic (N = {n})**") 


foof$table_body <-	foof$table_body %>% mutate(N = ifelse(row_type == "label", N, NA)) 

foof

# http://www.danieldsjoberg.com/gtsummary/articles/tbl_regression.html 

# https://stackoverflow.com/questions/64699682/adding-total-ns-f-variable-to-tbl-regression-using-gtsummary-package 