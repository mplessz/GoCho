06-prosp-tableau-compare
================
Marie Plessz
05/11/2020

# préparer les données

``` r
data_orig <- read_dta("Data/Cree/HDR6_04_prosp_studypop.dta")

# isoler les noms des vars à traiter comme des facteurs
to_factor <- data_orig %>%
    select( -age,  -y, -proj_isp, -fm_per_inclusion, -traveffr) %>% 
    select( -matches("_c_")) %>% 
    select( -matches("_n_") )%>%                        
    map_lgl(is.numeric) %>%
        names

# traiter les facteurs
df <- data_orig %>% 
    mutate_at(to_factor, as_factor) %>% 
    mutate_if(is.factor, fct_drop) # se débarrasser des levels vides

# variables binaires converties en type "logique"
    # les sélectionner
to_lgl <-df %>%
    select_if(~length(levels(.))==2)    %>% 
    map_lgl(is.numeric) %>%
        names

    # créer les variables binaires. pour l'instant elles ont le même nom dans un autre objet.

# ATTENTION : suppose que 1 est toujours la modalité "oui"

lg <- data_orig %>% select(proj_isp, all_of(to_lgl) ) %>% 
    mutate_at(vars(all_of(to_lgl)), ~if_else(. == 1, "T", "F") ) %>% 
    mutate_at(vars(all_of(to_lgl)), as.logical ) 

    # join en renommant les logiques
df <- left_join(df, lg, by= "proj_isp", suffix = c("", "_l"))

df$traveffr_c<- as.numeric(as.character(df$traveffr))
```

``` r
# labels
var_label(df) <- list(homme_l = "Homme", 
                                 aveccouple01_l = "Vit en couple",
                                 avecenf01_l = "Vit avec enfant(s)",
                                 diffinnow_l = "Difficultés financières",
                                 age_cl = "Tranche d'âge",
                                 tuu2012_cl = "Taille unité urbaine",
                                 edu = "Diplôme",
                                 prive_l = "Secteur privé",
                                 astopsante_l = "A eu arrêts >6 mois (santé)",
                                 astopcho_l = "A eu arrêts >6 mois (chômage)",
                                 traveffr_c = "Effort physique au travail (max=14)"
                                 )
```

# tableau 1

J’utilise le package `gtsummary`.

``` r
# noms
prog <- glue("Programme: {tag}.Rmd")
myfile <- glue("{tag}.html")

t1_gt <- t1 %>% 
        as_gt() %>% 
    gt::tab_source_note(gt::md(
        c(
        "Source: Constances, extraction du 24/07/2020, données inclusion et 2017.", 
        prog)   
        )) %>% 
            tab_header(
    title = "Caractéristiques à l'inclusion selon la situation en 2017"  )   %>%
  tab_stubhead(label = "car") 

t1_gt %>% 
    gtsave(filename = myfile)
  # le htmal peut être collé dans Word.
  #pour l'instant impossible de spécifier un chemin dans gtsave.
  #je contourne : 
  
 file.copy(myfile, "Resultats", overwrite = TRUE)
```

    ## [1] TRUE

``` r
 file.remove(myfile)
```

    ## [1] TRUE

``` r
t1_gt 
```

<!--html_preserve-->
<style>html {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
}

#nowhdahvyw .gt_table {
  display: table;
  border-collapse: collapse;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: small;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: auto;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}

#nowhdahvyw .gt_heading {
  background-color: #FFFFFF;
  text-align: center;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#nowhdahvyw .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#nowhdahvyw .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 4px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#nowhdahvyw .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#nowhdahvyw .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#nowhdahvyw .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}

#nowhdahvyw .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}

#nowhdahvyw .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#nowhdahvyw .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#nowhdahvyw .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}

#nowhdahvyw .gt_group_heading {
  padding: 1px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
}

#nowhdahvyw .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}

#nowhdahvyw .gt_from_md > :first-child {
  margin-top: 0;
}

#nowhdahvyw .gt_from_md > :last-child {
  margin-bottom: 0;
}

