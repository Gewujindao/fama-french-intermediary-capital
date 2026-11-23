library(tidyverse)
library(stringr)
library(sandwich)

# Run from the project root (Rscript 02_two_pass_regression.R).
# Data are read from data/; console output and figures go to results/.
dir.create("results", showWarnings = FALSE)
sink("results/02_two_pass_regression_output.txt", split = TRUE)
pdf("results/02_icrf_vs_ff5_scatter.pdf")
hkm <- readxl::read_xlsx("data/He_Kelly_Manela_Factors_monthly.xlsx")
test25 <- readxl::read_xlsx("data/25_Portfolios_5x5.xlsx")
ff5 <- readxl::read_xlsx("data/F-F_Research_Data_5_Factors_2x3.xlsx")



ff5 <- ff5[1:700, ]

test25 <- test25[1:1150, ]


hkm <- hkm[which(hkm$date>= 197001 & hkm$date<= 201811), ]
test25 <- test25[which(test25$date >= 197001 & test25$date <= 201811), ]
ff5 <- ff5[which(ff5$date >= 197001 & ff5$date <= 201811), ]
ff5$RF=as.numeric(ff5$RF)
beta <- data.frame(beta_hkm = rep(NA, 25), beta_m = rep(NA, 25),beta_s=rep(NA, 25),beta_h=rep(NA, 25),beta_r=rep(NA, 25),beta_c=rep(NA, 25), Er = rep(NA, 25))
firststage <- list()
ff5$`Mkt-RF`=as.numeric(ff5$`Mkt-RF`)
ff5$SMB=as.numeric(ff5$SMB)
ff5$HML=as.numeric(ff5$HML)
ff5$RMW=as.numeric(ff5$RMW)
ff5$CMA=as.numeric(ff5$CMA)
for (i in 1:25) {
  model <- lm(test25[, 1+i][[1]]-lag(ff5$RF) ~ ff5$`Mkt-RF`+ hkm$intermediary_capital_risk_factor + ff5$SMB + ff5$HML + ff5$RMW + ff5$CMA)
  firststage[[i]] <- model
  beta$beta_m[i] <- model$coefficients[2]
  beta$beta_hkm[i] <- model$coefficients[3]
  beta$beta_s[i] <- model$coefficients[4]  
  beta$beta_h[i] <- model$coefficients[5]   
  beta$beta_r[i] <- model$coefficients[6]
  beta$beta_c[i] <- model$coefficients[7]
  beta$Er[i] <- mean(test25[, 1+i][[1]] - lag(ff5$RF), na.rm = T)
}
model <- lm(Er ~ beta_hkm + beta_m + beta_s + beta_h + beta_r + beta_c, data = beta)
summary(model)


for (i in 1:25) {
  model <- lm(test25[, 1+i][[1]]-lag(ff5$RF) ~ ff5$`Mkt-RF` + ff5$SMB + ff5$HML + ff5$RMW + ff5$CMA)
  firststage[[i]] <- model
  beta$beta_m[i] <- model$coefficients[2]
  #beta$beta_hkm[i] <- model$coefficients[3]
  beta$beta_s[i] <- model$coefficients[3]  
  beta$beta_h[i] <- model$coefficients[4]   
  beta$beta_r[i] <- model$coefficients[5]
  beta$beta_c[i] <- model$coefficients[6]
  beta$Er[i] <- mean(test25[, 1+i][[1]] - lag(ff5$RF), na.rm = T)
}
model <- lm(Er ~  beta_m + beta_s + beta_h + beta_r + beta_c, data = beta)
summary(model)

plot(hkm$intermediary_capital_risk_factor,ff5$`Mkt-RF`) # seems to be correlated
plot(hkm$intermediary_capital_risk_factor,ff5$RMW)  # seems to be correlated
plot(hkm$intermediary_capital_risk_factor,ff5$SMB)
plot(hkm$intermediary_capital_risk_factor,ff5$HML)
plot(hkm$intermediary_capital_risk_factor,ff5$CMA)



# Load packages
library(ggplot2)
library(tidyr)
library(dplyr)

# Build one data frame from the two data sets
df <- data.frame(
  intermediary_capital_risk_factor = hkm$intermediary_capital_risk_factor,
  Mkt_RF = ff5$`Mkt-RF`,
  RMW = ff5$RMW,
  SMB = ff5$SMB,
  HML = ff5$HML,
  CMA = ff5$CMA
)

# Reshape to long format
df_long <- pivot_longer(
  df,
  cols = c(Mkt_RF, RMW, SMB, HML, CMA),
  names_to = "Factor",
  values_to = "Value"
)

# Scatter plots with ggplot, one panel per factor
p=ggplot(df_long, aes(x = intermediary_capital_risk_factor, y = Value)) +
  geom_point(alpha = 0.6) +
  facet_wrap(~ Factor, scales = "free_y") +
  labs(
    x = "Intermediary Capital Risk Factor",
    y = "Value"#,
    #title = "Relationships between Intermediary Capital Risk Factor and Fama-French 5 Factors"
  ) +
  theme_minimal()
ggsave("results/inter_vs_ff5.png", plot = p, width = 10, height = 5)
dev.off()
sink()
