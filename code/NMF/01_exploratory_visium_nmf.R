library(RcppML)
library(Matrix)
library(Voyager)
library(CoGAPS)
library(projectR)
library(spatialLIBD)
library(escheR)
library(here)
library(tidyverse)
library(ggforce)
################################################################################
# Use RcppML::nmf to perform non-negative matrix factorization on the manually
# annotated Visium dataset to get a loadings matrix and a factors matrix with 
# k factors. Plot each of those k factors as well as the layer labels to see
# if any of them are associated with a particular layer.
################################################################################

args <- commandArgs(trailingOnly = TRUE)
model_type <- args[[1]]


if(model_type == "manual_annot"){ # use manual annotations
    layer_labs <- "layer_guess_reordered"
    data_type <- "spe"
}else if(model_type == "bayesspace"){
    layer_labs <- "BayesSpace_harmony_09"
    data_type <- "spatialDLPFC_Visium"
}

# get the manually annotated visium data
ehub <- ExperimentHub::ExperimentHub()
vis_anno <- fetch_data(type = data_type, eh = ehub)

# NMF on the annotated visium data
k <- as.numeric(args[[2]])
A <- logcounts(vis_anno) # using logcounts because there are multiple datasets
#model <- RcppML::nmf(A, k = k, seed=1237)
model <- readRDS(here("processed-data", "cindy", "NMF", model_type,
                      sprintf("%s-visium-nmf-model-k%s", model_type, k)))
patterns <- t(model$h) # these are the factors

rownames(model$w) <- rowData(vis_anno)$gene_name

saveRDS(model, here("processed-data", "cindy", "NMF", model_type, 
                    sprintf("%s-visium-nmf-model-k%s.RDS", model_type, k)))

colnames(patterns) <- paste0("NMF", 1:k)
colData(vis_anno) <- cbind(colData(vis_anno), patterns)

brains <- unique(vis_anno$sample_id)
# pdf(here("plots", "cindy", "NMF", model_type, 
#          sprintf("%s-all-visium-samples-NMF-k%s.pdf", model_type,k)), 
#     height=25, width=20)
# for(i in 1:k){
#     pls<- list()
#     patternName <- paste0("NMF", i)
#     for (j in seq_along(brains)){
#         spe <- vis_anno[,which(vis_anno$sample_id==brains[[j]])]
#         pls[[j]] <- make_escheR(spe) |>
#             add_ground(layer_labs) |>
#             add_fill(patternName) +
#             scale_fill_gradient(low = "white", high = "black")+
#             ggtitle(paste(unique(spe$sample_id), patternName))
#     }
#     cor.mat <- colData(vis_anno)[,c(paste0("NMF", i), 
#                                layer_labs, "sample_id")] %>%
#         as.data.frame()%>%
#         pivot_longer(cols=starts_with("NMF"))
#     bp <- ggplot(transform(cor.mat, name=factor("name", levels=colnames(patterns))),
#                  aes_string(x=layer_labs, y="value", 
#                      fill=layer_labs))+
#         geom_boxplot()+
#         facet_wrap(~sample_id, scales="free")+
#         scale_y_log10()+
#         theme(legend.position="none", plot.title=element_text(size=20))+
#         theme_minimal()
#  
#     
#     do.call(gridExtra::grid.arrange, c(pls, ncol=3))
#     print(bp)
#     rm(pls)
#     gc()
# }
# dev.off() #need to change layer_guess_reordered to be more general

# Compute correlation between NMF factors and layer identities 
# colnames(patterns) <- paste0("NMF", 1:k)
labels <- unique(colData(vis_anno)[[layer_labs]])
n_labels <-length(labels)
factors.ind <- matrix(,nrow=dim(vis_anno)[[2]], ncol=n_labels)
for (i in 1:n_labels){
    label <- labels[[i]]
    factors.ind[,i] <- as.integer(colData(vis_anno)[[layer_labs]]== label)
}

colnames(factors.ind) <- labels
factors.ind <- as.data.frame(factors.ind)

