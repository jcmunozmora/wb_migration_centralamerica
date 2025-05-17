# Load necessary libraries
library(pwr)
library(ggplot2)
library(dplyr)

# Function to calculate binary outcome sample size
binary_sample_size <- function(p1, p2, alpha, power, r2, oversample) {
  # Calcular Cohen's h utilizando la fórmula correcta
  h <- abs(2 * asin(sqrt(p1)) - 2 * asin(sqrt(p2)))
  tryCatch({
    n_unadj <- pwr.2p.test(h = h, sig.level = alpha, power = power)$n
    n_adj <- n_unadj / (1 - r2) # Ajuste por covariables
    n_total <- n_adj * (1 + oversample) # Sobremuestreo
    return(ceiling(n_total))
  }, error = function(e) {
    return(NA) # Retorna NA si falla el cálculo
  })
}

# Function to calculate continuous outcome sample size
continuous_sample_size <- function(sd, mde, alpha, power, r2, oversample) {
  tryCatch({
    n_unadj <- pwr.t.test(d = mde / sd, sig.level = alpha, power = power)$n
    n_adj <- n_unadj / (1 - r2) # Adjust for covariates
    n_total <- n_adj * (1 + oversample) # Oversample
    return(ceiling(n_total))
  }, error = function(e) {
    return(NA) # Return NA if calculation fails
  })
}

# Study Parameters
alpha <- 0.05
power <- 0.8
oversample <- 0.1
r2_values <- list(migration = 0.3, food_insecurity = 0.2, dietary_diversity = 0.3)

# MDE ranges
migration_mdes <- seq(0.05, 0.10, by = 0.02)
food_insecurity_mdes <- seq(0.05, 0.15, by = 0.05)
dietary_diversity_mdes <- seq(0.5, 2, by = 0.5)

# Recommended sampling values (for vertical lines in plots)
migration_recommended <- 0.06
food_insecurity_recommended <- 0.1
dietary_diversity_recommended <- 1

# Baseline values
migration_base <- 0.43
food_insecurity_base <- 0.4
dietary_diversity_sd <- 5

# Gender-specific baseline values
female_headed_households <- 0.35 # Proportion of female-headed households
male_headed_households <- 0.65   # Proportion of male-headed households

# Ethnic group-specific baseline values
indigenous_households <- 0.15  # Proportion of indigenous households
non_indigenous_households <- 0.85 # Proportion of non-indigenous households

# Fragility typology-specific proportions
fragility_proportions <- list(
  high_conflict = 0.3,
  high_non_conflict = 0.2,
  low_conflict = 0.3,
  low_non_conflict = 0.2
)

# Calculate sample sizes for each outcome
migration_sample_sizes <- sapply(migration_mdes, function(mde) 
  binary_sample_size(migration_base, migration_base + mde, alpha, power, r2_values$migration, oversample))

food_insecurity_sample_sizes <- sapply(food_insecurity_mdes, function(mde) 
  binary_sample_size(food_insecurity_base, food_insecurity_base + mde, alpha, power, r2_values$food_insecurity, oversample))

dietary_diversity_sample_sizes <- sapply(dietary_diversity_mdes, function(mde) 
  continuous_sample_size(dietary_diversity_sd, mde, alpha, power, r2_values$dietary_diversity, oversample))

# Combine results into a data frame
results <- data.frame(
  Outcome = c(rep("Migration Intention", length(migration_mdes)),
              rep("Food Insecurity", length(food_insecurity_mdes)),
              rep("Dietary Diversity", length(dietary_diversity_mdes))),
  MDE = c(migration_mdes, food_insecurity_mdes, dietary_diversity_mdes),
  SampleSize = c(migration_sample_sizes, food_insecurity_sample_sizes, dietary_diversity_sample_sizes)
)

# Adjust sample sizes for gender, ethnic, and fragility strata
results_gender_ethnic_fragility <- results %>%
  mutate(
    Female_SampleSize = SampleSize * female_headed_households,
    Male_SampleSize = SampleSize * male_headed_households,
    Indigenous_SampleSize = SampleSize * indigenous_households,
    Non_Indigenous_SampleSize = SampleSize * non_indigenous_households,
    High_Conflict_SampleSize = SampleSize * fragility_proportions$high_conflict,
    High_Non_Conflict_SampleSize = SampleSize * fragility_proportions$high_non_conflict,
    Low_Conflict_SampleSize = SampleSize * fragility_proportions$low_conflict,
    Low_Non_Conflict_SampleSize = SampleSize * fragility_proportions$low_non_conflict
  )

# Visualization
ggplot(results, aes(x = MDE, y = SampleSize, color = Outcome)) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  facet_wrap(~ Outcome, scales = "free_x", ncol = 3) +
  theme_minimal() +
  theme(legend.position = "bottom", text = element_text(size = 10)) +
  geom_hline(aes(yintercept = min(SampleSize, na.rm = TRUE)), linetype = "dashed", color = "gray") +
  #geom_vline(data = data.frame(Outcome = c("Migration Intention", "Food Insecurity", "Dietary Diversity"), 
  #                             Recommended = c(migration_recommended, food_insecurity_recommended,   dietary_diversity_recommended)), 
#             aes(xintercept = Recommended), linetype = "dotted", color = "blue") +
  labs(x = "Minimum Detectable Effect (MDE)", y = "Sample Size (Adjusted)", color = NULL)+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))

ggsave("WB_Sampling.png",width = 6, height = 4, dpi = 300, units = "in", device='png')

# Combined total sample size
combined_sample_size <- sum(c(migration_sample_sizes, food_insecurity_sample_sizes, dietary_diversity_sample_sizes), na.rm = TRUE)

# Summary Table
summary_table <- results_gender_ethnic_fragility %>%
  group_by(Outcome) %>%
  summarise(
    Min_SampleSize = min(SampleSize, na.rm = TRUE),
    Max_SampleSize = max(SampleSize, na.rm = TRUE),
    Total_SampleSize = sum(SampleSize, na.rm = TRUE),
    Female_SampleSize = sum(Female_SampleSize, na.rm = TRUE),
    Male_SampleSize = sum(Male_SampleSize, na.rm = TRUE),
    Indigenous_SampleSize = sum(Indigenous_SampleSize, na.rm = TRUE),
    Non_Indigenous_SampleSize = sum(Non_Indigenous_SampleSize, na.rm = TRUE),
    High_Conflict_SampleSize = sum(High_Conflict_SampleSize, na.rm = TRUE),
    High_Non_Conflict_SampleSize = sum(High_Non_Conflict_SampleSize, na.rm = TRUE),
    Low_Conflict_SampleSize = sum(Low_Conflict_SampleSize, na.rm = TRUE),
    Low_Non_Conflict_SampleSize = sum(Low_Non_Conflict_SampleSize, na.rm = TRUE),
    Recommended_MDE = if_else(Outcome == "Migration Intention", migration_recommended,
                              if_else(Outcome == "Food Insecurity", food_insecurity_recommended, dietary_diversity_recommended))
  )

# Output combined sample size and summary table
list(
  Combined_Total_Sample_Size = combined_sample_size,
  Summary_Table = summary_table
)
