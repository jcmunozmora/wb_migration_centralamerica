###############################################################################

#  SEARCH THE MINIMUM (k,m) THAT REACHES ≥ 80 % POWER ‑‑ AND PLOT THE RESULTS
###############################################################################
library(dplyr);  library(tidyr);      library(purrr)
library(pbapply);                     # barra de progreso
library(future.apply); library(lme4)  # simulación + GLMM
library(ggplot2);  library(viridis)   # gráficos
plan(multisession, workers = parallel::detectCores() - 1)
pboptions(type = "timer")             # formato de la barra

## ─────────────────────────────── INPUTS ────────────────────────────────── ##
alpha      <- 0.05
pow_target <- 0.80
nrep       <- 400
analysis   <- "tmean"                 # o "glmm"

m_grid <- c(10,15,25)                  # hogares por clúster a explorar
icc_grid   <- c(0.03, 0.04, 0.06)
mde_grid <- c(0.10, 0.12, 0.15) 
p1_vec     <- rep(0.40, 4)            # prevalencia base

## ───────────────────────── CARGA DE ESTRATOS ───────────────────────────── ##
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

## ───────────────────── FUNCIONES DE SIMULACIÓN ─────────────────────────── ##
sim_one <- function(k, m, icc, p1, mde) {
  arm <- sample(rep(0:1, length.out = k))     # ½ clústeres tratamiento
  sd_b <- sqrt(icc * (pi^2 / 3) / (1 - icc))  # varianza entre‑clúster
  b    <- rnorm(k, 0, sd_b)
  p0   <- plogis(qlogis(p1)      + b)
  p1t  <- plogis(qlogis(p1 + mde) + b)
  prob <- ifelse(arm == 0, p0, p1t)

  data.frame(cluster = rep(seq_len(k), each = m),
             treat   = rep(arm,        each = m),
             outcome = rbinom(k * m, 1, rep(prob, each = m)))
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
  hits <- future_replicate(
    nrep,
    {
      dat <- sim_one(k, m, icc, p1, mde)
      tryCatch(tester(dat), error = function(e) NA_real_)
    },
    future.seed = TRUE
  )
  mean(hits, na.rm = TRUE)
}

## ───────────────────── BÚSQUEDA DEL DISEÑO ÓPTIMO ──────────────────────── ##
find_min_design <- function(N_target, p1) {
  # Rejilla (m,icc,mde) que evaluaremos
  grid <- expand.grid(m = m_grid, icc = icc_grid, mde = mde_grid,
                      KEEP.OUT.ATTRS = FALSE)

  # pbmapply ‑‑ barra de progreso sobre cada fila de grid
  res  <- pbmapply(function(m, icc, mde) {
            k <- pmax(4L, ceiling(N_target / m))   # punto de arranque
            repeat {
              pow <- power_km(k, m, icc, p1, mde)
              if (!is.na(pow) && pow >= pow_target) break
              k <- k + 2                            # crece de 2 en 2
              if (k > 500) { pow <- NA; break }     # tope de seguridad
            }
            c(k = k, n_design = k * m, power = pow)
         },
         grid$m, grid$icc, grid$mde, SIMPLIFY = FALSE)

  res <- bind_cols(grid, bind_rows(res))

  best <- res |>
            filter(power >= pow_target) |>
            arrange(n_design, k, m) |>
            slice(1)

  list(full = res, best = best)
}

## ──────────────────── CALCULAR POR CADA ESTRATO ────────────────────────── ##
results_list <- imap(targets, function(N, nm) {
  fd <- find_min_design(N, p1_vec[1])
  mutate(fd$full, Stratum = nm)
})
results     <- bind_rows(results_list)          # tabla completa
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

print(heat)   # lo muestra en pantalla
ggsave("img/power_heat_final.png", heat, width = 9, height = 6, dpi = 300)
