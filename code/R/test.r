###############################################################################
## 0. Packages & reproducibility --------------------------------------------
###############################################################################
packages <- c("sf", "dplyr", "ggplot2", "stringi", "readxl", "writexl", "viridis")
lapply(packages, require, character.only = TRUE)

set.seed(20240518)  # reproducible random draw

###############################################################################
## 1. Read & union shapefiles -----------------------------------------------
###############################################################################
# Shapes
shape_GTM <- st_read("data/inputs/GTM_adm/GTM_adm2.shp")
shape_SLV <- st_read("data/inputs/SLV_adm/SLV_adm2.shp")
shape_NIC <- st_read("data/inputs/NIC_adm/NIC_adm2.shp")
shape_HND <- st_read("data/inputs/HND_adm/HND_adm2.shp")

# Utilizar bind_rows para unir los sf

shape_combined <- rbind(shape_GTM, shape_HND, shape_NIC, shape_SLV)

###############################################################################
## 2. Join fragility typology -------------------------------------------------
###############################################################################
# Shapes
shape_GTM <- st_read("data/inputs/GTM_adm/GTM_adm2.shp")
shape_SLV <- st_read("data/inputs/SLV_adm/SLV_adm2.shp")
shape_NIC <- st_read("data/inputs/NIC_adm/NIC_adm2.shp")
shape_HND <- st_read("data/inputs/HND_adm/HND_adm2.shp")

# Append
shape_GTM <- shape_GTM %>%
  dplyr::select(NAME_0, NAME_1,NAME_2)
shape_HND <- shape_HND %>%
  dplyr::select(NAME_0, NAME_1,NAME_2)
shape_NIC <- shape_NIC %>%
  dplyr::select(NAME_0, NAME_1, NAME_2)
shape_SLV <- shape_SLV %>%
  dplyr::select(NAME_0, NAME_1,NAME_2)

shape_combined <- rbind(shape_GTM, shape_HND, shape_NIC, shape_SLV)
# proof
ggplot(data = shape_combined) +
  geom_sf() +
  theme_minimal() +
  labs(title = "Mapa Combinado", subtitle = "Shapes unidos")

# Caracteres
shape_combined$NAME_0 <- toupper(stri_trans_general(shape_combined$NAME_0, "Latin-ASCII"))
shape_combined$NAME_1<- toupper(stri_trans_general(shape_combined$NAME_1, "Latin-ASCII"))
shape_combined$NAME_2<- toupper(stri_trans_general(shape_combined$NAME_2, "Latin-ASCII"))

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



###############################################################################
## 3. Random selection of municipalities -------------------------------------
###############################################################################
sample_counts <- c(
  "low - low"   = 3,
  "low - high"  = 4,
  "high - low"  = 5,
  "high - high" = 6
)

selected_muni <- data_2 %>%
  split(.$cat_2) %>%
  lapply(function(df) {
    # Extraer el valor único de cat_2
    current_cat <- unique(df$cat_2)[1]
    n_sel <- sample_counts[current_cat]
    slice_sample(df, n = n_sel)
  }) %>%
  bind_rows()

###############################################################################
## 4. Plot & save map ---------------------------------------------------------
###############################################################################
# Crear mapa que muestra el resto de las municipalidades en gris y resalta las seleccionadas
map_selected <- ggplot() +
  # Fondo: mapa completo
  geom_sf(data = shape_combined, fill = "gray90", color = "white", size = 0.2) +
  # Municipios de data_2 con cat_2 (para dar contexto)
  geom_sf(data = data_2, aes(fill = factor(cat_2)), color = "gray50", size = 0.1, alpha = 0.3) +
  # Municipios seleccionados
  geom_sf(data = selected_muni, aes(fill = factor(cat_2)), color = "black", size = 0.5) +
  # Etiquetas
  geom_sf_text(data = selected_muni, aes(label = NAME_1), size = 2.5, color = "black", check_overlap = TRUE) +
  scale_fill_manual(values = c("low - low"  = "#529985", 
                               "low - high" = "#ACB955", 
                               "high - low" = "#E7B04D", 
                               "high - high"= "#C26B51"),
                    name = "Prioritization") +
  theme_minimal() +
  labs(title = "Municipios seleccionados por categoría",
       subtitle = "Selección aleatoria con números distintos por tipología")

# Guardar el mapa
ggsave("img/selected_municipalities_map.png", plot = map_selected, width = 12, height = 10, dpi = 300)

# Exportar los municipios seleccionados a un archivo Excel con todos sus atributos
write_xlsx(selected_muni, path = "data/derived/selected_municipalities.xlsx")