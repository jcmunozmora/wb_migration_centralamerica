############################################
##  Libraries
############################################
library(pwr)      # power & sample–size calculations
library(dplyr)    # wrangling
library(ggplot2)  # plotting

############################################
##  Helper: binary -> Cohen’s h  <->  MDE
############################################
h2mde  <- function(h, p1) {                 # convert h  ->  p2 - p1
  p2 <- (sin(asin(sqrt(p1)) + h / 2))^2
  return(p2 - p1)
}
mde2h  <- function(mde, p1) {               # convert p2 - p1  ->  h
  p2 <- p1 + mde
  h  <- abs(2 * asin(sqrt(p1)) - 2 * asin(sqrt(p2)))
  return(h)
}

############################################
##  (1)  Binary outcome ––––––––––––––––––
##  given N_total  ->  smallest MDE
############################################
binary_mde <- function(p1,                    # baseline prevalence
                       N_total,              # TOTAL obs. you can afford
                       alpha  = .05,
                       power  = .80,
                       r2     = 0,           # R² of covariates
                       oversample = 0.10,
                       tol    = 1e-4) {

  ## 1. translate TOTAL N  ->  *per-group* n used by pwr.2p.test()
  N_eff   <- N_total / (1 + oversample)      # remove oversampling inflation
  n_per_g <- (N_eff * (1 - r2)) / 2          # undo the R² adjustment + 2-groups

  ## 2. monotone link   MDE  ->  power
  f <- function(h) pwr.2p.test(h = h,
                               n = n_per_g,
                               sig.level = alpha)$power - power

  ## 3. find h that makes  f(h) = 0
  h_star <- uniroot(f, interval = c(1e-6, 5))$root   # h can never exceed ~3.3

  ## 4. convert h*  ->  MDE
  return(h2mde(h_star, p1))
}

# Primary strata: Fragility typology-specific proportions

fragility_proportions <- list(
  high_conflict = 0.38,
  high_non_conflict = 0.11,
  low_conflict = 0.40,
  low_non_conflict = 0.11
)

# Secondary strata: Gender and Ethnic group-specific proportions
female_headed_households <- 0.35

############################################
##  (2)  Continuous outcome ––––––––––––––
##  given N_total  ->  smallest MDE
############################################
continuous_mde <- function(sd,
                           N_total,
                           alpha  = .05,
                           power  = .80,
                           r2     = 0,
                           oversample = 0.10) {

  N_eff <- N_total / (1 + oversample)        # remove oversampling inflation
  n_per_g <- (N_eff * (1 - r2)) / 2

  ## Find Cohen’s d that reaches the target power
  f <- function(d) pwr.t.test(d = d,
                              n = n_per_g,
                              sig.level = alpha,
                              type = "two.sample")$power - power

  d_star <- uniroot(f, interval = c(1e-4, 5))$root
  return(d_star * sd)                        # MDE on the original scale
}

############################################
##  PARAMETERS
############################################
alpha  <- 0.05 # significance level
power  <- 0.80 # desired power
overs  <- 0.10 # oversampling inflation

p1_migration       <- 0.35 # baseline prevalence of migration intention
p1_food_insecurity <- 0.40 # baseline prevalence of food insecurity
sd_diet_div        <- 2    # baseline standard deviation of dietary diversity

r2s <- list(migration        = 0.30,
            food_insecurity  = 0.20,
            diet_diversity   = 0.30)

## Candidate TOTAL sample sizes you want to “try out”
N_grid <- seq( 600,  3000, by = 100)   # adapt as needed

############################################
##  RUN THE “WHAT-IF” GRID
############################################
out <- tibble(
  N_total = rep(N_grid, 3),
  Outcome = rep(c("Migration Intention",
                  "Food Insecurity",
                  "Dietary Diversity"),
                each = length(N_grid))
) %>%
  rowwise() %>%
  mutate(
    MDE = case_when(
      Outcome == "Migration Intention" ~ 
        binary_mde(p1_migration, N_total, alpha, power,
                   r2 = r2s$migration, oversample = overs),
      Outcome == "Food Insecurity" ~ 
        binary_mde(p1_food_insecurity, N_total, alpha, power,
                   r2 = r2s$food_insecurity, oversample = overs),
      Outcome == "Dietary Diversity" ~ 
        continuous_mde(sd_diet_div, N_total, alpha, power,
                       r2 = r2s$diet_diversity, oversample = overs)
    )
  ) %>%
  ungroup()

out$Observations <- out$N_total  

# Exportar el data frame a CSV sin row names
write.csv(out, file = "data/derived/mde_grid.csv", row.names = FALSE)

############################################
##  PLOT:  MDE  vs  TOTAL N
############################################
example <- tibble(
  Outcome = c("Migration Intention", "Food Insecurity", "Dietary Diversity"),
  MDE_example = c(
    binary_mde(p1_migration, 1600, alpha, power, r2s$migration, overs),
    binary_mde(p1_food_insecurity, 1600, alpha, power, r2s$food_insecurity, overs),
    continuous_mde(sd_diet_div, 1600, alpha, power, r2s$diet_diversity, overs)
  )
)

# Graficar el MDE versus el tamaño total de la muestra
ggplot(out, aes(x = N_total, y = MDE, colour = Outcome)) +
  geom_line(size = 1) +
  geom_vline(xintercept = 1600, linetype = "dashed", color = "black") +
  geom_hline(data = example, aes(yintercept = MDE_example, colour = Outcome), 
             linetype = "dashed", size = 0.8) +
  geom_text(data = example, 
            aes(x = 1600, y = MDE_example, 
                label = round(MDE_example, 2), colour = Outcome),
            vjust = -0.5, hjust = 0, size = 3) +
  facet_wrap(~ Outcome, scales = "free_y", ncol = 3) +
  theme_minimal(base_size = 10) +
  theme(legend.position = "bottom") +
  labs(x = "Total Sample Size (incl. oversampling)",
       y = "Minimum Detectable Effect (MDE)",
       colour = NULL)

ggsave("img/WB_MDE_vs_N.png",
       width = 10, height = 4, dpi = 300, units = "in")

############################################
##  EXAMPLE:  What MDE do we get if we can
##            survey exactly 2,000 HH?
############################################
example_N <- 1600
list(
  Mig_MDE  = binary_mde(p1_migration, example_N, alpha, power,
                        r2s$migration, overs),
  Food_MDE = binary_mde(p1_food_insecurity, example_N, alpha, power,
                        r2s$food_insecurity, overs),
  DDS_MDE  = continuous_mde(sd_diet_div, example_N, alpha, power,
                            r2s$diet_diversity, overs)
)

# Estimar el número de observaciones por fragilidad (redondeado)
obs_by_fragility <- sapply(fragility_proportions, function(prop) round(prop * example_N))
print(obs_by_fragility)
