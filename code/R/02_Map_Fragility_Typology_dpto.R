rm(list = ls())
# Maps - PCA results
#packages
library(sf)
library(haven)
library(dplyr)
library(ggplot2)
library(viridis)
library(haven)
library(paletteer)
library(stringi)
library(paletteer)
library(tibble)
library(readxl)

# cd
#setwd("/Users/jcmunoz/Library/CloudStorage/OneDrive-UniversidadEAFIT/Projects/2025_WB_CentralAmerica/wb_migration_centralamerica/")
# Shapes
shape_GTM <- st_read("data/inputs/GTM_adm/GTM_adm1.shp")
shape_SLV <- st_read("data/inputs/SLV_adm/SLV_adm1.shp")
shape_NIC <- st_read("data/inputs/NIC_adm/NIC_adm1.shp")
shape_HND <- st_read("data/inputs/HND_adm/HND_adm1.shp")
# PCA Data
data <- read_dta("data/derived/temporalA3.dta") ## Result of the PCA

# Append
shape_GTM <- shape_GTM %>%
  dplyr::select(NAME_0, NAME_1)
shape_HND <- shape_HND %>%
  dplyr::select(NAME_0, NAME_1)
shape_NIC <- shape_NIC %>%
  dplyr::select(NAME_0, NAME_1)
shape_SLV <- shape_SLV %>%
  dplyr::select(NAME_0, NAME_1)

shape_combined <- rbind(shape_GTM, shape_HND, shape_NIC, shape_SLV)
# proof
ggplot(data = shape_combined) +
  geom_sf() +
  theme_minimal() +
  labs(title = "Mapa Combinado", subtitle = "Shapes unidos")

# Caracteres
shape_combined$NAME_0 <- toupper(stri_trans_general(shape_combined$NAME_0, "Latin-ASCII"))
shape_combined$NAME_1<- toupper(stri_trans_general(shape_combined$NAME_1, "Latin-ASCII"))

# MAP
# General Characteristics
# theme
theme <- theme_minimal() + 
  theme(
    legend.position = "none", 
    panel.grid = element_blank(), 
    axis.text = element_blank(),  
    axis.ticks = element_blank(),  
    axis.title = element_blank()  
  )


#####################
# Results using 2 
var <- read_excel("data/derived/variables_A3.xls")
var_2 <- var %>%
  dplyr::select(pais, departamento, puntaje_minmax_Fragility_2, puntaje_minmax_Violence_2, cat_2)

var_2 <- var_2 %>%
  rename(
    NAME_0 = pais,
    NAME_1 = departamento)

#var_2[var_2$NAME_0 == "EL SALVADOR", "NAME_0"] <-"SALVADOR" 
var_2[var_2$NAME_1 == "QUETZALTENANGO", "NAME_1"] <-"QUEZALTENANGO"


data_2 <- left_join(shape_combined, var_2, by = c("NAME_0", "NAME_1"))
data_2  <- st_transform(data_2 , crs = 3857)

map2_fragility <- ggplot(data_2) +
  geom_sf(aes(fill = factor(puntaje_minmax_Fragility_2)), color = "gray50", size = 0.1) +  # usa la variable min_max
  scale_fill_manual(values = c("1" = "#B4D4DA", "2" = "#1C6AA8"), name = "Prioritization") +  # Colores para los valores 1, 2 y 3
  geom_sf_text(aes(label = paste0(NAME_1)), 
               size = 2, color = "black", check_overlap = TRUE, fontface = "bold", angle = 0) +
  theme_minimal() +  
  theme +
  labs(title = " ",   
       subtitle = " ")

ggsave("img/mapa_grupo_fragility_A3.png", 
       plot = map2_fragility,   
       width = 12,            
       height = 10,           
       dpi = 300) 


# Violence

map2_violence <- ggplot(data_2) +
  geom_sf(aes(fill = factor(puntaje_minmax_Violence_2)), color = "gray50", size = 0.1) +  # usa la variable min_max
  scale_fill_manual(values = c("1" = "#F4D166", "2" = "#D15022"), name = "Prioritization") +  # Colores para los valores 1, 2 y 3
  geom_sf_text(aes(label = paste0(NAME_1)), 
               size = 2, color = "black", check_overlap = TRUE, fontface = "bold", angle = 0) +
  theme_minimal() +  
  theme +
  labs(title = " ",   
       subtitle = " ")

