library(tidyverse)
library(lubridate)
library(readr)
#install.packages("stargazer")
library(stargazer)
# Run from the project root (Rscript 01_five_factor_regression.R).
# Data are read from data/; console output is copied to results/.
dir.create("results", showWarnings = FALSE)
sink("results/01_five_factor_regression_output.txt", split = TRUE)
ff5=read_csv('data/F-F_Research_Data_5_Factors_2x3_daily.CSV')
ff5$date=ymd(ff5$date)
ff5$date=as_date(ff5$date)

pf=read_csv('data/25_Portfolios_5x5_Daily.csv')
pf=pf[1:25817,]
pf$date=ymd(pf$date)
pf$date=as_date(pf$date)

pf=pf[which(pf$date%in%ff5$date),]

dt=pf%>%left_join(ff5)

colnames(dt)

model1=lm(`SMALL LoBM`~`Mkt-RF`+SMB+HML+RMW+CMA,data=dt)
summary(model1)

model1.1=lm(`SMALL LoBM`~`Mkt-RF`+SMB+HML+RMW+CMA,data=dt[which(year(dt$date)<2000),])
summary(model1.1)
model1.2=lm(`SMALL LoBM`~`Mkt-RF`+SMB+HML+RMW+CMA,data=dt[which(year(dt$date)>=2000),])
summary(model1.2)


model2=lm(`BIG HiBM`~`Mkt-RF`+SMB+HML+RMW+CMA,data=dt)
summary(model2)

model2.1=lm(`BIG HiBM`~`Mkt-RF`+SMB+HML+RMW+CMA,data=dt[which(year(dt$date)<1980),])
summary(model2.1)
model2.2=lm(`BIG HiBM`~`Mkt-RF`+SMB+HML+RMW+CMA,data=dt[which(year(dt$date)>=1981&year(dt$date)<2000),])
summary(model2.2)
stargazer(model1,model1.1,model1.2)
sink()
