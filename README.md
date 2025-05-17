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
- [Incorporation of Fragility and Gender Strata](#incorporation-of-fragility-and-gender-strata)
  - [Gender Stratum](#gender-stratum)
  - [Fragility-Typology Stratum](#fragility-typology-stratum)
    - [Conflict exposure](#conflict-exposure)
    - [Climate-risk exposure](#climate-risk-exposure)
    - [Defined Typologies](#defined-typologies)
- [Sampling design -- Results](#sampling-design--results)
  - [Baseline values](#baseline-values)
  - [Table 1. Baseline Values and Data Sources for Sampling Design](#table-1-baseline-values-and-data-sources-for-sampling-design)
  - [Table 2. Explanatory Power of Covariates](#table-2-explanatory-power-of-covariates)
  - [Power calculation](#power-calculation)

# Sampling Strategy & Power Calculations  

This study uses a **multi-stage, probability-proportional-to-size design** to examine the nexus between *food and nutritional security, migration,* and *fragility* in Northern Central America (Guatemala, Honduras, El Salvador, and Nicaragua).  
The design guarantees:

* representative coverage of all four countries,  
* explicit power for the most vulnerable sub-groups (e.g. **female-headed households**),  
* explicit allowance for cluster effects and covariate adjustment.

---

## 1 From _n_ → MDE  (vs. the usual MDE → _n_)

Most field budgets fix the **total number of households that can be interviewed**.  
Instead of asking *“how many households do we need to detect an effect of X?”* we reverse the logic:

> **Given a feasible total sample size \(N\),  
> what is the *smallest effect* \(\bigl(\text{MDE}\bigr)\) we can still pick up with 80 % power?**

This is implemented in the accompanying R script (`/code/R/power_reverse.R`) and works as follows.

| Step | Action |
|------|--------|
| 1 | **Undo inflation factors** – remove the 10 % oversampling reserve and the \(\bigl(1-R^{2}\bigr)^{-1}\) covariate adjustment so that `pwr` receives the *effective* per-group size. |
| 2 | **Binary outcomes** – use `pwr.2p.test()` with a root-finding routine (`uniroot`) to obtain the Cohen’s *h* that achieves the target power, then convert *h* back to \(\text{MDE}=p_{2}-p_{1}\). |
| 3 | **Continuous outcome** – same idea with `pwr.t.test()` and Cohen’s *d*, returning the MDE on the original scale (dietary-diversity points). |
| 4 | **Grid search** – repeat the calculation for a grid of candidate sample sizes (800 – 5,000 HH in 200-HH steps by default). |

The resulting look-up table (and the figure `WB_MDE_vs_N.png`) lets the team see, at a glance, what size effects are detectable for any budget-constrained \(N\).

---

## 2 Key Formulas  

### 2.1 Binary outcomes  
The classical sample-size equation (shown for reference) is

\[
n 
= \bigl(Z_{\alpha/2} + Z_{\beta}\bigr)^{2}\;
  \frac{p_{1}(1-p_{1}) + p_{2}(1-p_{2})}{(p_{2}-p_{1})^{2}}
  \times \frac{1}{1-R^{2}} .
\]

When we **fix \(n\)** we instead solve for the minimum \(\Delta = p_{2}-p_{1}\).  
This is done via the arc-sine transformation

\[
h = 2\bigl[\arcsin(\sqrt{p_{2}})-\arcsin(\sqrt{p_{1}})\bigr],
\qquad
p_{2}= \Bigl(\sin\bigl(\arcsin(\sqrt{p_{1}})+h/2\bigr)\Bigr)^{2},
\]

and the power function of `pwr.2p.test()`.

### 2.2 Continuous outcome (dietary-diversity score)

\[
n 
= \frac{2\bigl(Z_{\alpha/2}+Z_{\beta}\bigr)^{2}\sigma^{2}}
         {\text{MDE}^{2}}
  \times \frac{1}{1-R^{2}}
\quad\longrightarrow\quad
\text{solve for MDE} = d_{\star}\sigma .
\]

`pwr.t.test()` is used to locate the (two-sided) Cohen’s *d* that reaches 80 % power.

---

## 3 Clustering & Design Effect  

Sampling is clustered in **villages** (Primary Sampling Units, PSUs) with households as the Ultimate Sampling Units (USUs).  
The **design effect** for equal-sized clusters is

\[
\text{DEFF}_{\text{cluster}}
= 1 + (m-1)\rho ,
\]

where \(m\) is the average HH per village and \(\rho\) the intra-cluster correlation coefficient.  
For highly variable cluster sizes we use

\[
\text{DEFF} = 1 + (\bar m -1)\rho \bigl(1+\text{CV}_{m}^{2}\bigr).
\]

The total sample size fed into the power routine can therefore be expressed as

\[
N_{\text{total}}
= \tfrac{2n_{\text{pwr}}}{1-R^{2}}\;(1+\text{oversample})\;\text{DEFF}_{\text{cluster}},
\]

so analysts can transparently see how each design choice (covariates, oversampling, clustering) inflates or deflates the power budget.

---

## 4 Default Parameters  

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Significance level \(\alpha\) | 0.05 (two-sided) | 95 % confidence |
| Statistical power \(1-\beta\) | 0.80 | Conventional social-science benchmark |
| Oversampling reserve | 10 % | Non-response & data-loss buffer |
| \(R^{2}\) (covariates) | 0.30 (migration), 0.20 (food insecurity), 0.30 (dietary diversity) | Literature-based pseudo-\(R^{2}\) (see Table 2) |
| Baseline prevalences | 0.35 (migration), 0.40 (food insecurity) | Regional household surveys |
| SD (dietary-diversity) | 5 points | DHS & FAO data |
| ICC \(\rho\) | 0.05–0.10 (scenario range) | Typical for socio-economic HH indicators |

---

## 5 Replicating the Results  

```bash
# Clone the repo
git clone https://github.com/your-org/fragility-migration-sampling.git
cd fragility-migration-sampling

# Install R packages (if needed)
R -e "install.packages(c('pwr','ggplot2','dplyr'))"

# Run the script
Rscript code/R/power_reverse.R
