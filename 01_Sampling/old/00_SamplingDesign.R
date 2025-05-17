# Load necessary libraries
library(pwr)
library(ggplot2)
library(dplyr)
library(writexl)  


# Function to simulate MDE for binary outcomes based on sample size
simulate_mde_binary <- function(p1, sample_size, alpha, power, r2, oversample) {
  tryCatch({
    n_total <- sample_size / (1 + oversample)
    n_adj <- n_total * (1 - r2)  # Adjust for covariates
    pooled_p <- p1 * (1 - p1)
    delta <- sqrt((pwr.2p.test(n = n_adj, sig.level = alpha, power = power)$h^2) / (2 * pooled_p))
    return(delta)
  }, error = function(e) {
    return(NA)
  })
}

# Function to simulate MDE for continuous outcomes based on sample size
simulate_mde_continuous <- function(sd, sample_size, alpha, power, r2, oversample) {
  tryCatch({
    n_total <- sample_size / (1 + oversample)
    n_adj <- n_total * (1 - r2)  # Adjust for covariates
    mde <- sd * (pwr.t.test(n = n_adj, sig.level = alpha, power = power)$d)
    return(mde)
  }, error = function(e) {
    return(NA)
  })
}

# Study Parameters
alpha <- 0.05
power <- 0.8
oversample <- 0.1
r2_values <- list(migration = 0.3, food_insecurity = 0.25, dietary_diversity = 0.2)

# Baseline values
migration_base <- 0.35
food_insecurity_base <- 0.41
dietary_diversity_sd <- 5

# Sample size range
sample_sizes <- seq(200, 2600, by = 200)

# Primary strata: Fragility typology-specific proportions
fragility_proportions <- list(
  high_conflict = 0.18,
  high_non_conflict = 0.17,
  low_conflict = 0.39,
  low_non_conflict = 0.23
)

# Secondary strata: Gender and Ethnic group-specific proportions
female_headed_households <- 0.35
male_headed_households <- 0.65
indigenous_households <- 0.15
non_indigenous_households <- 0.85

# Simulate MDE for each outcome and sample size
migration_mde <- sapply(sample_sizes, function(n) simulate_mde_binary(migration_base, n, alpha, power, r2_values$migration, oversample))
food_insecurity_mde <- sapply(sample_sizes, function(n) simulate_mde_binary(food_insecurity_base, n, alpha, power, r2_values$food_insecurity, oversample))
dietary_diversity_mde <- sapply(sample_sizes, function(n) simulate_mde_continuous(dietary_diversity_sd, n, alpha, power, r2_values$dietary_diversity, oversample))

# Combine results into a data frame
results <- data.frame(
  SampleSize = rep(sample_sizes, 3),
  Outcome = c(rep("Migration Intention", length(sample_sizes)),
              rep("Food Insecurity", length(sample_sizes)),
              rep("Dietary Diversity", length(sample_sizes))),
  MDE = c(migration_mde, food_insecurity_mde, dietary_diversity_mde)
)

# Adjust sample sizes for primary and secondary strata
results_strata <- results %>%
  mutate(
    High_Conflict = SampleSize * fragility_proportions$high_conflict,
    High_Non_Conflict = SampleSize * fragility_proportions$high_non_conflict,
    Low_Conflict = SampleSize * fragility_proportions$low_conflict,
    Low_Non_Conflict = SampleSize * fragility_proportions$low_non_conflict,
    Female_SampleSize = SampleSize * female_headed_households,
    Male_SampleSize = SampleSize * male_headed_households,
    Indigenous_SampleSize = SampleSize * indigenous_households,
    Non_Indigenous_SampleSize = SampleSize * non_indigenous_households
  )

# Visualization
ggplot(results, aes(x = SampleSize, y = MDE, color = Outcome)) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  facet_wrap(~ Outcome, scales = "free_y", ncol = 2) +
  theme_minimal() +
  theme(legend.position = "bottom", text = element_text(size = 12)) +
  labs(x = "Sample Size", y = "Minimum Detectable Effect (MDE)", color = NULL) +
  geom_hline(aes(yintercept = min(MDE, na.rm = TRUE)), linetype = "dashed", color = "gray")

# Save the plot
ggsave("WB_Sampling_Size_vs_MDE_with_Strata.png", width = 8, height = 6, dpi = 300)

# Summary Table
summary_table <- results_strata %>% filter(SampleSize %in% c(200,600,800,1000,1200,1400,1600,2000,2200)) %>% select(-Male_SampleSize,-Non_Indigenous_SampleSize)
# Output summary table
summary_table
write_xlsx(summary_table, "WB_SampleSize.xlsx")
