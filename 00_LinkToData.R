# Créer un lien symbolique vers les données Constances
#MP le 2020-10-15

# Permet de laisser les "vrais fichiers" sur le disque dur crypté 
# R trouve un lien vers les données

# install.packages("fs")

library(fs)
# file system functions

# vérifier que le lecteur K crypté est connecté et accessible
if (file_access("K:/2022-GoCho-Data") == FALSE) stop("Connecter le disque dur externe, lettre K, et entrer le mot de passe") 


# si le lien n'existe pas, le créer 
if (link_exists("Data/") == FALSE) link_create("K:/2022-GoCho-Data", new_path = "Data/", symbolic = T )


# afficher l'emplacement réel des données pour info
cat("Chemin réel des données :", link_path("Data/"), "\n Pour changer, utiliser la fonction fs::link_delete() et relancer le script.")


# idem pour accéder aux fichiers créés par Sehar

if (link_exists("Data-Sehar/") == FALSE) link_create("K:/2020-CALICO-Sehar-Marie/", new_path = "Data-Sehar/", symbolic = T )

cat("Chemin réel des données de Sehar :", link_path("Data-Sehar/"), "\n Pour changer, utiliser la fonction fs::link_delete() et relancer le script.")