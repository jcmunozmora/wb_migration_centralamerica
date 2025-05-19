###############################################################################
#  SEARCH THE MINIMUM (k, m) THAT REACHES ≥ 80 % POWER ‑– AND PLOT THE RESULTS
###############################################################################
library(dplyr)
library(tidyr)
library(purrr)
library(pbapply)        # Progress bar
library(future.apply)   # For parallel processing
library(lme4)           # GLMM modeling
library(ggplot2)
library(viridis)

plan(multisession, workers = parallel::detectCores() - 1)
pboptions(type = "timer")  # Set progress bar type

## ─────────────────────────────── INPUTS ────────────────────────────────── ##
alpha      <- 0.05
pow_target <- 0.80
nrep       <- 400
analysis   <- "tmean"   # or "glmm"

m_grid    <- c(5, 10, 15, 25)                    # Households per cluster to explore
icc_grid  <- c(0.01, 0.03, 0.05, 0.06, 0.08, 0.1)  # Intra-cluster correlation values
mde_grid  <- c(0.10, 0.12, 0.15, 0.20, 0.25, 0.25) # Candidate MDE values
p1_vec    <- rep(0.40, 4)                         # Baseline prevalence

## ───────────────────────── CARGA DE ESTRATOS ───────────────────────────── ##
var <- readxl::read_excel("data/derived/variables_A3.xls") %>%
        group_by(cat_2) %>%
        summarise(n_p = sum(poblacion, na.rm = TRUE), .groups = "drop") %>%
        mutate(n_p = n_p / sum(n_p))

targets <- c(
  high_conflict     = round(var$n_p[var$cat_2 == "high - high"] * 1800),
  low_conflict      = round(var$n_p[var$cat_2 == "low - high"]  * 1800),
  high_non_conflict = max(400, round(var$n_p[var$cat_2 == "high - low"] * 1800)),
  low_non_conflict  = max(400, round(var$n_p[var$cat_2 == "low - low"]  * 1800))
)

## ───────────────────── FUNCIONES DE SIMULACIÓN ─────────────────────────── ##
# sim_one(): Simulates binary outcomes for clusters including a covariate
# The covariate, simulated here as standard normal, is meant to explain ~30% of the residual variance.
sim_one <- function(k, m, icc, p1, mde, r2_cov = 0.3) {
  covariate <- rnorm(k * m)
  
  # Random assignment of clusters to treatment/control
  arm <- sample(rep(0:1, length.out = k))
  
  # Calculate between-cluster variance based on ICC
  sd_b <- sqrt(icc * (pi^2 / 3) / (1 - icc))
  b <- rnorm(k, 0, sd_b)
  
  # Baseline probability per cluster:
  p0 <- plogis(qlogis(p1) + b)
  # Probability under treatment (adjusted by mde):
  p1t <- plogis(qlogis(p1 + mde) + b)
  prob <- ifelse(arm == 0, p0, p1t)
  
  data.frame(
    cluster = rep(seq_len(k), each = m),
    treat   = rep(arm, each = m),
    covariate = covariate,
    outcome = rbinom(k * m, 1, prob)
  )
}

# Define test functions for power estimation.
test_glmm <- function(dat) {
  fit <- suppressMessages(
    glmer(outcome ~ treat + covariate + (1 | cluster),
          data    = dat,
          family  = binomial,
          control = glmerControl(optimizer = "bobyqa", calc.derivs = FALSE))
  )
  as.numeric(summary(fit)$coef["treat", "Pr(>|z|)"] < alpha)
}

test_tmean <- function(dat) {
  clu <- dat %>%
         group_by(cluster, treat) %>%
         summarise(p = mean(outcome), .groups = "drop")
  if (length(unique(clu$treat)) < 2) return(NA_real_)
  as.numeric(t.test(p ~ factor(treat), data = clu)$p.value < alpha)
}

tester <- if (analysis == "glmm") test_glmm else test_tmean

# Function to compute power for given design parameters.
power_km <- function(k, m, icc, p1, mde) {
  hits <- future_replicate(
    nrep,
    {
      dat <- sim_one(k, m, icc, p1, mde, r2_cov = 0.3)
      tryCatch(tester(dat), error = function(e) NA_real_)
    },
    future.seed = TRUE
  )
  mean(hits, na.rm = TRUE)
}

## ───────────────────── BÚSQUEDA DEL DISEÑO ÓPTIMO ──────────────────────── ##
find_min_design <- function(N_target, p1) {
  # Create grid (m, icc, mde) over which we evaluate the design.
  grid <- expand.grid(m = m_grid, icc = icc_grid, mde = mde_grid,
                      KEEP.OUT.ATTRS = FALSE)
  
  # Evaluate each combination using pbmapply to show a progress bar
  res <- pbmapply(function(m, icc, mde) {
            k <- pmax(4L, ceiling(N_target / m))   # Starting point for number of clusters
            repeat {
              pow <- power_km(k, m, icc, p1, mde)
              if (!is.na(pow) && pow >= pow_target) break
              k <- k + 2  # Increase the number of clusters by 2
              if (k > 500) { pow <- NA; break }  # Safety threshold
            }
            c(k = k, n_design = k * m, power = pow)
         },
         grid$m, grid$icc, grid$mde, SIMPLIFY = FALSE)
  
  res <- bind_cols(grid, bind_rows(res))
  
  best <- res %>%
            filter(power >= pow_target) %>%
            arrange(n_design, k, m) %>%
            slice(1)
  
  list(full = res, best = best)
}

## ──────────────────── CALCULAR POR CADA ESTRATO ────────────────────────── ##
results_list <- imap(targets, function(N, nm) {
  fd <- find_min_design(N, p1_vec[1])
  mutate(fd$full, Stratum = nm)
})
results     <- bind_rows(results_list)          # Complete results table
opt_designs <- bind_rows(lapply(results_list, `[[`, "best"))

cat("\nDiseños mínimos que alcanzan ≥ 80 % de potencia:\n")
print(opt_designs)

## ───────────────────── VISUALIZACIÓN (HEAT‑MAP) ─────────────────────────── ##
heat <- ggplot(results,
               aes(factor(m), factor(mde), fill = pmin(power, 1))) +
          geom_tile() +
          facet_grid(Stratum ~ icc, labeller = label_both) +
          scale_fill_viridis_c(name = "Power", limits = c(0, 1)) +
          labs(title = paste0("Power heat‑map (analysis: ", analysis,
                              ", nrep = ", nrep, ")"),
               x = "Households per cluster (m)",
               y = "MDE") +
          theme_minimal(base_size = 11)

print(heat)   # Display the heat map

ggsave("img/power_heat_final.png", heat, width = 9, height = 6, dpi = 300)
