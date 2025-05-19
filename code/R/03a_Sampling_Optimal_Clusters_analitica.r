###############################################################################
#  ANALYTIC POWER  +  BUDGET FILTER  +  ENHANCED VISUALS (WITH COVARIATE ADJUSTMENT: R² = 30%)
###############################################################################
library(dplyr);  library(tidyr);  library(purrr)
library(ggplot2); library(viridis)

alpha        <- 0.05
pow_target   <- 0.80
budget_limit <- 1900                # ←  ❗  máximo de encuestas
p0           <- 0.40                # prevalencia base

m_grid    <- c(5, 10, 15, 25)                    # Households per cluster to explore
icc_grid  <- c(0.01, 0.03, 0.05, 0.06, 0.08, 0.1)  # Intra-cluster correlation values
mde_grid  <- c(0.10, 0.12, 0.15) # Candidate MDE values

## ─────────  estratos y tamaños base  ───────── ##
var <- readxl::read_excel("data/derived/variables_A3.xls") |>
         group_by(cat_2) |>
         summarise(w = sum(poblacion, na.rm = TRUE), .groups = "drop") |>
         mutate(w = w / sum(w))

targets <- c(
  high_conflict     = round(var$w[var$cat_2=="high - high"] * 1800),
  low_conflict      = round(var$w[var$cat_2=="low - high"]  * 1800),
  high_non_conflict = max(400, round(var$w[var$cat_2=="high - low"] * 1800)),
  low_non_conflict  = max(400, round(var$w[var$cat_2=="low - low"]  * 1800))
)

## ─────────  fórmula cerrada para potencia CON AJUSTE POR COVARIANTE (R² = 30 %)  ───────── ##
power_clu <- function(k, m, icc, p0, mde, alpha = 0.05, r2_cov = 0.3){
  p1   <- p0 + mde
  deff <- 1 + (m - 1) * icc
  n_e  <- (k / 2) * m / deff               # effective sample size per arm
  n_e_adj <- n_e * (1 - r2_cov)             # adjust for covariates explaining 30% of variance
  se   <- sqrt((p0 * (1 - p0) + p1 * (1 - p1)) / n_e_adj)
  z    <- abs(mde) / se
  z_a  <- qnorm(1 - alpha/2)
  pnorm(z - z_a)
}

## ─────────  barrido rápido  ───────── ##
results <- imap_dfr(targets, function(N, name){
  expand_grid(m = m_grid, icc = icc_grid, mde = mde_grid) |>
    rowwise() |>
    mutate(
      k = {                         # crecer k hasta ≥ 80 % power o quedarnos sin presupuesto
        k_tmp <- max(4, 2 * ceiling(N / (2 * m)))
        repeat {
          n_des <- k_tmp * m
          if(n_des > budget_limit){ pow <- NA; break }
          pow <- power_clu(k_tmp, m, icc, p0, mde, alpha, r2_cov = 0.3)
          if(pow >= pow_target) break
          k_tmp <- k_tmp + 2
        }
        k_tmp
      },
      power = power_clu(k, m, icc, p0, mde, alpha, r2_cov = 0.3),
      n_design = k * m,
      within_budget = n_design <= budget_limit,
      Stratum = name
    ) |>
    ungroup()
})

## ─────────  mejor diseño dentro de presupuesto  ───────── ##
opt_designs <- results |>
                 filter(within_budget, power >= pow_target) |>
                 arrange(Stratum, n_design, k, m) |>
                 group_by(Stratum) |>
                 slice(1)

cat("\nDiseños óptimos (potencia ≥ 0.80 y ≤ 1 900 encuestas):\n")
print(opt_designs)

icc_o <- opt_designs$icc[1]

# Filter the results for ICC = valor óptimo (e.g. 0.05)
results_icc05 <- results %>% 
  filter(icc == icc_o)

scatter_improved <- ggplot(results_icc05, aes(n_design, power, colour = within_budget)) +
  geom_hline(yintercept = pow_target, linetype = "dotted", color = "blue", size = 1) +
  geom_vline(xintercept = budget_limit, linetype = "dashed", color = "red", size = 1) +
  geom_point(alpha = 0.8, size = 3) +
  # Add labels for the optimal designs from opt_designs
  geom_text(data = opt_designs, 
            aes(x = 1200, y = 0.82, 
                label = paste0("n=", n_design, "\n(k=", k, ", m=", m, ")")),
            vjust = -1, hjust = 0.5, size = 3.5, color = "black", fontface = "bold") +
  scale_colour_manual(values = c(`TRUE` = "#E41A1C", `FALSE` = "grey50"),
                      labels = c("Within budget", "Over budget"),
                      name = "") +
  facet_wrap(~ Stratum, labeller = label_both) +
  labs(title = paste0("Design Size vs. Power (ICC = ", icc_o, ")"),
       x = "Total Interviews (k × m)",
       y = "Power") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold", hjust = 0.5),
        legend.position = "top",
        strip.text = element_text(face = "bold"))

print(scatter_improved)

# Optionally, save the plot
ggsave("img/power_scatter_budget_ICC05_optDesigns.png", scatter_improved, width = 10, height = 6, dpi = 300)