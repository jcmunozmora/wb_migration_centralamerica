# Load required libraries
library(dplyr)
library(ggplot2)
library(lme4)      # For mixed models
library(simstudy)  # For power simulations
library(writexl)   # For exporting to Excel

# Parameters
final_sample_size <- 1400  # Final sample size
icc_values <- c(0.05, 0.1, 0.15)  # Intra-cluster correlation values
clusters_range <- seq(10, 50, by = 5)  # Number of clusters to test
mde <- 0.1  # Minimum Detectable Effect (binary outcome)
alpha <- 0.05  # Significance level
target_power <- 0.8  # Desired statistical power
reps <- 500  # Number of repetitions for the simulation

# Function to simulate statistical power
simulate_power <- function(clusters, icc, sample_size, mde, alpha, reps) {
  households_per_cluster <- floor(sample_size / clusters)
  power_results <- replicate(reps, {
    # Generate clustered data
    defs <- defData(varname = "cluster_effect", formula = 0, variance = icc, id = "cluster")
    defs <- defData(defs, varname = "y", formula = "cluster_effect", variance = (1 - icc), dist = "normal")
    dt <- genData(clusters, defs)
    dt <- addColumns(defDataAdd(varname = "treatment", dist = "binary", formula = 0.5), dt)
    dt <- genCluster(dt, cLevelVar = "cluster", numIndsVar = households_per_cluster, level1ID = "id")
    dt$y <- dt$y + dt$treatment * mde
    
    # Fit mixed effects model with error handling
    model <- tryCatch({
      glmer(y ~ treatment + (1 | cluster), data = dt, family = gaussian())
    }, error = function(e) NULL)  # Return NULL on error
    
    # Check if model converged and treatment coefficient exists
    if (!is.null(model)) {
      model_summary <- summary(model)
      if ("treatment" %in% rownames(model_summary$coefficients)) {
        p_value <- model_summary$coefficients["treatment", "Pr(>|z|)"]
        return(p_value < alpha)
      }
    }
    return(FALSE)  # If model fails or treatment coefficient is missing, mark iteration as FALSE
  })
  mean(power_results)  # Return the estimated power
}

# Simulate power for all cluster configurations
results <- expand.grid(Clusters = clusters_range, ICC = icc_values) %>%
  rowwise() %>%
  mutate(
    Households_Per_Cluster = floor(final_sample_size / Clusters),
    Power = simulate_power(Clusters, ICC, final_sample_size, mde, alpha, reps)
  )

# Identify the optimal configuration
optimal_clusters <- results %>%
  filter(Power >= target_power) %>%
  arrange(ICC, Clusters)

# Check if optimal_clusters is not empty before printing
if (nrow(optimal_clusters) > 0) {
  # Export results to Excel
  write_xlsx(list(
    "Power Simulation Results" = results,
    "Optimal Configuration" = optimal_clusters
  ), "Power_Simulation_Results.xlsx")
  
  # Print optimal configuration
  print("Optimal Cluster Configuration:")
  print(optimal_clusters)
} else {
  print("No se encontró ninguna configuración óptima que cumpla con el poder objetivo.")
}

# Visualization: Power vs. Number of Clusters
ggplot(results, aes(x = Clusters, y = Power, color = as.factor(ICC))) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  geom_hline(yintercept = target_power, linetype = "dashed", color = "red") +
  labs(x = "Number of Clusters", y = "Statistical Power",
       color = "Intra-Cluster Correlation (ICC)") +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom") +
  ggtitle("Simulation of Statistical Power by Cluster Configuration")