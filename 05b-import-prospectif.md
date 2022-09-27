05b-cc-vardep-long
================
Marie Plessz
07/12/2020

``` r
tag <- "05b-cc-vardep-long"
```

# Objectif

Projet: HDR6

Objectif : importer proprement le fichier de données de Stata. facteurs,
etc.

## importer

``` r
data_orig <- read_dta("Data/Cree/HDR6_04_prosp_studypop.dta")
```

## transformer en facteurs

Les variables importées avec la classe `haven_labelled` sont
automatiquement transformées en facteurs par la fonction
`labelled::to_factor`. Il reste quelques variables à nettoyer.

Les labels des variables `_inc` et `_sui` sont perdues dans le reshape…
il faudrait reprendre les lignes de code correspondantes et les mettre
dans un dofile à part.

``` r
# transformer en facteur toutes les vars qui doivent l'être
df <- data_orig %>% 
    labelled::to_factor() %>% 
    mutate_at(vars("aq_modvie_refdoc", "alc_control_inc"), as_factor) %>% 
    
# recodages     
    mutate(astopcho = case_when(astopcho == 0 ~ "Non",
                                                         astopcho == 1 ~ "Oui"  )) %>% 
    mutate_if(is.factor, fct_drop) %>% 
    mutate(aq_modvie_refdoc = ordered(aq_modvie_refdoc, levels = c("I1", "I2", "I3"))) %>% 
    rename(annee = y )  

     
# labels manquants

var_label(df) <- list(
    annee = "Année d'inclusion",
    aq_modvie_refdoc = "Ref questionnr inclusion",
    traitt = "Statut 2017", 
    alc_control_inc = "Déjà bu alcool?")
```

``` r
# varlist <- generate_dictionary(df)
```

## éliminer les cas incomplets sur chaque var dep potentielle.

je prends dans le fichier 07-graph. Idéalement il faudrait pas avoir
besoin de le faire 2 fois

``` r
# pivoter 1 ligne par var dépendante et par indv
cc_vardep <- df %>% 
    select(proj_isp, traitt, c(ends_with("_inc"), ends_with("_sui")) ) %>% 
     pivot_longer(cols = c(ends_with("_inc"), ends_with("_sui")),
                            names_to = c( ".value", "Phase"),
                            names_pattern = "(.+)_(.+)") %>% 
    relocate(c(alc_control, fum_control), .before = Phase)%>% 
    mutate_at(vars(alc_n:poi_f), as.character) %>% 
    pivot_longer(cols = alc_n:poi_f, 
                             names_to = "vardep",
                             values_to = "value") %>% 
    pivot_wider(id_cols = c("proj_isp", "vardep" ), names_from = Phase, values_from = value) %>% 

    
# dans chaque vardep, supprimer les lignes pour lesquelles au moins 1 obs est manquante 
    mutate(cc = !is.na(inc) & !is.na(sui) ) %>% 
    filter(cc == 1)  %>% 
    select(-cc) 

# join avec les vars à l'inclusion
dfjoin <- df %>% 
    rename("fum_control" = "fum_control_inc") %>% 
    rename("alc_control" = "alc_control_inc") %>%   
    select(-c(ends_with("_inc"), ends_with("_sui")))
```

``` r
ccvardep_long <- inner_join(cc_vardep, dfjoin, by = "proj_isp") %>% mutate(vardep = as.factor(vardep))
```

``` r
# vérifier les effectifs 
ccvardep_long %>% group_by(traitt) %>% count(proj_isp) %>% count(traitt)
```

    ## # A tibble: 2 x 2
    ## # Groups:   traitt [2]
    ##   traitt           n
    ##   <fct>        <int>
    ## 1 En emploi    29843
    ## 2 Perdu emploi   718

``` r
#   traitt           n
#   <fct>        <int>
# 1 En emploi    29843
# 2 Perdu emploi   718

effectifs_complets <- ccvardep_long  %>% 
        group_by(vardep) %>% 
        count() 


saveRDS( effectifs_complets, "Doc/HDR6_05b-vardep-effectifs-complets.Rds")
```

## Sauver

``` r
saveRDS( ccvardep_long, "Data/Cree/HDR6_05b-cc-vardep-long.Rds")
```
