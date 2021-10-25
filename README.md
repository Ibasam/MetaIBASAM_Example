MetaIBASAM:  A demo-genetic agent-based model to simulate spatially structured salmon populations

MetaIbasam is an extension of the existing IBASAM model (https://github.com/Ibasam/IBASAM/wiki) by incorporating a dispersal process to describe Atlantic salmon metapopulation and its eco-evolutionary dynamics. MetaIBASAM allows an investigation of the consequences of dispersal on local populations and network dynamics at the demographic, phenotypic, and genotypic levels. More generally, it allows to explore eco-evolutionary dynamics by taking into account complex interactions between ecological and evolutionary processes (plasticity, genetic adaptation and dispersal), feedbacks (e.g. genetic <-> demography) and trade-offs (e.g. growth vs survival). By doing so, one can investigate responses to changing environments and alternative management strategies.
----

Contact: mathieu.buoro@inrae.fr
----


Here, we provide a simple example to run simulations using MetaIBASAM.
The master R file is metaIbasam.R which call the R packages and scripts Ibasam.R (function to run IBASAM) and parIbasam.R (required and run the required.

metaIbasam.R: load data and parameters and run the function Ibasam in parallel;
Ibasam.R: function to run Ibasam (one session for each population);
parIbasam.R: generate and load population-specific parameters, scenarios (e.g. dispersal rate) and environmental conditions;

Below, here the steps to modify and run the analysis:

## 1. Define population parameters in data/dataPop.csv:
- populations characteristics are provided in the table (file dataPop.csv) in the folder data/;

## 2. Define simulation parameters and scenario in parIbasam.R:
  - Modify the simulation parameters, e.g.:
    nSimulations = 1; # number of simulations
    nYears = 30 # number of years to simulate
    nInit = 10 # number of years to simulate at initialization (warm-up)
    rPROP = .25 # proportion of area (= population size) to simulate; from 0 (rPROP=0) to 100% (rPROP=1) 

 - one can modify the dispersal kernel and/or the scenario (philopatry rate, "scenarioConnect"), environmental conditions (discharge, water temperature) and exploitation rates in parIbasam.R
 
## 3. Run metaIbasam.R in a R session:
 - library, data and parameters provided by parIbasam.R will loaded; /!\ R packages doParallel and MASS are required!!!
 - simulated environmental conditions will be generated using the R function provided in "climate_simulation.R" in the folder code/ ;
  - environmental data are saved in the folder data/;
 - dispersal matrix will be generated from the R function provided in "dispersal_matrix.R" in the folder code/ ;
 - metaIbasam will create two folders:
    results/ : all results will be saved in this folder
    tmp/ :  temporary text files containing all individual information of migrants from all populations. Example: "Mig_1_3_10.txt" = Migrants from population 1 to population 3 at year 10;
    
  - The function "foreach" of the library "doParallel" will run all populations in parallel in different R sessions.
  
  - check the folder results/ !!!
 
 
