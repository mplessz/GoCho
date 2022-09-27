02\_tableaux\_descriptives
================
Marie Plessz
05/11/2020

# préparer les données

``` r
data_orig <- read_dta("Data/Cree/HDR6_01_tous.dta")

df <- data_orig %>% 
    filter(emploi == 1 | emploi ==2) %>% 
    mutate_if(is.numeric, as_factor) %>% 
    select(-age, -revuc_cho) %>% 
    mutate(emploi = fct_recode(emploi, "Chômage" = "Demandeur d'emploi sans emploi")) %>% 
    mutate(cc = case_when(nmiss == 0 ~ "Complet",
                                                TRUE ~"Incomplet")) %>% 
    mutate_if(is.factor, fct_drop) # se débarrasser des levels vides

# labels
var_label(df) <- list(homme = "Homme", 
                                 aveccouple01 = "Vit en couple",
                                 avecenf01 = "Vit avec enfant(s)",
                                 diffinnow = "Difficultés financières",
                                 conjemploi = "Conjoint.e",
                                 cp_jmstrav = "Jamais travaillé >6mois",
                                 revuc_mi = "Revenu mensuel/UC",
                                 age_cl = "Tranche d'âge",
                                 tuu2012_cl = "Taille unité urbaine",
                                 cc = "Cas complet",
                                 diplome3 = "Diplôme"
                                 )

# labels des modalités
df <- df %>%  
    mutate(avecenf01 = fct_recode(avecenf01, 
        "Non" = "EnfantNON", "Oui" = "EnfantOUI"  )) %>% 
    mutate(conjemploi = fct_recode(conjemploi,
      "Conjoint en emploi" = "Cjt en emploi"  ,
        "Conjoint Sans emploi" = "Cjt Sans emploi"
    )) %>% 
    mutate(diffinnow = fct_recode(diffinnow,
        "Non" = "DiffFinMoisNON", "Oui" = "DiffFinMoisOUI")) %>% 
    mutate( entrain = fct_recode(entrain,
        "Jamais" = "JMSPasEntrain",
        "Parfois" = "PFSPasEntrain",
        "Souvent" = "SVTPasEntrain")) 
```

# tableau 1

J’utilise le package `gtsummary`.

    ## [1] FALSE

    ## [1] TRUE