#nowhdahvyw .gt_row {
  padding-top: 1px;
  padding-bottom: 1px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}

#nowhdahvyw .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 12px;
}

#nowhdahvyw .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 1px;
  padding-bottom: 1px;
  padding-left: 5px;
  padding-right: 5px;
}

#nowhdahvyw .gt_first_summary_row {
  padding-top: 1px;
  padding-bottom: 1px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
}

#nowhdahvyw .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 1px;
  padding-bottom: 1px;
  padding-left: 5px;
  padding-right: 5px;
}

#nowhdahvyw .gt_first_grand_summary_row {
  padding-top: 1px;
  padding-bottom: 1px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#nowhdahvyw .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#nowhdahvyw .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#nowhdahvyw .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#nowhdahvyw .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding: 1px;
}

#nowhdahvyw .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#nowhdahvyw .gt_sourcenote {
  font-size: 90%;
  padding: 1px;
}

#nowhdahvyw .gt_left {
  text-align: left;
}

#nowhdahvyw .gt_center {
  text-align: center;
}

#nowhdahvyw .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#nowhdahvyw .gt_font_normal {
  font-weight: normal;
}

#nowhdahvyw .gt_font_bold {
  font-weight: bold;
}

#nowhdahvyw .gt_font_italic {
  font-style: italic;
}

#nowhdahvyw .gt_super {
  font-size: 65%;
}

#nowhdahvyw .gt_footnote_marks {
  font-style: italic;
  font-size: 65%;
}
</style>
<div id="nowhdahvyw" style="overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<table class="gt_table">
<thead class="gt_header">
<tr>
<th colspan="3" class="gt_heading gt_title gt_font_normal" style>
Caractéristiques à l’inclusion selon la situation en 2017
</th>
</tr>
<tr>
<th colspan="3" class="gt_heading gt_subtitle gt_font_normal gt_bottom_border" style>
</th>
</tr>
</thead>
<thead class="gt_col_headings">
<tr>
<th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1">
<strong>Caractéristiques à l’inclusion</strong>
</th>
<th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1">
<strong>En emploi en 2017</strong>
</p>
<p>
(N = 29172)<sup class="gt_footnote_marks">1</sup>
</th>

      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1"><strong>Perdu emploi en 2017</strong></p>

<p>
(N = 707)<sup class="gt_footnote_marks">1</sup>
</th>

    </tr>

