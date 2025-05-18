###############################################################################
#  FULL EXPLORER  ── scan ICC × MDE for a fixed sample design
###############################################################################
library(dplyr); library(ggplot2); library(tidyr)
library(lme4);  library(pbapply); library(future.apply)
plan(multisession, workers = parallel::detectCores()-1)
pboptions(type = "txt")

n_sample <- 1800

## ---------- Get the distribution  ----------------------------------------
library(readxl)
var <- read_excel("data/derived/variables_A3.xls")
var <- var |> group_by(cat_2) |> summarise(n_p=sum(poblacion,na.rm=TRUE)) |>
             mutate(n_p = n_p/sum(n_p),n=round(n_p*n_sample))

print(var)

## ---------- PARAMETERS  ----------------------------------------
## ---- (OPTIONAL) bigger small strata  --------------------------------------
targets <- c(
  high_conflict     = var$n[var$cat_2=="high - high"],
  low_conflict      = var$n[var$cat_2=="low - high"],
  high_non_conflict = max(400, var$n[var$cat_2=="high - low"]), # was ≈250
  low_non_conflict  = max(400, var$n[var$cat_2=="low - low"])   # was ≈220
)


p1_vec   <- rep(0.40, length(targets))
m_grid   <- 5:10                     #  Number of households per cluster
icc_grid <- c(0.04, 0.06)      # test three ICC values
mde_grid <- c(0.08, 0.10, 0.12)      # test three effect sizes
nrep     <- 800                      # Monte-Carlo reps
alpha    <- 0.05
analysis <- "tmean"                   # "glmm" or "tmean"
## ---------------------------------------------------------------------------

## ---------- simulator ------------------------------------------------------
sim_one <- function(k, m, icc, p1, mde) {
  arm <- sample(rep(0:1, c(floor(k/2), ceiling(k/2))))
  sd_b <- sqrt(icc * (pi^2/3)/(1-icc))
  b    <- rnorm(k, 0, sd_b)
  p0   <- plogis(qlogis(p1) + b)
  p1t  <- plogis(qlogis(p1+mde) + b)
  prob <- ifelse(arm==0, p0, p1t)
  data.frame(cluster = rep(seq_len(k), each=m),
             treat   = rep(arm, each=m),
             outcome = rbinom(k*m, 1, rep(prob, each=m)))
}

## ---------- analysis functions --------------------------------------------
test_glmm <- function(dat){
  fit <- glmer(outcome ~ treat + (1|cluster), data=dat,
               family=binomial,
               control=glmerControl(optimizer="bobyqa", calc.derivs=FALSE))
  as.numeric(summary(fit)$coef["treat","Pr(>|z|)"] < alpha)
}
test_tmean <- function(dat){
  clu <- dat |> group_by(cluster,treat) |> summarise(p=mean(outcome),.groups="drop")
  if(length(unique(clu$treat))<2) return(NA_real_)
  as.numeric(t.test(p~factor(treat),data=clu)$p.value < alpha)
}
tester <- if(analysis=="glmm") test_glmm else test_tmean

power_km <- function(k,m,icc,p1,mde){
  hits <- future_replicate(nrep,{
    dat <- sim_one(k,m,icc,p1,mde)
    tryCatch(tester(dat), error=function(e) NA_real_)
  },future.seed=TRUE)
  mean(hits,na.rm=TRUE)
}

## ---------- grid search ----------------------------------------------------
results <- lapply(names(targets), \(s){
  N <- targets[s]; p1 <- p1_vec[1]
  expand.grid(m=m_grid, icc=icc_grid, mde=mde_grid) |>
    mutate(k        = ceiling(N / m),
           n_design = k*m,
           power    = pblapply(seq_len(n()), \(i)
                                power_km(k[i],m[i],icc[i],p1,mde[i]))) |>
    unnest(power) |> mutate(Stratum=s)
}) |> bind_rows()

## ---------- pretty print ---------------------------------------------------
options(pillar.sigfig = 4)
print(filter(results, m %in% c(7,9,12)) |> head(20))

## ---------- designs that hit ≥ 0.80 ---------------------------------------
good <- results |> filter(power>=0.80) |>
        group_by(Stratum) |> slice_min(n_design, n=1, with_ties=FALSE)
print(good)

## ---------- heat-map of power ---------------------------------------------
ggplot(results, aes(factor(m), factor(mde),
                    fill = pmin(power,1))) +
  geom_tile() +
  facet_grid(Stratum ~ icc, labeller = label_both) +
  scale_fill_viridis_c(name="Power", limits=c(0,1)) +
  labs(title=paste("Power heat-map (analysis:",analysis,", nrep=",nrep,")"),
       x="Households per cluster (m)", y="MDE") +
  theme_minimal(base_size=11)

ggsave(paste0("img/power_heat_",analysis,".png"),
       width=9, height=6, dpi=300)
