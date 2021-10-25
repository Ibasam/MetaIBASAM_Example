##### CONNECTIVITY MATRIX #####


##### I. DISTANCE ####
distance=matrix(data=NA, ncol=npop, nrow=npop)
colnames(distance)=rownames(distance)=pops


# Relative distance between rivers
dist <- dat$Distance
for (i in 1:npop){
  for (j in 1:npop){
    distance[i,j]=abs(dist[j]-dist[i])
  }}


##### II. AREA #####
# Relative river size
area_log=log10(dat$Area)
ratio_area=matrix(, nrow=1, ncol= npop); colnames(ratio_area)=pops
for (i in 1:npop){
  ratio_area[1,i]=area_log[i]/(sum(area_log))
  } 


##### III. DISPERSAL KERNEL #####
lap = function(mu, beta, distance) {(1/(2*beta))*exp(-(distance-mu)/beta)} # Laplace function

##### IV. CONNECTIVITY MATRIX #####
connect_kernel=matrix(, nrow=npop, ncol=npop)
rownames(connect_kernel)=colnames(connect_kernel)=pops
connect=list()

# Calculate probability to disperse for each population based on philopatry rate (h), distance across populations and population size (area)
for (i in 1:npop){
  attrac_d=lap(mu, beta, distance[i,]) #attractivity score of sites based on distance
  attrac_d[i]<-0 # ignore population of origin
  attrac_ad=attrac_d*ratio_area # influence of area on attractivity
  proba_attract_ad=attrac_ad/sum(attrac_ad) #probability of attractivity
  sum(proba_attract_ad)
  
  proba_dispersal=proba_attract_ad*(1-h[scenarioConnect]) # probability to disperse
  proba_dispersal[i] <- h[scenarioConnect] # philopatry
  connect_kernel[i,]=proba_dispersal
  test <- rowSums(connect_kernel) #sum of probabilities should be = 1
  if (!(any(test==1))) {
    print ("something wrong with dispersal kernel")
    connect_kernel <- NULL
  }
}