</thead>
<tbody class="gt_table_body">
<tr>
<td class="gt_row gt_left">
Homme
</td>
<td class="gt_row gt_center">
47,9%
</td>
<td class="gt_row gt_center">
44,8%
</td>
</tr>
<tr>
<td class="gt_row gt_left">
Vit en couple
</td>
<td class="gt_row gt_center">
79,3%
</td>
<td class="gt_row gt_center">
65,5%
</td>
</tr>
<tr>
<td class="gt_row gt_left">
Vit avec enfant(s)
</td>
<td class="gt_row gt_center">
62,7%
</td>
<td class="gt_row gt_center">
46,3%
</td>
</tr>
<tr>
<td class="gt_row gt_left">
Tranche d’âge
</td>
<td class="gt_row gt_center">
</td>
<td class="gt_row gt_center">
</td>
</tr>
<tr>
<td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">
18-29 ans
</td>
<td class="gt_row gt_center">
10,1%
</td>
<td class="gt_row gt_center">
20,7%
</td>
</tr>
<tr>
<td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">
30-39 ans
</td>
<td class="gt_row gt_center">
27,5%
</td>
<td class="gt_row gt_center">
25,9%
</td>
</tr>
<tr>
<td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">
40-49 ans
</td>
<td class="gt_row gt_center">
35,3%
</td>
<td class="gt_row gt_center">
25,7%
</td>
</tr>
<tr>
<td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">
50 ans et plus
</td>
<td class="gt_row gt_center">
27,1%
</td>
<td class="gt_row gt_center">
27,7%
</td>
</tr>
<tr>
<td class="gt_row gt_left">
Diplôme
</td>
<td class="gt_row gt_center">
</td>
<td class="gt_row gt_center">
</td>
</tr>
<tr>
<td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">
&lt; Bac
</td>
<td class="gt_row gt_center">
13,3%
</td>
<td class="gt_row gt_center">
19,9%
</td>
</tr>
<tr>
<td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">
2
</td>
<td class="gt_row gt_center">
13,9%
</td>
<td class="gt_row gt_center">
19,0%
</td>
</tr>
<tr>
<td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">
3
</td>
<td class="gt_row gt_center">
29,8%
</td>
<td class="gt_row gt_center">
24,6%
</td>
</tr>
<tr>
<td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">
4
</td>
<td class="gt_row gt_center">
43,0%
</td>
<td class="gt_row gt_center">
36,5%
</td>
</tr>
<tr>
<td class="gt_row gt_left">
CSP actuelle ou plus longue
</td>
<td class="gt_row gt_center">
</td>
<td class="gt_row gt_center">
</td>
</tr>
<tr>
<td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">
Agric, Indep, Autre
</td>
<td class="gt_row gt_center">
3,1%
</td>
<td class="gt_row gt_center">
5,1%
</td>
</tr>
<tr>
<td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">
Cadre, prof. intell. sup.
</td>
<td class="gt_row gt_center">
39,3%
</td>
<td class="gt_row gt_center">
34,9%
</td>
</tr>
<tr>
<td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">
Profession intermediaire
</td>
<td class="gt_row gt_center">
31,3%
</td>
<td class="gt_row gt_center">
16,3%
</td>
</tr>
<tr>
<td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">
Employe
</td>
<td class="gt_row gt_center">
20,3%
</td>
<td class="gt_row gt_center">
32,7%
</td>
</tr>
<tr>
<td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">
Ouvrier
</td>
<td class="gt_row gt_center">
6,0%
</td>
<td class="gt_row gt_center">
11,0%
</td>
</tr>
<tr>
<td class="gt_row gt_left">
Secteur privé
</td>
<td class="gt_row gt_center">
49,8%
</td>
<td class="gt_row gt_center">
86,4%
</td>
</tr>
<tr>
<td class="gt_row gt_left">
Difficultés financières
</td>
<td class="gt_row gt_center">
7,6%
</td>
<td class="gt_row gt_center">
16,3%
</td>
</tr>
<tr>
<td class="gt_row gt_left">
A eu arrêts &gt;6 mois (chômage)
</td>
<td class="gt_row gt_center">
13,7%
</td>
<td class="gt_row gt_center">
28,4%
</td>
</tr>
<tr>
<td class="gt_row gt_left">
A eu arrêts &gt;6 mois (santé)
</td>
<td class="gt_row gt_center">
3,2%
</td>
<td class="gt_row gt_center">
6,1%
</td>
</tr>
<tr>
<td class="gt_row gt_left">
Effort physique au travail (max=14)
</td>
<td class="gt_row gt_center">
3,52 (3,14)
</td>
<td class="gt_row gt_center">
3,97 (3,64)
</td>
</tr>
<tr>
<td class="gt_row gt_left" style="text-align: left; text-indent: 10px;">
N manquantes
</td>
<td class="gt_row gt_center">
508
</td>
<td class="gt_row gt_center">
18
</td>
</tr>
</tbody>
<tfoot class="gt_sourcenotes">
<tr>
<td class="gt_sourcenote" colspan="3">
Source: Constances, extraction du 24/07/2020, données inclusion et 2017.
</td>
</tr>
<tr>
<td class="gt_sourcenote" colspan="3">
Programme: 06-prosp-tableau-compare.Rmd
</td>
</tr>
</tfoot>
<tfoot>
<tr class="gt_footnotes">
<td colspan="3">
<p class="gt_footnote">

<sup class="gt_footnote_marks"> <em>1</em> </sup>

Statistiques prépsentées: % en colonnes. Pour l’effort physique: moyenne
(écart-type). <br />
</p>
</td>
</tr>
</tfoot>
</table>
</div>
<!--/html_preserve-->
