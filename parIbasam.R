#set.seed(666) # R‘s random number generator. Use the set.seed function when running simulations to ensure all results, figures, etc are reproducible.

#_________________ SIMULATION PARAMETERS _________________#
nSimulations = 1; # number of simulations
nYears = 20 # number of years to simulate
nInit = 10 # number of years to simulate at initialization (warm-up)
rPROP = .25 # proportion of area (= population size) to simulate; from 0 to 100% (rPROP=1) 


############ 1. POPULATIONS PARAMETERS ############
## 1.1 Population characteristics
dat <- read.csv2("data/dataPop.csv", header=TRUE, stringsAsFactors = FALSE, comment.char = "#")

pops <- dat$Population; # population name
npop <- length(pops) # number of populations

Area=as.numeric(dat$Area) # area of juvenile production
Rmax=as.numeric(dat$Rmax) # maximum recruitment
Alpha=as.numeric(dat$alpha) # density-independent survival
Type=dat$Type # source-neutral-sink type



#_________________ SCENARIOS _________________#



#############@ 1. CONNECTIVITY #############

# 1.1 Parameters for Laplace kernel
mu=0
beta=29.5 # so that >80% of migrants disperse into the first 50km

# 1.2 Choose Philopatry/dispersal scenario
h = c(1, 0.95, 0.9, 0.85, 0.8, 0.75, 0.7) # Philopatry (homing) rates ; dispersal rate = 1 - h
scenarioConnect=3 #scenario = 1 for h=1.00, scenario = 2 for h=0.95, ....

# 1.3 simulate dispersal matrix
if (npop < 2){
  pdisp = matrix(1,npop,npop)
} else {
  source("code/dispersal_matrix.R")
  pdisp = connect_kernel
}





############ 2. ENVIRONMENT ############

## 2.1 Environmental conditions (discharge, water temperature)

## Parameters for the sinusoidal function
# Here, we used the Scorff parameters adjusted on 1970-2007 data for all rivers

## water temperature
mT <- rep(12.674299, npop)
ampT <- rep(5.909091, npop)
phaseT <- rep(114.780948, npop)
arT <- rep(0.95184170929478, npop)
sigmaT <- rep(0.449967327959108,npop)

## water flow
mF <- rep(-0.02,npop)
ampF <- rep(1.010139,npop)
phaseF <- rep(327.836285,npop)
arF <- rep(0.964034622660953,npop)
sigmaF <- rep(0.118343974744226,npop)

## Spatial covariation
rho<-0 # spatial correlation (synchrony)
corMat <- array(rho,dim=c(npop,npop)); diag(corMat)<-1

#Create the covariance matrix:
covMatT <- sigmaT %*% t(sigmaT) * corMat
covMatF <- sigmaF %*% t(sigmaF) * corMat


# Simulation:
source("code/climate_simulation.R") # simulate environmental conditions (daily water temperature and water flow) for all rivers of the metapopulation



################ 3. FISHERIES ###############@
fish.state=TRUE # TRUE If fishing applied
fish.stage=TRUE # fishing on life stages (1SW/MSW) if TRUE, on Sizes ("small","med","big") otherwise


if ( fish.stage==TRUE)
{
  frates = c(0.1, 0.1, 0.1, 0.1) # (1SW_init, 1SW, MSW_init, MSW)
}

if ( fish.stage==FALSE)
{
  frates = c(0.07, 0.10, 0.15) # fishing rates by size (e.g. small, medium, big)
}

fishing.rates <- frates





