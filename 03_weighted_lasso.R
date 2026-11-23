library(magrittr)
library(glmnet)
library(ppcor)
library(plotmo)
beta2 = data.frame(
  beta.hkm = rep(NA,25),
  beta.m = rep(NA,25),
  beta.smb=rep(NA,25),
  beta.hml=rep(NA,25),
  beta.rmw=rep(NA,25),
  beta.cma=rep(NA,25),
  Ere = rep(NA,25)
)


# Run from the project root (Rscript 03_weighted_lasso.R).
# Data are read from data/; console output and figures go to results/.
dir.create("results", showWarnings = FALSE)
sink("results/03_weighted_lasso_output.txt", split = TRUE)
pdf("results/03_lasso_path.pdf")
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
firststage=list()
hkm2=hkm
hkm2$intermediary_capital_risk_factor=hkm2$intermediary_capital_risk_factor


for(i in 1:25){
  model = lm(test25[,1+i][[1]]-lag(ff5$RF)~
               hkm2$intermediary_capital_risk_factor+
               ff5$`Mkt-RF`+
               ff5$SMB+
               ff5$HML+
               ff5$RMW+
               ff5$CMA)
  firststage[[i]]=model
  beta2$beta.hkm[i] = model$coefficients[2]
  beta2$beta.m[i] = model$coefficients[3]
  beta2$beta.smb[i] = model$coefficients[4]
  beta2$beta.hml[i] = model$coefficients[5]
  beta2$beta.rmw[i] = model$coefficients[6]
  beta2$beta.cma[i] = model$coefficients[7]
  beta2$Ere[i] = mean(test25[,1+i][[1]]-lag(ff5$RF),na.rm = T)
}

residuals_length = length(firststage[[i]]$residuals)

Sigma = matrix(0, nrow = 587, ncol = 25)
for(i in 1:25){
  Sigma[,i]=firststage[[i]]$residuals
}
Sigma=cov(Sigma)
d=1.5
lambda= sqrt(sum(diag(Sigma)) / 25)* (nrow(hkm)-1)^(-d / 2) #\eta_T

# 
z <- function(rho) 0.5 * log((1 + rho) / (1 - rho))
factorpool = cbind(hkm[,3],ff5[,2:6])
wj = NULL
pcmatrix=matrix(0, 25, 6)
for(i in 1:25){
  temp = cbind(test25[,i+1]-lag(ff5$RF),factorpool) %>% na.omit()
  pc=pcor(temp)
  pc=pc$estimate
  pcmatrix[i,]=as.numeric(pc[1,2:7])
}
wj=colSums(abs(z(pcmatrix)))^(-d)

lasso=glmnet(as.matrix(beta2[,1:6]), as.matrix(beta2[,7]), alpha = 1, 
             penalty.factor = wj)
print(lasso)
plot(lasso,xvar="lambda", label=TRUE)

plot_glmnet(lasso,lable=T)
dev.off()
sink()
