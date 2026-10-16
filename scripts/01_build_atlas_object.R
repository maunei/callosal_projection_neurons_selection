# =============================================================================
# Step 1. The La Manno atlas as an R object
# =============================================================================
# The atlas (La Manno et al. 2021, Nature 596:92-96) is a loom file: an HDF5 file
# holding count matrices of 292,495 cells x 31,053 genes and per-cell / per-gene
# annotations. This step builds a SingleCellExperiment that
#   * keeps every cell annotation (age, dissected region, class, subclass,
#     cluster, cycling status, sample, ...) as colData and gene annotations as rowData;
#   * links the count matrices of the loom file without copying them (HDF5Array):
#       raw       unique-molecule counts of each cell (main matrix of the loom)
#       pooled    counts summed over each cell's nearest neighbours in the atlas;
#                 this smoothed layer is the one used by the analysis
#       spliced, unspliced, expected   other layers of the loom, kept for completeness
#   * adds per-cell library sizes and median-scaling size factors for the raw and
#     pooled matrices, computed over the whole atlas:
#       size_factor = median(total counts of all cells) / total counts of the cell
#     The analysis uses the pooled ones: normalised expression in later steps =
#     pooled count x size_factor_pooled, where the total is the sum of the cell's
#     pooled values over all genes. The raw size factors are stored but not used.
# Output: results/01_atlas/atlas_sce.rds (about 150 MB of annotations and embeddings;
#         the counts stay in the loom file, which must remain available)
# =============================================================================
source("scripts/_common.R")
suppressPackageStartupMessages(library(rhdf5))
loom <- CFG$atlas_loom

# --- annotations -----------------------------------------------------------------
read_group <- function(group, n) {
  nm <- h5ls(loom)[h5ls(loom)$group == paste0("/", group), "name"]
  vals <- lapply(nm, function(a) { x <- h5read(loom, paste0(group, "/", a)); if (is.raw(x)) x <- as.integer(x); x })
  names(vals) <- nm
  is_vec <- vapply(vals, function(x) is.null(dim(x)) || length(dim(x)) == 1, TRUE) &
            vapply(vals, length, 1L) == n
  list(vectors = lapply(vals[is_vec], as.vector),
       matrices = vals[!is_vec & vapply(vals, function(x) !is.null(dim(x)) && n %in% dim(x), TRUE)])
}
gene <- as.vector(h5read(loom, "row_attrs/Gene"))
cell <- as.vector(h5read(loom, "col_attrs/CellID"))
ca <- read_group("col_attrs", length(cell))
ra <- read_group("row_attrs", length(gene))
H5close()
col_data <- DataFrame(ca$vectors, row.names = cell, check.names = FALSE)
row_data <- DataFrame(ra$vectors, row.names = make.unique(gene), check.names = FALSE)
log_msg("annotations:", ncol(col_data), "cell attributes,", ncol(row_data), "gene attributes")

# --- count matrices, linked lazily (stored cells x genes in the file) -------------
layers <- c(raw = "matrix", pooled = "layers/pooled", spliced = "layers/spliced",
            unspliced = "layers/unspliced", expected = "layers/expected")
assays_list <- lapply(layers, function(ds) t(HDF5Array(loom, ds)))     # genes x cells
sce <- SingleCellExperiment(assays = assays_list, colData = col_data, rowData = row_data)
metadata(sce)$loom_datasets <- layers          # used by load_atlas() to re-link the matrices

# reduced dimensions stored in the loom (2-D cell attributes): embeddings (t-SNE,
# UMAP, PCA) are kept; the 96-dimensional HPF model matrices of the atlas pipeline
# are left in the loom file (they would add ~0.5 GB to the object).
for (nm in setdiff(names(ca$matrices), c("HPF", "HPF_theta"))) {
  m <- ca$matrices[[nm]]; if (nrow(m) != ncol(sce)) m <- t(m)
  reducedDim(sce, nm) <- m
}

# --- library sizes and size factors (one pass over each matrix, by blocks) -------
n <- ncol(sce); blocks <- split(seq_len(n), ceiling(seq_len(n) / 10000))
for (a in c("raw", "pooled")) {
  tot <- numeric(n)
  for (b in blocks) tot[b] <- rowSums(h5read(loom, layers[[a]], index = list(b, NULL)))
  H5close()
  colData(sce)[[paste0("total_", a)]]       <- tot
  colData(sce)[[paste0("size_factor_", a)]] <- median(tot) / tot
  log_msg(a, "counts: median total per cell", median(tot))
}

# base::saveRDS on purpose: the object stores links to the loom file, not the counts
# (load it with load_atlas() in scripts/_common.R, which points the links to the loom
# file given in config/config.yaml).
base::saveRDS(sce, RES("01_atlas", "atlas_sce.rds"))
writeLines(c(
  sprintf("cells: %d   genes: %d", ncol(sce), nrow(sce)),
  sprintf("assays: %s", paste(assayNames(sce), collapse = ", ")),
  sprintf("reduced dimensions: %s", paste(reducedDimNames(sce), collapse = ", ")),
  sprintf("median total counts per cell: raw %s, pooled %s",
          median(sce$total_raw), median(sce$total_pooled)),
  sprintf("cell attributes: %s", paste(colnames(colData(sce)), collapse = ", "))),
  RES("01_atlas", "atlas_summary.txt"))
log_msg("step 1 done")
