### Look at SpatialFeatureExperiment (SFE) to understand the structure ###

# get libraries
library(SpatialFeatureExperiment)
library(SpatialExperiment)

# read in data
data = readRDS(here::here("data/xenium-0005434-SFE.RDS"))

data$total

dimGeometry(data, "spotPoly", MARGIN = 2)
