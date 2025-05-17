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

---

## Incorporation of Fragility and Gender Strata

To ensure the sample design reflects the complexity of the population, the stratification incorporates two critical dimensions—**gender** and **fragility**.  
The prevalence of each typology in the population was used to determine stratum proportions, guaranteeing sufficient representation to detect meaningful differences across groups.

### 1  Gender Stratum  
Within each fragility typology, the sample is further stratified by household gender type, distinguishing between **female-headed** and **male-headed** (80 %) households.  
Sample sizes are adjusted so that gender-specific subgroups are adequately represented.

### 2  Fragility-Typology Stratum  
The primary stratum defines **four fragility categories** based on **climate risk** and **conflict** levels.

#### Conflict exposure  
*Indicators:* number of battles, protests, riots, acts of violence against civilians, and fatalities from these events.  
A Principal Component Analysis (PCA) is run on these variables, using the median score as the cut-off: departments scoring **above** the median are classified as **high-risk** for violence, while those **below** the median are **low-risk** (see Appendix 1 for details).

#### Climate-risk exposure  
*Indicators:* water stress in crops and livestock, probability of droughts affecting crops, and probability of droughts affecting livestock.  
A PCA is conducted using the same median-based classification: departments **above** the median are **high-risk** for climate change, and those **below** are **low-risk** (see Appendix 1).

Based on the two PCAs, we define **four typologies**:

* **Higher Climate Risk & Conflict-Affected**  
  Departments with climate-risk values above the median **and** high exposure to conflict.

* **Higher Climate Risk & Non-Conflict-Affected**  
  Departments highly exposed and vulnerable to climate change **but not** affected by conflict.

* **Lower Climate Risk & Conflict-Affected**  
  Departments less exposed and vulnerable to climate change **but** highly affected by conflict.

* **Lower Climate Risk & Non-Conflict-Affected**  
  Departments less exposed and vulnerable to climate change **and** not affected by conflict.

---

## Sampling design -- Results

### Sample size 

To ensure a robust and representative sampling design, baseline values were derived from existing evidence on key outcomes in Northern Central America. These values serve as essential parameters for estimating sample sizes that reflect the region’s complex socio-economic and environmental dynamics. By guiding the Minimum Detectable Effects (MDEs) calculation for each outcome, these baseline values ensure that the sample size is adequate to detect meaningful differences across critical strata, such as fragility typologies, and gender. This evidence-based approach strengthens the reliability and validity of the sampling design, ensuring it is closely aligned with the realities and diversity of the target. The table below summarizes the key baseline values for the sampling process.


Given numerous unobservable factors, the sampling design integrates existing evidence on the explanatory power of key covariates for the selected outcome variables. To achieve this, relevant literature and studies were reviewed to identify the contributions of household-level and geographical covariates to the outcomes of interest. These covariates typically include household head characteristics, such as age, gender, education, employment status, and regional and community-level fixed effects. Incorporating these controls enhances the sampling design by addressing potential confounding variables, thereby ensuring that the model's explanatory power is robust and reflective of the diverse contexts within Northern Central America. The table below provides a summary of these considerations.

### Table 1. Baseline Values and Data Sources for Sampling Design

| **Type** | **Variable / Dimension** | **Notes / Source** | **Value<br>(× 100 %)** |
|----------|-------------------------|--------------------|------------------------|
| **Outcome** | Proportion of households reporting migration intention *(binary)* | Several studies examine the desire to migrate; the most recent regional report excludes Nicaragua. — *International Organization for Migration (IOM), 2022* | **0.35** |
| **Outcome** | Proportion of households reporting food insecurity *(binary)* | Literature reports different prevalence rates.<br>Reference values used in this estimation:<br>&nbsp;&nbsp;• Guatemala – 41 % (Deza & Ruiz-Arranz, 2022)<br>&nbsp;&nbsp;• Honduras – 39 % (Deza & Ruiz-Arranz, 2022)<br>&nbsp;&nbsp;• El Salvador – 52 % (Deza & Ruiz-Arranz, 2022)<br>&nbsp;&nbsp;• Dry Corridor (GT, HN, SV) – 43 % (WFP, 2017) | **0.41** *(average)* |
| **Outcome** | Average dietary-diversity score *(continuous)* | No systematic regional study. Evidence links food insecurity with low dietary diversity.<br>Reference: mean score = **5.6** in eight Latin-American countries (Argentina, Brazil, Chile, Colombia, Costa Rica, Ecuador, Peru, Venezuela) — *Gómez et al., 2019* | **5.0** *(average)* |
| **Stratum** | Proportion of female-headed households | Estimates suggest **30 – 40 %** of households in Central America are female-headed. | **0.35** |
| **Stratum** | Proportion of households living in fragile **Type I** areas – high climate risk **and** high conflict-affected levels | — | **0.38** |
| **Stratum** | Proportion of households living in fragile **Type II** areas – high climate risk and **high** conflict-affected levels | Own calculation based on **LandScan Global Population Database (2024)** | **0.11** |
| **Stratum** | Proportion of households living in fragile **Type III** areas – low climate risk **and** high conflict-affected levels | — | **0.40** |
| **Stratum** | Proportion of households living in fragile **Type IV** areas – low climate risk **and** low conflict-affected levels | — | **0.11** |

Once the sampling size is defined, the following decision is the composition of the number of villages and households. The optimal number of villages in the sampling design is determined by balancing statistical power and logistical feasibility. To achieve this, the design minimizes the design effect—a factor that reduces the effective sample size due to intra-cluster correlation (ICC). The trade-off lies between the number of clusters and the number of households per cluster: fewer clusters with more households increase ICC effects, reducing statistical efficiency, while more clusters with fewer households mitigate these effects but increase logistical complexity and costs. The optimal cluster size is reached when the effective sample size is maximized, and the benefits of adding more clusters begin to show diminishing returns. Practical considerations, such as field costs, accessibility of villages, and survey feasibility, further refine this balance. Simulations based on the study's parameters help identify this optimal point, ensuring robust statistical inference and operational efficiency. In most studies with moderate ICC (e.g., 0.05–0.15), the number of households per cluster typically ranges between 10 and 20, with the total number of clusters adjusted based on the overall sample size and stratification requirements.

### Sampling strategy