### Tutorial here: https://pachterlab.github.io/voyager/articles/vig5_xenium.html ###

# read in packages
library(Voyager)
library(SFEData) 
library(SingleCellExperiment)
library(SpatialExperiment)
library(SpatialFeatureExperiment)
library(ggplot2)
library(stringr)
library(scater) 
library(scuttle)
library(BiocParallel)
library(BiocSingular)
library(bluster)
library(scran)
library(patchwork)
theme_set(theme_bw())

# read in dataset
(sfe <- JanesickBreastData(dataset = "rep2"))

# assign cell ids
colnames(sfe) <- seq_len(ncol(sfe))

# plot tissue
plotGeometry(sfe, "cellSeg")

# plot cell density
plotCellBin2D(sfe, hex = TRUE)

# QC
names(colData(sfe))
