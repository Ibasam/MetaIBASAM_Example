
## Function to simulate environmental conditions (daily water temperature and flow) for all rivers of the metapopulation
## River specific parameters should provided in parameters file ("parIbasam.R")

#_________________ SINUSOIDAL MODEL _________________#
# m: annual average
# amp: amplitude, peak deviation of the function from zero
# phase: 
# ar: autoregressive parameter (order 1)
# eps: residual error
# day: julian day
# nday: total number of days (365)
sinus_model_resid_ar_multi <-  function (m, amp, phase, ar, eps, day, nday) 
  {
    error <- numeric(length(day))
    tm <- m + amp * sin(2 * pi * (day - phase)/nday)
    error[1] <- 0
    for (dd in day[-1]) {
      error[dd] <- ar[1] * error[dd - 1] + eps[dd]
      tm[dd] <- tm[dd] + error[dd]
    }
    return(tm)
  }


#_________________ SPATIAL COVARIATION _________________#
# extract residual errors values
eT <- mvrnorm(365*(nInit + nYears + 1),mu = rep(0,npop),Sigma = covMatT, empirical = TRUE)
eF <- mvrnorm(365*(nInit + nYears + 1),mu = rep(0,npop),Sigma = covMatF, empirical = TRUE)


#_________________ SIMULATION OF ENVIRONMENTAL CONDITIONS _________________#

## 1. Freshwater conditions:
river_climate_model_multi <- function (npop, nInit, nYears) 
{
  
  nyear = nInit + nYears + 1
  nday <- 365
  day <- 1:(365 * nyear)
  
  temperatures=NULL
  logrelflow=NULL
  
  for (pop in 1:npop){

    #compute water temperature
    tmpT <- sinus_model_resid_ar_multi(mT[pop], ampT[pop], phaseT[pop], arT[pop], eT[,pop], day, nday)
    #compute water flow 
    tmpF <- sinus_model_resid_ar_multi(mF[pop], ampF[pop], phaseF[pop], arF[pop], eF[,pop], day, nday)
    
    # Remove for outliers
    tmpT[tmpT < 0] <- 0.01 # water temperature cannot be negative
    tmpF[tmpF > 3] <- 3 # upper limits of water flow (at log scale)
    tmpF[tmpF < -3] <- -3 # lower limits of water flow (at log scale)
    
    temperatures <- cbind(temperatures,tmpT)    
    logrelflow <- cbind(logrelflow,tmpF)
    
  } # end loop pop
  
  return(list(temperatures = temperatures, flow = exp(logrelflow)))
}

# return data:
river_climate <- river_climate_model_multi(npop, nInit, nYears) 

## 2. Oceanic growth conditions:
MeanNoiseSea <- c(rep(1,nInit),seq(1,1,length=nYears)) #MeanNoiseSea
ocean_climate <- MeanNoiseSea
  
save(river_climate, ocean_climate, file="data/climate_simulation.Rdata")
