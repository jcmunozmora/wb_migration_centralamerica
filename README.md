# The complex links between food security, migration, and fragility and violence in Northern Central America 

This the code repository for the project "The complex links between food security, migration, and fragility and violence in Northern Central America". The World Bank, with support from the State and Peacebuilding Fund (SPF), is undertaking an analytical study to explore the intricate links between food security, migration, and fragility in NCA. This study aims to generate robust data and insights for regional and country-specific strategies. 

In this repository there is all the replication codes for the sampling design as well as the analitical analysis.

## Table of Contents

- [Sampling Design - Theory](#sampling-design---theory)
  - [Binary outcome](#binary-outcome)
  - [Continuous outcome (dietary-diversity score)](#continuous-outcome-dietary-diversity-score)
  - [Clustering and design effect](#clustering-and-design-effect)
    - [Design Effect (DEFF)](#design-effect-deff)
    - [Accounting for survey weights](#accounting-for-survey-weights)
- [Sampling Design - Results](#sampling-design---results)

## Sampling Design - Theory

The study uses a robust, multi-stage random sampling approach to examine the relationship between food and nutritional security, migration, and fragility in Northern Central America, specifically in Honduras, Nicaragua, El Salvador, and Guatemala. This design ensures representativeness, accounts for variability across communities, and addresses the specific vulnerabilities of key population subgroups, such as  female-headed households. 

The sampling design employs a robust approach to ensure that the selected sample is representative of the population and sufficient to detect key effects across strata. Minimum Detectable Effect (MDE) thresholds were used to calculate the required sample sizes for key outcomes, such as food insecurity, migration intention, and dietary diversity. The MDE represents the smallest effect size the sample is statistically powered to detect, ensuring meaningful differences can be identified across subgroups.

The sample-size calculation is based on the following equation for the two **food-insecurity** and **migration** outcomes (binary outcomes).

### Binary outcome

$$
n = \left(\tfrac{Z_{\alpha}}{2} + Z_{\beta}\right)^{2} 
      \frac{ \,p_{1}(1 - p_{1}) + p_{2}(1 - p_{2}) }{ (p_{2} - p_{1})^{2} } 
      \times \frac{1}{1 - R^{2}}
$$

where

* **n** – required sample size  
* $Z_{\alpha/2}$ – *z*-score for the desired confidence level. In our case we assume 1.96 for 95 % confidence.  
* $Z_{\beta}$ – *z*-score for the desired power. We assume 0.84 for 80 % power.*  
* $p_{1}, p_{2}$ – proportions for the baseline and expected outcomes, respectively  
* **MDE** – minimum detectable effect, where \(p_{2} = p_{1} + \text{MDE}\)  
* $R^{2}$ – proportion of the outcome variance explained by covariates  

### Continuous outcome (dietary-diversity score)

For the dietary-diversity outcome (a continuous variable), the sample size is defined as follows:

$$
n =
\frac{2\left(\tfrac{Z_{\alpha}}{2} + Z_{\beta}\right)^{2}\sigma^{2}}{\text{MDE}^{2}}
\times \frac{1}{1 - R^{2}}
$$

where

* $\sigma^{2}$ – adjusted variance,  
  $\sigma^{2}_{\!z} = \sigma^{2}\bigl(1 - R^{2}\bigr)$

### Clustering and design effect

To determine the number of households per village cluster we must minimise **intra-cluster correlation** effects. This involves striking a balance between the number of clusters and the number of households within each cluster.

A key concept in this process is the **Design Effect (DEFF)**, which measures the loss of statistical efficiency resulting from clustering.

### Design Effect (DEFF)

The **design effect** compares the variance of an estimator under the actual (cluster) design with the variance that would have been obtained from a simple random sample (SRS) of the same total size.  
For a single-stage cluster sample with roughly equal cluster sizes, the design effect that captures the loss of efficiency caused by clustering is:

$$
\text{DEFF}_{\text{cluster}}
= 1 + (m - 1)*\rho
$$

where  

* **m** – average number of sampled units (e.g., households) per cluster  
* $\rho$ – intra-cluster correlation coefficient (ICC), i.e., the proportion of total outcome variance attributable to between-cluster variation  


#### Accounting for survey weights

If sampling weights are applied, the overall design effect is the product of the clustering and weighting components:

$$
\text{DEFF}_{\text{total}} = \text{DEFF}_{\text{cluster}} \times \bigl(1 + \mathrm{CV}_{w}^{2}\bigr)
$$

where $\mathrm{CV}_{w}$ is the coefficient of variation of the final survey weights.

## Sampling Design - Results

