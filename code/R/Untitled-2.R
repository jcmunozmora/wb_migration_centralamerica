###############################################################################
#  SEARCH THE MINIMUM (k,m) THAT ACHIEVES ≥ 80% POWER BY STRATUM
###############################################################################
library(dplyr); library(tidyr); library(ggplot2)
library(lme4);  library(pbapply); library(future.apply)
plan(multisession, workers = parallel::detectCores() - 1)
pboptions(type = "txt")

## ────────────────────────────── INPUTS ──────────────────────────────────── ##
alpha      <- 0.05                   # nivel de significancia
pow_target <- 0.80                   # potencia deseada
nrep       <- 800                    # réplicas Monte-Carlo
analysis   <- "tmean"                # "glmm" o "tmean"

m_grid     <- 4:15                   # hogares por clúster que vamos a probar
icc_grid   <- c(0.03, 0.04, 0.06)    # valores plausibles del ICC
mde_grid   <- c(0.08, 0.10, 0.12)    # tamaños de efecto a detectar
p1_vec     <- rep(0.40, 4)           # prevalencia base por estrato (p0)

## ─────────────────────── STRATA & MUESTRA BASE ─────────────────────────── ##
var <- readxl::read_excel("data/derived/variables_A3.xls") |>
         group_by(cat_2) |>
         summarise(n_p = sum(poblacion, na.rm = TRUE), .groups = "drop") |>
         mutate(n_p = n_p / sum(n_p))

targets <- c(
  high_conflict     = round(var$n_p[var$cat_2 == "high - high"] * 1800),
  low_conflict      = round(var$n_p[var$cat_2 == "low - high"]  * 1800),
  high_non_conflict = max(400, round(var$n_p[var$cat_2 == "high - low"] * 1800)),
  low_non_conflict  = max(400, round(var$n_p[var$cat_2 == "low - low"]  * 1800))
)

## ───────────────────── FUNCIONES SIMULACIÓN & TEST ─────────────────────── ##
sim_one <- function(k, m, icc, p1, mde) {
  # genera un clúster RCT (½ tratamiento, ½ control)
  arm <- sample(rep(0:1, length.out = k))   # asignación balanceada
  sd_b <- sqrt(icc * (pi^2 / 3) / (1 - icc))
  b    <- rnorm(k, 0, sd_b)
  p0   <- plogis(qlogis(p1)      + b)
  p1t  <- plogis(qlogis(p1+mde)  + b)
  prob <- ifelse(arm == 0, p0, p1t)

  data.frame(
    cluster = rep(seq_len(k), each = m),
    treat   = rep(arm,        each = m),
    outcome = rbinom(k * m, 1, rep(prob, each = m))
  )
}

test_glmm <- function(dat) {
  fit <- suppressMessages(
    glmer(outcome ~ treat + (1 | cluster),
          data    = dat,
          family  = binomial,
          control = glmerControl(optimizer = "bobyqa", calc.derivs = FALSE))
  )
  as.numeric(summary(fit)$coef["treat", "Pr(>|z|)"] < alpha)
}
test_tmean <- function(dat) {
  clu <- dat |>
           group_by(cluster, treat) |>
           summarise(p = mean(outcome), .groups = "drop")
  if (length(unique(clu$treat)) < 2) return(NA_real_)
  as.numeric(t.test(p ~ factor(treat), data = clu)$p.value < alpha)
}
tester <- if (analysis == "glmm") test_glmm else test_tmean

power_km <- function(k, m, icc, p1, mde) {
  hits <- future_replicate(nrep, {
    dat <- sim_one(k, m, icc, p1, mde)
    tryCatch(tester(dat), error = function(e) NA_real_)
  }, future.seed = TRUE)
  mean(hits, na.rm = TRUE)
}

## ──────────────────── BÚSQUEDA DEL DISEÑO ÓPTIMO ───────────────────────── ##
find_min_design <- function(N_target, p1) {
  res <- expand.grid(m = m_grid, icc = icc_grid, mde = mde_grid,
                     keep.row.names = FALSE) |>
    mutate(Design = pmap(list(m, icc, mde), function(m, icc, mde) {
      # crecer k hasta lograr potencia ≥ pow_target
      k    <- pmax(4L, ceiling(N_target / m))               # arranque razonable
      found <- FALSE
      while (!found && k <= 500) {                          # tope de seguridad
        pow <- power_km(k, m, icc, p1, mde)
        if (!is.na(pow) && pow >= pow_target) found <- TRUE else k <- k + 2
      }
      tibble(k = k, n_design = k * m,
             power = pow %||% NA_real_)
    })) |>
    unnest(Design)

  # elegir (m,k) con menor n_design (break ties por k más chico)
  res |>
    filter(power >= pow_target) |>
    arrange(n_design, k, m) |>
    slice(1)
}

## ───────────────────── CÁLCULO POR ESTRATO ─────────────────────────────── ##
library(purrr)
opt_designs <- imap_dfr(targets, function(N, name) {
  out <- find_min_design(N, p1_vec[1])
  mutate(out, Stratum = name)
})

print(opt_designs)
#> # A tibble: 4 × 8
#>   m     icc   mde      k n_design power Stratum            
#>  <int> <dbl> <dbl> <dbl>    <dbl> <dbl> <chr>              
#> 1     9  0.04  0.08    46       414   0.8 high_conflict     …
#> 2     …                                                      …

## ───────────────────── OPTIONAL: HEAT-MAPS, EXPORT, … ─────────────────────
# (puedes conservar el código de tus gráficos, sólo cambia 'results' por
#  tus nuevas tablas si quieres comparar la potencia alcanzada)
