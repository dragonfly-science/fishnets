# steepness tests;

# Source in the package
source('collate.R')

# Load the Fishbase data
fb <- FishbaseWeb$read('data/fishbase-web')
# Limit to the 7940 with both k and linf
fb <- subset(fb,!is.na(k) & !is.na(linf))
# An an id column for indexing later
fb$id <- 1:nrow(fb)
# Add a dummy row for helping with predictor nodes
# that need to have at least two predictors
fb$dummy <- 1.0


steppa <- Steepness$create('./data/steepness')
steppa_merged <- Steepness$merge(steppa,fb)

# Create test net for steepness
steep_net <- Fishnet(
  species   = SpeciesRandom(),
  genus     = GenusParser(),
  family    = FamilyLookupper(),
  order     = OrderLookupper(),
  class     = ClassLookupper(),
  
  habit     = TaxonomicImputer('habit'),
  depthmax  = TaxonomicImputer('depthmax',c(log,exp),2),
  trophic   = TaxonomicImputer('trophic',c(log,exp),2),
  lmax      = TaxonomicImputer('lmax',c(log,exp),2),
  amax      = TaxonomicImputer('amax',c(log,exp),2),
  fecundity = TaxonomicImputer('fecundity',c(log,exp),2),
  
  linf      = Glmer(log(linf)~class+order+family+log(lmax),exp),
  k         = Brter(log(k)~class+order+family+log(linf)+habit+log(depthmax)+trophic,exp),
  m         = Svmer(log(m)~class+order+family+log(k)+log(amax),exp),
  lmat      = Glmer(log(lmat)~class+order+family+log(linf),exp),
  #mean_R_z  = Brter(log(mean_R_z-0.2)~log(linf)+m+fecundity+trophic+log(lmat)+log(k),transform = function(x){exp(x)+0.2},bag.fraction = 0.5,ntrees=0)
  #mean_R_z  = Svmer(log(mean_R_z-0.2)~log(linf)+m+fecundity+trophic+log(lmat)+log(k),transform = function(x){exp(x)+0.2})
  mean_R_z  = Svmer(log(mean_R_z-0.2)~log(linf)+m+fecundity+trophic+log(lmat)+log(k)+log(amax),transform = function(x){exp(x)+0.2})
  #recsigma  = RecsigmaThorsonEtAl2014(),
  #recauto   = RecautoThorsonEtAl2014()
  #recsteep  = RecsteepHeEtAl2006()
)
# Fit to Fishbase data
steep_net$fit(steppa_merged,impute = T)

#steep_net$nodes$mean_R_z$fit(steppa_merged)
summary(steep_net$nodes$mean_R_z$glm)
summary(steep_net$nodes$mean_R_z$brt)
summary(steep_net$nodes$mean_R_z$svm)
# check it ------

canary <- steep_net$sample(list(
  species = 'Sebastes pinniger'
),samples = 10000)

ggplot(canary) + 
  geom_bar(aes(x=mean_R_z,y=..density..),fill='grey40') + 
  scale_x_continuous(limits=c(0,3)) + 
  labs(x='Steepness (z)',y='Density')

salmo <- steep_net$sample(list(
  species = 'Salmo salar'
),samples = 10000)

ggplot(salmo) + 
  geom_bar(aes(x=mean_R_z,y=..density..),fill='grey40') + 
  scale_x_continuous(limits=c(0,2)) + 
  labs(x='Steepness (z)',y='Density')

Cod <- steep_net$sample(list(
  species = 'Gadus morhua'
),samples = 10000)

ggplot(Cod) + 
  geom_bar(aes(x=mean_R_z,y=..density..),fill='grey40') + 
  scale_x_continuous(limits=c(0,5)) + 
  labs(x='Steepness (z)',y='Density')


Herring <- steep_net$sample(list(
  species = 'Clupea Harengus'
),samples = 10000)

ggplot(Herring) + 
  geom_bar(aes(x=mean_R_z,y=..density..),fill='grey40') + 
  scale_x_continuous(limits=c(0,3)) + 
  labs(x='Steepness (z)',y='Density')


ggplot(Cod) + 
  geom_bar(aes(x=m,y=..density..),fill='grey40') + 
  scale_x_continuous() + 
  labs(x='Natural mortality (m)',y='Density')

########################################

bwa <- steep_net$sample(list(
  species = 'Hyperoglyphe antarctica',
  # Maximum length, temperature and 
  # maximum depth from Fishbase
  lmax = 140,
  temp = 11,
  depthmax = 1500,
  # Female growth and max age from 
  # Horn et al 2010
  linf = 92.5,
  k = 0.071,
  amax = 71  
),samples = 10000)

ggplot(bwa) + 
  geom_bar(aes(x=mean_R_z,y=..density..),fill='grey40') + 
  scale_x_continuous() + 
  labs(x='Steepness (z)',y='Density')

ggplot(bwa) + 
  geom_point(aes(x=m,y=mean_R_z),alpha=0.4) + 
  scale_x_log10(breaks=seq(0.1,1.1,0.2)) + 
  scale_y_log10(breaks=seq(0.1,1.1,0.2)) + 
  labs(x='Natural mortality rate (M)',y='Steepness')

########################################

########################################

s_sub <- steppa_merged %.% filter(!is.na(mean_R_z)) %.% group_by(species) %.% summarise(z = unique(mean_R_z)) %.% filter(!is.na(z))

