###########################################################################################################
###########################################################################################################

### Visualize the gene expression of Xenium data ###
### Caleb Hallinan ###
### 01/17/2024 ###

###########################################################################################################
###########################################################################################################


### read in libraries ###

library(SpatialFeatureExperiment)
library(SpatialExperiment)
library(escheR)
library(Seurat)
library(SeuratData)
library(ggplot2)
library(patchwork)
library(dplyr)


###########################################################################################################
###########################################################################################################


### read in data ###

# just open section
spe = readRDS(here::here("data/slide-5434/Br6471_Post_SFE_filt.RDS"))

# check columns
colData(spe)

# grab gene expression matrix
expr_mat = assays(spe)$counts


###########################################################################################################
###########################################################################################################


### plot gene expression on tissue ###

# add gene of interest to column data
g = "IL7R"
colData(spe)[g] = expr_mat[g,]

# plot
# make_escheR(spe) |> add_fill(var = "total_counts", point_size=1) 
make_escheR(spe) |> add_fill(var = g, point_size=1) 
make_escheR(spe) |> add_ground(var = g, point_size=.5) + scale_color_continuous(type = "viridis")



###########################################################################################################
###########################################################################################################


### Volcano plots ###

# maybe do this?
# https://bioconductor.org/packages/devel/bioc/vignettes/EnhancedVolcano/inst/doc/EnhancedVolcano.html



