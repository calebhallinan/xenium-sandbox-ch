### Look at SpatialFeatureExperiment (SFE) to understand the structure ###

# get libraries
library(SpatialFeatureExperiment)
library(SpatialExperiment)

# read in data
data = readRDS(here::here("processed-data/cindy/slide-5434/xenium-0005434-SFE.RDS"))

data$total

dimGeometry(data, "spotPoly", MARGIN = 2)

# escheR and voyager has functions to plot data from object


if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install("scry")