su_sub <- steppa_merged %.% filter(!is.na(mean_R_z)) %.% group_by(species) %.% summarise(z = unique(mean_R_z)) %.% filter(!is.na(z))

# fb_full = subset(steppa_merged,id %in% model.frame(
#  log(k) ~ id + class + order + family + genus + species + 

#    swimmode + habit + feeding + diet + trophic + log(depthmax) + temp + 
#    fecundity + mean_R_z + log(lmax)
#  ,fb)$id)
nrow(fb_full)
length(unique(fb_full$species))
fb_full$species = factor(fb_full$species)
spp <- unique(fb_full$species)
spp_group <- sample(1:2,length(spp),replace=T)
sp1 <- subset(fb_full,species %in% spp[spp_group==1])
sp2 <- subset(fb_full,species %in% spp[spp_group==2])

steep_net$fit(fb_full)

cmp <- data.frame(
  preds = steep_net$nodes$mean_R_z$predict(s_sub),
  obs = s_sub$mean_R_z
)

ggplot(cmp) + geom_point(aes(x=preds,y=obs),size=3,alpha=0.3) +
  geom_abline(a=0,b=1) +
  scale_x_log10("Predicted k",breaks=c(0.1,0.2,0.5,1.0,2.0),limits=c(0.05,2)) + 
  scale_y_log10("Observed k",breaks=c(0.1,0.2,0.5,1.0,2.0),limits=c(0.05,2))


par(las=1,mar=c(4,7,1,1))
summary(brt$brt)

brt$fit(sp1)
cmp <- data.frame(
  preds = brt$predict(sp2),
  obs = sp2$k
)
ggplot(cmp) + geom_point(aes(x=preds,y=obs),size=3,alpha=0.3) +
  geom_abline(a=0,b=1) +
  scale_x_log10("Predicted k",breaks=c(0.1,0.2,0.5,1.0,2.0),limits=c(0.05,2)) + 
  scale_y_log10("Observed k",breaks=c(0.1,0.2,0.5,1.0,2.0),limits=c(0.05,2))

brt <- 
  
  Brter(
    log(k) ~ class + order + 
      swimmode + habit + feeding + diet + trophic + log(depthmax) + temp + 
      fecundity + log(lmax),
    exp,ntrees=2000)


brt$fit(fb_full)
par(las=1,mar=c(4,7,1,1))
summary(brt$brt)

brt$fit(sp1)
cmp <- data.frame(
  preds = brt$predict(sp2),
  obs = sp2$k
)
ggplot(cmp) + geom_point(aes(x=preds,y=obs),size=3,alpha=0.3) +
  geom_abline(a=0,b=1) +
  scale_x_log10("Predicted k",breaks=c(0.1,0.2,0.5,1.0,2.0),limits=c(0.05,2)) + 
  scale_y_log10("Observed k",breaks=c(0.1,0.2,0.5,1.0,2.0),limits=c(0.05,2))

###########################################
# Comparison of 

#' Plot density histograms
plot_samples <- function(samples,species_,pars=c('linf','k','m','mean_R_z')){
  data = subset(steppa_merged,species==species_)
  
  melted <- melt(samples[,pars])
  data_melted <- melt(data[,pars])
  ggplot(melted,aes(x=value)) +
    geom_bar(data=data_melted,aes(y = ..density..)) +
    geom_density(fill=hsv(0,0.7,0.7),alpha=0.5) +
    facet_wrap(~variable,scales='free') + 
    labs(x='',y='Density') + 
    theme(strip.text.x=element_text(size=10))
}

steep_net$fit(subset(steppa_merged,species!='Gadus morhua'))

preds <- steep_net$sample(list(
    species = 'Gadus morhua'
  ))

plot_samples(preds,'Gadus morhua')

plot_samples(
  
  steep_net$sample(list(
    species = 'Gadus morhua',
    swimmode = 'subcarangiform',
    habit = 'benthopelagic',
    depthmax = 600,
    temp = 5,
    lmax = 132
  )),
  
  'Gadus morhua'
)

preds <- steep_net$sample(dists(
  species =  Fixed('Gadus morhua'),
  swimmode = Fixed('subcarangiform'),
  habit = Fixed('benthopelagic'),
  depthmax = Fixed(600),
  temp = Trapezoid(2,3,6,7),
  lmax = Fixed(132),
  linf = Normal(110,20),
  k = Triangle(0.07,0.13,0.35),
  amax=Fixed(20)
))

plot_samples(preds,'Gadus morhua')

###############################

steep_net$fit(subset(steppa_merged,species!='Katsuwonus pelamis'))

plot_samples(
  
  steep_net$sample(list(
    species = 'Katsuwonus pelamis',
    family = 'Scombridae'
  )),
  
  'Katsuwonus pelamis'
)

plot_samples(
  
  steep_net$sample(dists(
    species = Fixed('Katsuwonus pelamis'),
    family = Fixed('Scombridae'),
    depthmax = Fixed(260),
    lmax = Fixed(90.5)
  )),
  
  'Katsuwonus pelamis'
)


plot_samples(
  
  steep_net$sample(dists(
    species = Fixed('Katsuwonus pelamis'),
    family = Fixed('Scombridae'),
    depthmax = Fixed(260),
    lmax = Fixed(90.5),
    linf = Normal(80,10),
    k = Normal(0.6,0.1)
  )),
  
  'Katsuwonus pelamis'
)