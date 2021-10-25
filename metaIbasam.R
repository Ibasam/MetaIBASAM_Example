#!/usr/bin/env Rscript

#_________________ PACKAGES _______________________#
library(metaIbasam)
#install.packages("metaIbasam_0.0.6_tar.gz", repos=NULL, type="source")
if(!require(doParallel)) { install.packages("doParallel"); library(doParallel) };
if(!require(MASS)) { install.packages("MASS"); library(MASS) };


#_________________ LOADING IBASAM _________________#
# Loading the (modified) Ibasam function used to simulate a population with its own characteristics
source("Ibasam.R")

#_________________ LOADING PARAMETERS _____________#
# Loading parameters of the popualtions scenarios (e.g. dispersal/philopatry rates)
source("parIbasam.R")

#_________________ SIMULATIONS _________________#

for (sim in 1:nSimulations){ # loop over X simulations
  
  # Create results folder
  ifelse(!dir.exists(paste0('results')),dir.create(paste0('results')), FALSE)
  
  # Create temporary folder
  ifelse(dir.exists(paste0('tmp')),unlink(paste0('tmp'), recursive = TRUE), FALSE)
  ifelse(!dir.exists(paste0('tmp')),dir.create(paste0('tmp')), FALSE)
  
  cl <- makeCluster(npop) # creating a cluster (multiple r session) of size = number of popualtions (npop) 
  registerDoParallel(cl) # R sessions will be run in parallel
  
  results <- foreach(i=1:npop, .packages='metaIbasam', .verbose=T) %dopar% {
    
    tryCatch({
      
      Ibasam(nInit=nInit # number of years at initialization (burn-in)
             , nYears=nYears # number of years of simulation (after initialization)
             , npop = npop # Number of populations in the metapopulation
             , Pop.o = i # Population of origin
             , area = Area[i]*rPROP # Total area observed x proportion to simulate (0-1, if rPROP=1)
             , rmax = Rmax[i] # Maximum recruitment; reference Scorff river
             , alpha = Alpha[i] # Density-independent survival of juveniles; reference Scorff river
             , pdisp = pdisp[i,]  # Dispersal probability (population of origin in line)
             , fisheries = FALSE, stage = fish.stage, fishing_rate=fishing.rates[i,] # fishing rates
             , returning = TRUE # if TRUE, return R object contaning all data (very long)
             , plotting = TRUE,window=FALSE,success=FALSE,empty=TRUE
      )
      
    }, error = function(e) return(paste0("The population '", i, "'",  " caused the error: '", e, "'")))

  } # end foreach function
  

  save(results,file=paste0("results","/Metapop_Sc",scenarioConnect,"_Sim",sim,".RData"))

  
  
  # Cleaning
  stopCluster(cl); rm(cl)  # stop et remove cluster
  gc() # clean Rmemory
  system(paste0('rm -R tmp')) #if want to not remove the folder tmp

  
  } # end loop for simulation
#q('no') # close R session 
