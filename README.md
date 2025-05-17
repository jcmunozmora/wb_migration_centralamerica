# The complex links between food security, migration, and fragility and violence in Northern Central America 

This the code repository for the project "The complex links between food security, migration, and fragility and violence in Northern Central America". The World Bank, with support from the State and Peacebuilding Fund (SPF), is undertaking an analytical study to explore the intricate links between food security, migration, and fragility in NCA. This study aims to generate robust data and insights for regional and country-specific strategies. 

analytical pipelines.

```text
repo/
├── code/
│   └── R/
│       ├── power_reverse.R     # fixed‑budget → MDE calculations
│       ├──  …                 # helper scripts (cleaning, plots, etc.)
├── data/
│   ├── inputs/                # baseline rates, ICC priors, covariate R²
│   └── derived/               # simulation outputs
├── img/                       # auto‑generated figures
└── README.md                  # you are here
```

---

## Table of Contents

- [Sampling Design - Theory](#sampling-design---theory)
  - [Fixed‑Sample‑Size → Minimum Detectable Effect](#fixed-sample-size--minimum-detectable-effect)
  - [Binary outcome](#binary-outcome)
  - [Continuous outcome (dietary‑diversity score)](#continuous-outcome-dietary-diversity-score)
  - [Clustering and design effect](#clustering-and-design-effect)
    - [Design Effect (DEFF)](#design-effect-deff)
    - [Accounting for survey weights](#accounting-for-survey-weights)
- [Incorporation of Fragility and Gender Strata](#incorporation-of-fragility-and-gender-strata)
  - [Gender Stratum](#gender-stratum)
  - [Fragility‑Typology Stratum](#fragility-typology-stratum)
    - [Conflict exposure](#conflict-exposure)
    - [Climate‑risk exposure](#climate-risk-exposure)
    - [Defined Typologies](#defined-typologies)
- [Sampling design -- Results](#sampling-design--results)
  - [Baseline values](#baseline-values)
  - [Table 1. Baseline Values and Data Sources for Sampling Design](#table-1-baseline-values-and-data-sources-for-sampling-design)
  - [Table 2. Explanatory Power of Covariates](#table-2-explanatory-power-of-covariates)
  - [Power calculation](#power-calculation)

---

## Sampling Strategy - Theory

The survey follows a **multi‑stage, probability‑proportional‑to‑size (PPS) design** with *villages* as primary sampling units (PSUs) and *households* as ultimate sampling units (USUs). Stratification combines four **fragility typologies** (defined by conflict and climate‑risk scores) with **household‑head gender**, guaranteeing both geographical coverage and statistical power for key sub‑groups such as female‑headed households.

## Fixed‑Sample‑Size → Minimum Detectable Effect

Operational constraints often limit the total number of households that can be interviewed. Rather than fixing a minimum detectable effect (MDE) first, we invert the problem:

> **Given a feasible total sample size $N_{\text{total}}$, what is the *smallest effect* (MDE) that can be detected with 80 % power at $\alpha = 0.05$ once oversampling, covariate adjustment, and clustering are taken into account?**

The script **`code/R/power_reverse.R`** automates this conversion:

1. **Remove inflation factors**

   $$
   n_{\text{eff}} = \frac{N_{\text{total}}}{\bigl(1+\text{oversample}\bigr)\,\text{DEFF}_{\text{cluster}}} \times (1-R^{2}),
   $$

   producing the *effective* per‑group size expected by the `pwr` package.

2. **Solve for the effect size.**

   - Binary outcomes – root‑find on Cohen’s *h* with `pwr.2p.test()`, then convert back to an absolute risk difference.
   - Continuous outcome – root‑find on Cohen’s *d* with `pwr.t.test()`, then multiply by the outcome’s standard deviation.

3. **Return an MDE grid** for a range of candidate $N_{\text{total}}$ values (default: 800 – 5 000 households).

The figure `img/WB_MDE_vs_N.png` visualises how detectable effects shrink as the total sample size grows.

### `01_Sampling_Design.R` – what the script does

`01_Sampling_Design.R` takes a *grid of candidate total sample sizes*, applies the oversampling, clustering, and covariate‑adjustment factors in reverse, and then solves the power equations to obtain the **minimum detectable effect (MDE)** for each outcome.

* **Outputs**
  * `img/WB_MDE_vs_N.png` – a visual map of how the MDE declines as the total sample size increases.
  * `data/derived/mde_grid.csv` – a tidy table listing `Outcome`, `N_total`, and the corresponding `MDE`.

These artefacts guide the final choice of total households and cluster configuration without prescribing any particular effect size ex‑ante. The sample-size calculation is based on the following equation for the two **food-insecurity** and **migration** outcomes (binary outcomes).

### Binary outcome

$$
n = \bigl(Z_{\alpha/2}+Z_{\beta}\bigr)^2
    \frac{p_{1}(1-p_{1}) + p_{2}(1-p_{2})}{(p_{2}-p_{1})^{2}}
    \times \frac{1}{1-R^{2}}.
$$

* **n** – required sample size per study arm  
* $Z_{\alpha/2}=1.96$ (95 % confidence)  
* $Z_{\beta}=0.84$ (80 % power)  
* $p_{2}=p_{1}+\text{MDE}$  
* $R^{2}$ – share of outcome variance explained by covariates

### Continuous outcome (dietary‑diversity score)

$$
n = \frac{2\bigl(Z_{\alpha/2}+Z_{\beta}\bigr)^{2}\,\sigma^{2}}{\text{MDE}^{2}}
    \times \frac{1}{1-R^{2}},
$$

with residual variance $\sigma^{2}_{z}=\sigma^{2}(1-R^{2})$.

### Clustering and design effect

Because households are sampled in villages, statistical efficiency depends on the **intra‑cluster correlation** (ICC). The number of households per village cluster must be set to minimise ICC effects, balancing the número of clusters versus households per cluster.

A key concept in this process is the **Design Effect (DEFF)**, measuring the loss of efficiency due to clustering.

#### Design Effect (DEFF)

For a single‑stage cluster sample with roughly equal cluster sizes, the design effect is:

$$
\text{DEFF}_{\text{cluster}} = 1 + (m-1)\,\rho,
$$

or

$$
\text{DEFF}_{\text{cluster}} = 1 + (\bar m-1)\,\rho(1+\text{CV}_{m}^{2})
$$

for unequal clusters.

* $m$ – average households per cluster  
* $\rho$ – ICC

##### Accounting for survey weights

If sampling weights are applied, the overall design effect is:

$$
\text{DEFF}_{\text{total}} = \text{DEFF}_{\text{cluster}}\bigl(1+\text{CV}_{w}^{2}\bigr),
$$

where $\text{CV}_{w}$ is the coefficient of variation of the final weights.

---

## Incorporation of Fragility and Gender Strata

To ensure the sample design reflects the complexity of the population, the stratification incorporates two key dimensions—**gender** and **fragility**.  
The prevalence of each typology in the population was used to determine stratum proportions, guaranteeing sufficient representation to detect meaningful differences across groups.

### 1. Gender Stratum  
Within each fragility typology, the sample is further stratified by household gender type, distinguishing between **female-headed** and **male-headed** households. Sample sizes are adjusted so that gender‑specific subgroups are adequately represented.

### 2. Fragility‑Typology Stratum  
The primary stratum defines **four fragility categories** based on **climate risk** and **conflict** levels.

#### Conflict exposure  
*Indicators:* number of battles, protests, riots, acts of violence against civilians, and fatalities. A PCA is run on these variables, using the median as a cut-off. Departments above the median are classified as **high‑risk**; below, as **low‑risk**.

#### Climate‑risk exposure  
*Indicators:* water stress, probability of droughts affecting crops and livestock. Similar median‑based PCA classifies departments as **high‑risk** or **low‑risk**.

Based on both PCAs, four typologies are defined:

* **Higher Climate Risk & Conflict‑Affected**  
* **Higher Climate Risk & Non‑Conflict‑Affected**  
* **Lower Climate Risk & Conflict‑Affected**  
* **Lower Climate Risk & Non‑Conflict‑Affected**

---

## Sampling design -- Results

### Baseline values

[Descripción de los valores base utilizadas en el diseño...]

### Table 1. Baseline Values and Data Sources for Sampling Design

| **Type** | **Variable / Dimension** | **Notes / Source** | **Value (× 100 %)** |
|----------|--------------------------|--------------------|---------------------|
| **Outcome** | Proportion of households reporting migration intention *(binary)* | ... | **0.35** |
| ...      | ...                      | ...                | ...                 |

### Table 2. Explanatory Power of Covariates (Assumptions for Dependent Variables)

| **Dependent variable** | **Common covariates** | **Notes / Source** | **\(R^{2}\)** |
|------------------------|-----------------------|--------------------|---------------|
| ...                    | ...                   | ...                | **0.30**      |
| ...                    | ...                   | ...                | **0.20**      |
| ...                    | ...                   | ...                | **0.30**      |

### Power calculation

[Detalles sobre la simulación y los resultados de poder...]

| **Parameter** | **Specification** |
|---------------|-------------------|
| **Outcome variables** | 1. **Food security** (binary)<br>2. **Migration intention** (binary)<br>3. **Dietary‑diversity score** (continuous) |
| **Significance level** (\(\alpha\)) | **0.05** (95 % confidence) |
| **Statistical power** (1 – \(\beta\)) | **80 %** |
| **Oversampling rate** | **10 %** |
| **Cluster (primary sampling unit)** | **Villages** |
| **Ultimate sampling units** | **Households** |

The simulation results were visualized to show how sample size changes with MDE values for each outcome.