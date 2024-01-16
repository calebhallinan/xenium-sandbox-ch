### Look at SpatialFeatureExperiment (SFE) to understand the structure ###

# get libraries
library(SpatialFeatureExperiment)
library(SpatialExperiment)
library(escheR)

# read in data
data = readRDS(here::here("processed-data/cindy/slide-5434/xenium-0005434-SFE.RDS"))

data$total


# escheR and voyager has functions to plot data from object


if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("BiocStyle")

remotes::install_github("prabhakarlab/Banksy")

devtools::install(here("Banksy-bioc"), repos=NULL, type='source')


 
### look at data ###

#read in data
data = readRDS(here::here("data/slide-5434/Br6471_Post_SFE.RDS"))
colData(data)

# plot
make_escheR(data, spot_size=20) |> add_fill(var = "nGenes_normed") 


library(STexampleData)
spe <- Visium_humanDLPFC()
make_escheR(spe, spot_size=0.1) |> add_fill(var = "in_tissue") 
make_escheR(spe, spot_size=5) |> add_fill(var = "in_tissue") 
make_escheR(spe, spot_size=10) |> add_fill(var = "in_tissue") 
# All these look the same