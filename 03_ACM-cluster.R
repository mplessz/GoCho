# MP projet HDR6

# ACM sur les chômeurs avec imputation des données manquantes

# démarche : 
	# ACM avec imputation des non-réponses
	# classification
	# refaire la même ACM (avec NR) in incluant cluster dans les variables quali
	# produire les tableaux et graphiques de l'ACM


# début -----
library(haven)
library(tidyverse)
library(FactoMineR)
library(missMDA)
library(knitr)
library(RColorBrewer)
library(ggrepel) 
library(questionr)

options(OutDec= ",")

# données ----

data_orig <- read_dta("Data/Cree/HDR6_02_chomeurs.dta")

# préparation

df.acm <- data_orig %>% 
	mutate_if(is.numeric, as_factor) %>%
	select(proj_isp, entrain,  rorigreschom,
				 revuc_mi, astopsante, diplome3, cp_jmstrav, avecenf01, 
				 conjemploi, age_cl,  homme,  tuu2012_cl,
				 cspvol, diffinnow,  rorigresproch) %>% 
	column_to_rownames("proj_isp")

# 1. première MIMCA -----
qualisup <- which(colnames(df.acm) %in% c("cspvol", "diffinnow", "rorigresproch"))

res.impute <- missMDA::imputeMCA(df.acm, ncp = 4, quali.sup= qualisup )

res.mca <- MCA(df.acm, tab.disj = res.impute$tab.disj, quali.sup = qualisup, ncp = 4)


# 2. cluster ----

res.hcpc <- HCPC(res.mca , nb.clust = 4)
saveRDS(res.hcpc, file = "Data/res.hcpc.RDS")

## garder le classement de chaque individu
df.clus <- res.hcpc$data.clust %>% rownames_to_column(var = "proj_isp") %>% #récupérer proj_isp pour pouvoir faire des join
	as_tibble()  %>% 
	mutate(clust = fct_recode(clust, "Classe 1" = "1",
														"Classe 2" = "2",
														"Classe 3" = "3",
														"Classe 4" = "4"
	)) %>%  select(proj_isp, clust)

# 3. refaire l'ACM avec cluster en variable supplémentaire -----
df.acm <- df.acm %>%  rownames_to_column("proj_isp") %>% 
	full_join(df.clus, by = "proj_isp") %>% column_to_rownames("proj_isp")

dim(df.acm)	

qualisup <- which(colnames(df.acm) %in% c("cspvol", "diffinnow", "rorigresproch", "clust"))

res.impute <- missMDA::imputeMCA(df.acm, ncp = 4, quali.sup= qualisup )

res.mca <- MCA(df.acm, tab.disj = res.impute$tab.disj, 
							 quali.sup = qualisup,
							 ncp = 4)

# 4. tableaux  sur l'ACM complète ------
seuil <- 100 / nrow(res.mca$var$coord) # seuil : contribution moyenne


# tableau de résultats ----


frequences <- gather(df.acm, variables, modalites) %>% # étendre le jeu de données par variable et modalité
	count(variables, modalites) %>% # compter le nombre de couples "variable/modalité" unique (donc le nombre d'individus par modalité du jeu de données)
	group_by(variables) %>% 
	mutate(pourcentage = round(100 * n / nrow(df.acm), 1)) %>% # calculer des pourcentages pour chaque groupe de variable
	ungroup() %>% 
	select(variables, modalites, n, pourcentage)  # sélectionner les variables dans un ordre plus lisible


# Coordonnées (modalités actives) ----
coordonnees <- as.data.frame(round(res.mca$var$coord, 2)) %>% # récupérer les coordonnées des modalités actives et arrondir à deux décimales (c'est bien suffisant)
	rename_all(tolower) %>% # tout en minuscules
	rename_all(~ str_replace(., " ", "")) %>% # renommer les variables en supprimant les espaces : par exemple : "dim 1" devient "dim1" 
	rename_all(~ str_c(., "coord", sep = "_")) %>% # ajouter le suffixe _coord à chaque nom de variable. On obtient ainsi par exemple "dim1_coord"
	mutate(modalites = rownames(.)) # récupérer les noms des modalités, stockées dans le nom des lignes de res.mca$var$coord


# Contributions (modalités actives) ----
contributions <- as.data.frame(round(res.mca$var$contrib, 2))  %>% 
	rename_all(tolower) %>% 
	rename_all(~ str_replace(., " ", "")) %>% 
	rename_all(~ str_c(., "contrib", sep = "_")) %>% 
	rownames_to_column("modalites")


