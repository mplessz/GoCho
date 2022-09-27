# MP projet HDR6

# Complément ACM : vérifie que les axes avec imputation sont fortement corrélés aux axes calculés sur cas complets

# dépend de 01_ACM_cluster

# ==> corrélations sont toutes supérieures à 0.95

# début -----
library(haven)
library(tidyverse)
library(FactoMineR)
library(knitr)
library(questionr)

# données ----

data_orig <- read_dta("Data/Cree/HDR6_02_chomeurs.dta")

# préparation

df.cc <- data_orig %>% 
	mutate_if(is.numeric, as_factor) %>%
	select(proj_isp, entrain,  rorigreschom,
				 revuc_mi, astopsante, diplome3, cp_jmstrav, avecenf01, 
				 conjemploi, age_cl,  homme,  tuu2012_cl,
				 cspvol, diffinnow,  rorigresproch) %>% 
	column_to_rownames("proj_isp") %>% 
	drop_na()

qualisup <- which(colnames(df.cc) %in% c("cspvol", "diffinnow", "rorigresproch"))

res.cc <- MCA(df.cc, quali.sup = qualisup, ncp = 4)


coord_tous <- res.cc$ind$coord %>% as.data.frame() %>%  
	rownames_to_column("proj_isp")  %>%  as_tibble() %>% 
	full_join( y = coord_mi , by = "proj_isp", suffix = c("_cc", "_mi")) %>% 
	rename_with(~ sub(" ", "", .x)) 

mat <- coord_tous %>% 
	select(-proj_isp, -clust) %>% 
	cor(use = "pairwise.complete.obs") %>% 
	as.data.frame %>% 
	rownames_to_column("v")  %>% 
	as_tibble() %>% 
	select(-contains("_cc")) %>% 
	filter( str_detect(v, "_cc")) %>% 
	as_tibble() %>% 
	print()