ggsave("img/mapa_grupo_violence_A3.png", 
       plot = map2_violence,   
       width = 12,            
       height = 10,           
       dpi = 300) 



# cat 

map2_total_2 <- ggplot(data_2) +
  # Fondo: mapa completo
  # Municipios de data_2 con cat_2 (para dar contexto)
  geom_sf(data = data_2, aes(fill = factor(cat_2)), color = "gray50", size = 0.1, alpha = 0.3) +
  geom_sf_text(aes(label = paste0(NAME_1)), 
               size = 2, color = "black", check_overlap = TRUE, fontface = "bold", angle = 0) +
  # Etiquetas
  scale_fill_manual(values = c("low - low"  = "#529985", 
                               "low - high" = "#ACB955", 
                               "high - low" = "#E7B04D", 
                               "high - high"= "#C26B51"),
                    name = "Prioritization") +
  theme_minimal() +
  labs(title = "Tipologías de fragilidad",
       subtitle = "")


ggsave("img/mapa_grupo_total_A3.png", 
       plot = map2_total_2,   
       width = 12,            
       height = 10,           
       dpi = 300) 


# Appendix

dataA1 <- read_dta("data/derived/temporalA1.dta")


#####################
# Results using 2 
#var <- read_excel("Databases/output/variablesA1.xls")

var <- read_excel("data/derived/variablesA11.xls")

var_2 <- var %>%
  dplyr::select(pais, departamento, puntaje_minmax_Fragility_2, puntaje_minmax_Violence_2, cat_2)

var_2 <- var_2 %>%
  rename(
    NAME_0 = pais,
    NAME_1 = departamento)

#var_2[var_2$NAME_0 == "EL SALVADOR", "NAME_0"] <-"SALVADOR" 
var_2[var_2$NAME_1 == "QUETZALTENANGO", "NAME_1"] <-"QUEZALTENANGO"


data_2 <- left_join(shape_combined, var_2, by = c("NAME_0", "NAME_1"))
data_2  <- st_transform(data_2 , crs = 3857)

map2_fragility <- ggplot(data_2) +
  geom_sf(aes(fill = factor(puntaje_minmax_Fragility_2)), color = "gray50", size = 0.1) +  # usa la variable min_max
  scale_fill_manual(values = c("1" = "#B4D4DA", "2" = "#1C6AA8"), name = "Prioritization") +  # Colores para los valores 1, 2 y 3
  geom_sf_text(aes(label = paste0(NAME_1)), 
               size = 2, color = "black", check_overlap = TRUE, fontface = "bold", angle = 0) +
  theme_minimal() +  
  theme +
  labs(title = " ",   
       subtitle = " ")

ggsave("img/mapa_grupo_fragilityA11.png", 
       plot = map2_fragility,   
       width = 12,            
       height = 10,           
       dpi = 300) 


# Violence

map2_violence <- ggplot(data_2) +
  geom_sf(aes(fill = factor(puntaje_minmax_Violence_2)), color = "gray50", size = 0.1) +  # usa la variable min_max
  scale_fill_manual(values = c("1" = "#F4D166", "2" = "#D15022"), name = "Prioritization") +  # Colores para los valores 1, 2 y 3
  geom_sf_text(aes(label = paste0(NAME_1)), 
               size = 2, color = "black", check_overlap = TRUE, fontface = "bold", angle = 0) +
  theme_minimal() +  
  theme +
  labs(title = " ",   
       subtitle = " ")

ggsave("img/mapa_grupo_violenceA11.png", 
       plot = map2_violence,   
       width = 12,            
       height = 10,           
       dpi = 300) 

# cat 

map2_total_2 <- ggplot(data_2) +
  geom_sf(aes(fill = factor(cat_2)), color = "gray50", size = 0.1) +  # usa la variable min_max
  scale_fill_manual(values = c("low - low" = "#529985", "low - high" = "#ACB955", "high - low" = "#E7B04D", "high - high" = "#C26B51"), name = "Prioritization") +  # Colores para los valores 1, 2 y 3
  geom_sf_text(aes(label = paste0(NAME_1)), 
               size = 2, color = "black", check_overlap = TRUE, fontface = "bold", angle = 0) +
  theme_minimal() +  
  theme +
  labs(title = " ",   
       subtitle = " ")

ggsave("img/mapa_grupo_totalA11.png", 
       plot = map2_total_2,   
       width = 12,            
       height = 10,           
       dpi = 300) 