resultats_actives <- frequences %>% 
	right_join(coordonnees, by = "modalites") %>% 
	right_join(contributions, by = "modalites") %>%  # fusionner les jeux de données ; la clé de fusion (implicite) est la variable "modalites", qui est commune à tous. 
	mutate(type = "Variable active") %>% # ajout d'une colonne contenant la chaîne de caractères "Variable active" (pour pouvoir distinguer plus tard avec les variables supplémentaires)
	select(type, variables, modalites, n, pourcentage,
				 contains("dim1"), contains("dim2"),
				 contains("dim3"), contains("dim4"))


coordonnees_sup <- as.data.frame(round(res.mca$quali.sup$coord, 2)) %>% # la démarche est la même que supra, mais avec le sous-objet quali.sup qui stocke les informations sur les variables qualitatives supplémentaires
	rename_all(tolower) %>%
	rename_all(~ str_replace(., " ", "")) %>% 
	rename_all(~ str_c(., "coord", sep = "_")) %>% 
	mutate(modalites = rownames(.))


# Assemblage du tableau des résultats (modalités actives) ----

resultats_sup <- frequences %>% 
	right_join(coordonnees_sup) %>% 
	mutate(type = "Variable supplémentaire") %>% # comme supra pour le tableau des résultats des modalités actives : on distingue ici le type de variable.
	select(type, variables, modalites, n, pourcentage,
				 contains("dim1"), contains("dim2"),
				 contains("dim3"), contains("dim4"))

resultats_complet <- bind_rows(resultats_actives, resultats_sup)


write_csv2(resultats_complet, file = "Resultats/03_resultats_complet.csv")



# 5. graph inertie -----

res.mca$eig %>%  round(3) %>%  kable(caption = "Valeurs propres") 

variances <-  as.data.frame(res.mca$eig) %>% rownames_to_column() %>% # récupérer les noms de lignes (dim 1, dim 2, etc) dans une colonne distincte
	slice(1:9) 

variances %>% ggplot( aes(x = rowname)) + # initialisation du graphique et de l'axe horizontal
	geom_bar(aes(y = `percentage of variance`),   # on indique le type de graphique (barplot) et la variable à représenter sur l'axe vertical
					 stat = "identity", 
					 fill = "grey") + # parce que j'aime bien le rouge
	xlab("") + # on enlève le label de l'axe des x, pas très utile
	ylab("% de variance") + # on renomme proprement le label de l'axe des y
	labs(title="Inertie des premières dimensions de l'ACM (%)") +
	theme_minimal() 

ggsave("Resultats/03_valeurspropres.png", width = 6, height = 5)


# 6. graph plan factoriel -----

	# extraire le % d'inertie de chaque axe
	i1 <- round(variances$`percentage of variance`[1], 1)
	i2 <- round(variances$`percentage of variance`[2], 1)

resultats_complet %>% 
	filter(dim1_contrib > seuil |
				 	dim2_contrib > seuil |
				 	is.na(dim2_contrib) & dim1_coord > 0.29 |
				 	is.na(dim2_contrib) & dim1_coord < -0.29 |
				 	variables == "clust") %>% # on part du tableau complet et on sélectionne, en plus des modalités actives qui passent le seuil, les modalités supplémentaires dont les coordonnées s'écartent de +/- 0.3 du barycentre (c'est parfaitement arbitraire...).
	
	ggplot( aes(x = dim1_coord, y = dim2_coord, 
							label = modalites,
							colour = type, # on distingue par des couleurs différentes les variables actives et supplémentaires
							size = n, 
							shape = type)) + 
	
	geom_point() +
	geom_text_repel(size = 3, segment.alpha = 0.5) +
	
	geom_hline(yintercept = 0, colour = "darkgrey", linetype="longdash") +
	geom_vline(xintercept = 0, colour = "darkgrey", linetype="longdash") +
	
	xlab(paste0("Axe 1 (", i1, " %)")) +
	ylab(paste0("Axe 2 (", i2, " %)")) +
	
	scale_color_manual(values = c("black", "darkgrey")) + # paramètres de couleur ; tout est possible ici... à vous de tester les lignes ci-dessous par exemple :
	# scale_color_brewer(palette = "Set1") +
	# scale_color_grey() +
	# scale_color_brewer(palette = "Accent")
	
	guides( colour = guide_legend(title="", # titre de la légende distinguant actives et supplémentaires
																nrow = 1),
					shape = guide_legend(title=""),
					size = FALSE) + # toujours pas de légende pour les tailles de point
	
	theme_minimal() +
	theme(legend.position="bottom") +
	
	coord_fixed(ratio = 1)

ggsave("Resultats/03_planfactoriel.png", width = 6, height = 6)


# 8. sauver les coordonnées et le cluster des individus ----


coord_mi <- res.mca$ind$coord %>% as.data.frame() %>%  
	rownames_to_column("proj_isp")  %>%  as_tibble() %>% 
	full_join(df.clus, by = "proj_isp") %>% 
	write_csv2("Data/Cree/HDR6-3-coord-cluster.csv")
# as.data.frame conserve les rownames