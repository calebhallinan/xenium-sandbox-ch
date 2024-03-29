# CH: successfully runs clustering using BANKSY
suppressPackageStartupMessages({
    library(Voyager)
    library(SpatialFeatureExperiment)
    library(SpatialExperiment)
    library(ggplot2)
    library(stringr)
    library(BiocSingular)
    #library(scater)
    library(BiocParallel)
    library(dplyr)
    library(here)
    library(gridExtra)
    library(Banksy)
    library(scuttle)
    library(escheR)
    library(RColorBrewer)
})
#------------------------------------------------------------#
# Trying out Banksy for spatial domain detection:
# tutorial: https://github.com/prabhakarlab/Banksy/tree/bioc
#------------------------------------------------------------#
# args <- commandArgs(trailingOnly = TRUE)
# args <-  c("data/slide-5434/Br6522_Post_SFE_filt.RDS", 0.9, 0.5) # CH: adding to run local
args <-  c("/users/challina/xenium-sandbox-ch/data/slide-5434/Br6522_Post_SFE_filt.RDS", 0.9, 0.5) # CH: adding to run local
lambda <- as.numeric(args[[2]])
#k <- args[[3]]
res <- as.numeric(args[[3]])

print(lambda)
print(res)

# read in the data
sfe <- readRDS(args[[1]])
# sfe <- readRDS("/users/challina/xenium-sandbox-ch/data/slide-5434/Br6522_Post_SFE_filt.RDS")
# sfe <- readRDS("data/slide-5434/Br6471_Post_SFE_filt.RDS")
# delete this line after the first run
#colData(sfe) <- colData(sfe)[,!grepl("^clust", colnames(colData(sfe)))]


sfe <- computeLibraryFactors(sfe)
aname <- "normcounts"
assay(sfe, aname) <- normalizeCounts(sfe, log = FALSE)


# Compute neighbourhood matrices
#lambda <- c(0, 0.9)
k_geom <- c(15, 30)

sfe <- Banksy::computeBanksy(sfe, assay_name = aname, compute_agf = TRUE,
                             k_geom = k_geom)

# run PCA and UMAP, then Leiden clustering to find spatial domains
# lambda is in [0,1], higher values of lambda puts more weight on spatial
# information
set.seed(1000)
sfe <- Banksy::runBanksyPCA(sfe, use_agf = TRUE, lambda = lambda)
print("PCA done")
sfe <- Banksy::runBanksyUMAP(sfe, use_agf = TRUE, lambda = lambda)
print("UMAP done")

# for leiden, higher resolution = more clusters, 
# lower resolution = fewer clusters
sfe <- Banksy::clusterBanksy(sfe, use_agf = TRUE, lambda = lambda, 
                             resolution = res)
print("clustering done")

# save the Banksy results
saveRDS(sfe, args[[1]])

# default for the leiden algorithm in clusterBanksy is k_neighbours=50
clustName <- sprintf("clust_M1_lam%s_k%s_res%s", lambda, 50, res)


# plot using escheR 
colourCount = nlevels(colData(sfe)[[clustName]])
getPalette = colorRampPalette(brewer.pal(12, "Set3"))


    
if (class(sfe)=="SpatialExperiment"){ # save to different location if it's visium
    
    p1 <- make_escheR(sfe, y_reverse=TRUE) %>%
        add_fill(var=clustName)+
        scale_fill_manual(values=getPalette(colourCount))
    
    fname <- paste(sfe$subject_position[[1]], "visium", "Banksy", "lambda", 
                   lambda, "res", res, sep="-")
    pdfname <- paste0(fname, ".pdf")
    pdf(here("plots", "05_segmentRegions", "banksy", "visium", pdfname))
    print(p1)
    dev.off()
} else{
    
    p1 <- make_escheR(sfe, y_reverse=FALSE) %>%
        add_fill(var=clustName)+
        scale_fill_manual(values=getPalette(colourCount))
    
    fname <- paste(sfe$region_id[[1]], "Banksy", "lambda", 
                   lambda, "res", res, sep="-")
    pdfname <- paste0(fname, ".pdf")
    pdf(here("plots", "05_segmentRegions", "banksy", pdfname))
    print(p1)
    dev.off()
}



