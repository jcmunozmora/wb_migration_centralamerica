import numpy as np
import pandas as pd
from statsmodels.regression.mixed_linear_model import MixedLM
from tqdm import tqdm
import itertools
import seaborn as sns
import matplotlib.pyplot as plt

# Simulation Parameters
final_sample_size = 1400  # Total sample size
fragility_proportions = {"high_conflict": 0.3, "high_non_conflict": 0.2,
                         "low_conflict": 0.3, "low_non_conflict": 0.2}
max_clusters_per_typology = {"high_conflict": 100, "high_non_conflict": 100,
                             "low_conflict": 100, "low_non_conflict": 100}
icc = 0.1  # Intra-cluster correlation
mde = 0.1  # Minimum Detectable Effect
alpha = 0.05  # Significance level
target_power = 0.8  # Target power
r_squared = 0.2  # Variance explained by covariates
reps = 1000  # Number of repetitions per configuration

# Function to simulate clustered data
def generate_clustered_data(clusters, households_per_cluster, icc, mde, r_squared):
    total_households = clusters * households_per_cluster
    cluster_effect_variance = icc * (1 - r_squared)
    residual_variance = (1 - icc) * (1 - r_squared)
    np.random.seed(42)  # For reproducibility

    # Generate cluster effects
    cluster_effects = np.random.normal(0, np.sqrt(cluster_effect_variance), clusters)
    
    # Generate household data
    data = []
    for cluster in range(clusters):
        for household in range(households_per_cluster):
            treatment = np.random.binomial(1, 0.5)
            y = cluster_effects[cluster] + treatment * mde + np.random.normal(0, np.sqrt(residual_variance))
            data.append([cluster, household, treatment, y])
    
    df = pd.DataFrame(data, columns=["cluster", "household", "treatment", "y"])
    return df

# Function to fit MixedLM with error handling
def fit_mixedlm(df):
    model = MixedLM.from_formula("y ~ treatment", groups="cluster", data=df)
    try:
        result = model.fit(method='lbfgs', maxiter=1000)
        return result
    except Exception as e:
        print(f"Model fitting failed: {e}")
        return None

# Function to simulate power
def simulate_power(clusters, sample_size, icc, mde, r_squared, reps, alpha):
    households_per_cluster = sample_size // clusters
    power_results = []
    
    for _ in range(reps):
        df = generate_clustered_data(clusters, households_per_cluster, icc, mde, r_squared)
        result = fit_mixedlm(df)
        
        if result is not None and "treatment" in result.params:
            p_value = result.pvalues["treatment"]
            power_results.append(p_value < alpha)
        else:
            power_results.append(False)
    
    return np.mean(power_results)

# Simulate power for all cluster configurations
results = []
for typology, proportion in fragility_proportions.items():
    typology_sample_size = int(final_sample_size * proportion)
    max_clusters = max_clusters_per_typology[typology]
    
    for clusters in range(5, max_clusters + 1, 5):
        power = simulate_power(clusters, typology_sample_size, icc, mde, r_squared, reps, alpha)
        households_per_cluster = typology_sample_size // clusters
        results.append({
            "Typology": typology,
            "Clusters": clusters,
            "Households_Per_Cluster": households_per_cluster,
            "Power": power
        })

# Convert results to DataFrame for easier analysis
results_df = pd.DataFrame(results)
print(results_df)

# Plotting the results
plt.figure(figsize=(12, 8))
sns.lineplot(data=results_df, x="Clusters", y="Power", hue="Typology", marker="o")

# Add a horizontal line for the target power
plt.axhline(y=target_power, color='r', linestyle='--', label=f'Target Power ({target_power})')

# Customize the plot
plt.title('Statistical Power by Number of Clusters and Typology')
plt.xlabel('Number of Clusters')
plt.ylabel('Statistical Power')
plt.legend(title='Typology')
plt.grid(True)
plt.tight_layout()

# Show the plot
plt.show