cor.mat <- cbind(patterns, factors.ind)
cor.mat$`NA` <- NULL


M <- cor(cor.mat, use="complete.obs")
M <- M[grepl("NMF", rownames(M)), !grepl("NMF", colnames(M))]

# compute the correlation between NMF factors and the brain IDs
brs <- unique(colData(vis_anno)[["sample_id"]])
n_brs <- length(brs)
brs.ind <- matrix(, nrow=ncol(vis_anno), ncol=n_brs)

for (i in 1:n_brs){
    br <- brs[[i]]
    brs.ind[,i] <- as.integer(colData(vis_anno)[["sample_id"]]==br)
}

colnames(brs.ind) <- brs
brs.ind <- as.data.frame(brs.ind)


brs.cor.mat <- cbind(patterns, brs.ind)
print(colnames(brs.cor.mat))

brs.M <- cor(brs.cor.mat, use="complete.obs")
print(head(brs.M))
if (data_type=="spe"){
    brs.M <- brs.M[grepl("NMF", rownames(brs.M)), grepl("^[[:digit:]]+$", colnames(brs.M))]
}else if (data_type=="spatialDLPFC_Visium"){
    brs.M <- brs.M[grepl("NMF", rownames(brs.M)), grepl("^Br", colnames(brs.M))]
}

print(brs)
print(head(brs.M))

# pseudobulk to get an expression profile for each domain label and compute the
# correlation between each NMF factor and the domain expression profile.

summed <- scuttle::aggregateAcrossCells(vis_anno, 
                            ids=colData(vis_anno)[c(layer_labs, "sample_id")])
summed$layer_donor <- paste(colData(summed)[[layer_labs]], 
                            summed$sample_id, sep="_")

expr_profiles <- as.data.frame(as.matrix(counts(summed)))
colnames(expr_profiles) <- summed$layer_donor

expr_prof_cor_mat <- cbind(patterns, expr_profiles)
exprs.M <- cor(expr_prof_cor_mat, use="complete.obs")

exprs.M <- exprs.M[grepl("NMF", rownames(exprs.M)), 
                   !(grepl("NMF", colnames(exprs.M)))]
print(head(exprs.M))


col <- circlize::colorRamp2(seq(-1, 1, length = 3), c("blue", "#EEEEEE", "red"))
fname <- sprintf("%s_NMF_layer_corr_plot_k%s.pdf", model_type, k)
pdf(here("plots", "cindy", "NMF", model_type, fname), height=30, width=30)
ComplexHeatmap::Heatmap(t(as.matrix(M)), col=col,
                        row_names_gp = grid::gpar(fontsize = 30),
                        column_names_gp = grid::gpar(fontsize = 25),
                        width = ncol(t(as.matrix(M)))*unit(6.5, "mm"), 
                        height = nrow(t(as.matrix(M)))*unit(20, "mm"))

ComplexHeatmap::Heatmap(t(as.matrix(exprs.M)), col=col,
                        row_names_gp = grid::gpar(fontsize = 30),
                        column_names_gp = grid::gpar(fontsize = 25),
                        width = ncol(t(as.matrix(exprs.M)))*unit(6.5, "mm"), 
                        height = nrow(t(as.matrix(exprs.M)))*unit(20, "mm"))
ComplexHeatmap::Heatmap(t(as.matrix(brs.M)), col=col,
                        row_names_gp = grid::gpar(fontsize = 30),
                        column_names_gp = grid::gpar(fontsize = 25),
                        width = ncol(t(as.matrix(brs.M)))*unit(6.5, "mm"), 
                        height = nrow(t(as.matrix(brs.M)))*unit(20, "mm"))
dev.off()

cors <- list(layer_cor=M, exprs_cor = exprs.M, sample_cor=brs.M)
saveRDS(cors, here("processed-data", "cindy", "NMF", model_type,
                    sprintf("%s-nmf-correlations-k%s.RDS", model_type, k)))

