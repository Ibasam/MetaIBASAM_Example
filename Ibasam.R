Ibasam <-
  function (nInit # number of years at initialization (burn-in)
            , nYears # number of years of simulation (after initialization)
            , npop # number of populations
            , Pop.o # Index for the population of origin
            , area # juveniles production area (m2)
            , rmax # maximum recruitment (density max of juveniles)
            , alpha # Density-independent survival of juveniles;
            , pdisp # Dispersal probability
            , fisheries = FALSE, stage = TRUE, fishing_rate = fishing.rates ## fishing effects
            , plotting = TRUE, window = FALSE, returning = TRUE, success = FALSE, empty = TRUE
  ) 
  {
    
    #Initialization & Preparation:
    empty()
    def <- defaultParameters()
    
    #### POPULATION SPECIFIC PARAMETERS ####
    # required to define river/population characteristics
    def$envParam[9] <- area
    def$colParam[40] <- alpha
    def$colParam[41] <- area*rmax #rmax = Neggsmax  

    def$gParam[1] <- round(area*8*0.15)
    def$parrParam[1] <- round(area*8*0.15*0.011)
    def$smoltsParam[1] <- round(area*8*0.15*0.03)
    def$grilseParam[1] <- round(area*8*0.15*0.003)
    def$mswParam[1] <- round(area*8*0.15*0.0005)
    
    #### POPULATION SPECIFIC ENVIRONMENT ####
    ## Freshwater conditions:
    flow <- river_climate$flow[,Pop.o] 
    temperatures <- river_climate$temperatures[,Pop.o]
    
    def$envParam[3] <- 0.5 # Growth speed according to temperature -> dr
     module <- mean(river_climate$flow[Pop.o])
     def$envParam[7] <- 0.2 * module # Critical_RelativeFlow
     def$envParam[15] <- 0.1 * module #CritInfFlow
     def$envParam[16] <- 7 * module #CritSupFlow
     
     ## Oceanic growth conditions:
     MeanNoiseSea <- ocean_climate

    Reset_environment()
    Prepare_environment_vectors(temperatures, flow)
    setup_environment_parameters(def$envParam)
    setup_collection_parameters(def$colParam)
    
 
    
    ## Define fishing rates  
    if (fisheries) {
      if(stage){
        rates <- cbind(
          grilses=c(rep(fishing_rate[1],nInit),rep(fishing_rate[2],nYears))
          ,msw=c(rep(fishing_rate[3],nInit),rep(fishing_rate[4],nYears)) 
        )         
      } else {
        rates <- cbind(
          Small=c(rep(fishing_rate[1],nInit),rep(fishing_rate[1],nYears))
          ,Med=c(rep(fishing_rate[2],nInit),rep(fishing_rate[2],nYears))
          ,Big=c(rep(fishing_rate[3],nInit),rep(fishing_rate[3],nYears))
        )
      }
    }
    
    #### INITIALIZING POPULATION ####
    set_collecID(Pop.o) # provide ID number for each population (variable CollecID) to avoid duplicate individuals ID with migrants
    time_tick(90)
    add_individuals(def$gParam)
    add_individuals(def$parrParam)
    add_individuals(def$smoltsParam)
    go_summer()
    popo <- observe()
    add_individuals(def$grilseParam)
    add_individuals(def$mswParam)
    go_winter()
    
    popa <- observe()
    if (returning || success) {
      results <- popa #before: observe()
    }
    
    
    ratios <- matrix(NA, nrow = nInit+nYears, ncol = 4)
    winterM <- matrix(NA, nrow = nInit+nYears, ncol = 6)
    summerM <- matrix(NA, nrow = nInit+nYears, ncol = 18)
    ally <- summarize.oneyear(popo, popa)
    sptm <- NULL
    
    
    ## RUN
    pb   <- txtProgressBar(1, nYears+nInit, style=3) # initilazing progress bar
    N<-NULL #
    for (y in 1:(nYears+nInit)) {
      #cat("Year: ",y,"of ",nYears, "\n")
      setTxtProgressBar(pb, y) # progress bar
      
      # Oceanic growth conditions:
      def$envParam[1] <- MeanNoiseSea[y]
      setup_environment_parameters(def$envParam)
      
      ptm <- proc.time()
      spring()
      summer()
      
      #### FISHING ####
      popo <- observe() # state BEFORE fisheries
      if (fisheries) {
        fishing(rates[y,])
      }
      
      #popo <- observe() # state AFTER fisheries        
      if (returning || success) {
        results <- rbind(results, popo)
      }
      
      ratios[y, ] <- unlist(proportions.population(popo))
      summerM[y, ] <- unlist(important.indicator.summer.population(popo))
      
      autumn()
      winter()
      
      #### DISPERSAL ####
      for (Pop.e in 1:npop){
        # Pop.o: population of origin
        # Pop.e: disperse toward population Pop.e
        if(Pop.e == Pop.o) { 
          next 
        } else {
          # } else {
          emfile <- paste0("tmp","/Mig_",Pop.o,"-",Pop.e,"_",y,".txt") 
          emmigrants(emfile, pdisp[Pop.e])
        } # end if
      } # end Pop.e
      
      #pope <- observe()
      
      for (Pop.i in 1:npop){
        # Pop.o: population of origin
        # Pop.i: immigrate from population Pop.i
        if(Pop.i == Pop.o) { 
          next 
        } else {
          imfile <- paste0("tmp","/Mig_",Pop.i,"-",Pop.o,"_",y,".txt")
          pause(imfile) # R script to pause the execution of Ibasam until immigrant file (e.g. mig_AtoB) is created in a specific folder
          immigrants(imfile)
        } # end if
      } # end Pop.i
      

      popa <- observe() 

      if (returning || success) {
        results <- rbind(results, popa)
      }
      
      winterM[y, ] <- unlist(important.indicator.winter.population(popa))
      ally <- append.oneyear(popo, popa, ally)
      sptm <- rbind(sptm, proc.time() - ptm)
    }
    
    #### PLOT ####
    if (plotting) {
      pdf(paste('results/Res_Pop',Pop.o,'.pdf',sep=''))
      op <- par(mfrow = c(2, 2))
      plot_proportions_population(ratios, window = window)
      plot_winterM(winterM, window = window)
      plot_summerM(summerM, window = window)
      plotevolution(ally, window = window)
      par(mfrow = c(2, 1))
      if (success) {
        newwindow(window)
        suc <- temporal_analyse_origins(results, 1:nYears, 
                                        plotting = plotting, titles = "Strategy success through time")
      }
      newwindow(window)
      plot(ts(sptm[, 1]), main = "CPU time needed per year", 
           ylab = "seconds", xlab = "years", bty = "l", sub = paste("Total:", 
                                                                    round(sum(sptm[, 1]), 3)))
      lines(lowess(sptm[, 1]), col = 2, lty = 2)
      par(op)
      dev.off()
    }
    if (returning) {
      return(list("pop"=results))
    } else {
      invisible(NULL)
    }
  }
