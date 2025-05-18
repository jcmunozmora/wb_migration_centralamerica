library(lme4)
library(dplyr)
library(pbapply)  # Para la barra de progreso
library(ggplot2)

############################################################
##  Helper: simulate one clustered binary dataset
############################################################
sim_one <- function(k, m, icc, p1, mde) {
  # p2: true prevalencia en tratamiento
  p2 <- p1 + mde
  
  # generar efectos aleatorios para inducir ICC
  sigma_b <- sqrt(icc * (pi^2 / 3) / (1 - icc))
  b <- rnorm(k, 0, sigma_b)
  
  # expandir a nivel de hogar  
  df <- data.frame(
    cluster = rep(1:k, each = m),
    treat   = rep(c(rep(0, floor(k/2)), rep(1, k - floor(k/2))), each = m)
  )
  
  lp <- qlogis(ifelse(df$treat == 0, p1, p2)) + b[df$cluster]
  df$outcome <- rbinom(nrow(df), 1, plogis(lp))
  df
}

############################################################
##  Wrapper: Monte-Carlo power for a (k, m) combination
############################################################
power_km <- function(k, m, icc, p1, mde, nrep = 50) {
  sig <- replicate(nrep, {
    dat <- sim_one(k, m, icc, p1, mde)
    fit <- glmer(outcome ~ treat + (1 | cluster),
                 data = dat, family = binomial,
                 control = glmerControl(optimizer = "bobyqa"))
    pval <- summary(fit)$coef["treat", "Pr(>|z|)"]  # Wald test
    pval < 0.05
  })
  mean(sig)  # empirical power
}

############################################################
##  Grid search around your targets per stratum
############################################################
# target sample sizes per stratum
target <- c(
  high_conflict     = 608,
  high_non_conflict = 176,
  low_conflict      = 640,
  low_non_conflict  = 176
)

icc   <- 0.06   # assumed common ICC (adjust as needed)
p1    <- 0.40   # baseline food-insecurity prevalence
mde   <- 0.08   # effect size you care to detect (e.g. 8 percentage points)

# Grid de posibles valores: m = households per cluster (por ejemplo, de 8 a 25)
grid <- expand.grid(
  m = 8:25  # HH per cluster
)

# Usamos pblapply en lugar de lapply para ver el progreso
out <- pblapply(names(target), function(stratum) {
  n_tot <- target[stratum]
  grid %>%
    mutate(
      k = ceiling(n_tot / m),          # número de clústeres mínimos requeridos
      n_design = k * m                 # total de HH en el diseño
    ) %>%
    rowwise() %>%
    mutate(
      power = power_km(k, m, icc = icc, p1 = p1, mde = mde, nrep = 400)
    ) %>%
    ungroup() %>%
    mutate(Stratum = stratum)
}) %>% 
  bind_rows()

############################################################
##  Seleccionar el “diseño óptimo” en cada estrato  
##  (minimizar el total de HH incluidos mientras se alcanza
##   la potencia objetivo, ≥ 0.80)
############################################################

design_opt <- out %>%
  filter(power >= 0.80) %>%
  group_by(Stratum) %>%
  slice_min(n_design, n = 1) %>%  # Diseño con menor n_design
  ungroup()

print(design_opt)

############################################################
##  Graphs  
############################################################

# Gráfico de la grilla de diseño y potencia por estrato
ggplot(out, aes(x = m, y = n_design, color = Stratum, group = Stratum)) +
  geom_line(alpha = 0.7) +
  geom_point(alpha = 0.7) +
  # Resaltar el diseño óptimo con un punto de mayor tamaño y borde en rojo
  geom_point(data = design_opt, aes(x = m, y = n_design),
             color = "red", size = 4, shape = 21, fill = "red") +
  facet_wrap(~Stratum, scales = "free_y") +
  labs(title = "Diseño óptimo: Total de HH vs. HH por clúster (m)",
       x = "Households per cluster (m)",
       y = "Total de HH en el diseño (n_design)",
       color = "Estrato") +
  theme_minimal(base_size = 12)

ggsave("img/Sampling_Optimal_Clusters.png", width = 10, height = 6, dpi = 300)

# Gráfico de la grilla de diseño y potencia por estrato
ggplot(out, aes(x = m, y = n_design, color = Stratum, group = Stratum)) +
  geom_line(alpha = 0.7) +
  geom_point(alpha = 0.7) +
  # Agregar etiquetas de potencia (si se desea, por ejemplo, como texto)
  # geom_text(aes(label = round(power, 2)), hjust = -0.2, size=3) +
  # Resaltar el diseño óptimo con un punto de mayor tamaño y borde en rojo
  geom_point(data = design_opt, aes(x = m, y = n_design),
             color = "red", size = 4, shape = 21, fill = "red") +
  facet_wrap(~Stratum, scales = "free_y") +
  labs(title = "Diseño óptimo: Total de HH vs. HH por clúster (m)",
       x = "Households per cluster (m)",
       y = "Total de HH en el diseño (n_design)",
       color = "Estrato") +
  theme_minimal(base_size = 12)

# Si deseas guardar el gráfico:
ggsave("img/Sampling_Optimal_Clusters.png", width = 10, height = 6, dpi = 300)
