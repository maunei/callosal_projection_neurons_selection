# =============================================================================
# _common.R : shared set-up for every step of the CPN-selection workflow
# =============================================================================
# Every step script starts with   source("scripts/_common.R")   and is run from
# the workflow folder by scripts/run_r.sh (which passes the config file).
#
# Provides:
#   CFG                  settings from config/config.yaml (paths, threads)
#   RES(step, file)      path of an output file of a step, folder created on demand
#   load_atlas()         the La Manno atlas as a SingleCellExperiment (step 1 output)
#   gene_counts()        counts of selected genes for selected cells (dense matrix)
#   read_panels()        the twelve CellCover panels as a long table
#   ATLAS_AGES           atlas ages in developmental order
#   log_msg(), write_tsv()
# =============================================================================

ROOT <- getwd()
renv::load(file.path(ROOT, "envs", "r"), quiet = TRUE)    # workflow's own R library

suppressPackageStartupMessages({
  library(SingleCellExperiment)
  library(HDF5Array)
  library(data.table)
  library(Matrix)
})

args <- commandArgs(trailingOnly = TRUE)
CFG  <- yaml::read_yaml(if (length(args)) args[1] else "config/config.yaml")
CFG$atlas_loom       <- normalizePath(CFG$atlas_loom, mustWork = TRUE)
CFG$cellcover_panels <- normalizePath(CFG$cellcover_panels, mustWork = TRUE)
setDTthreads(CFG$threads)

RES <- function(step, file = NULL) {
  d <- file.path(ROOT, CFG$results_dir, step)
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  if (is.null(file)) d else file.path(d, file)
}

log_msg   <- function(...) cat(format(Sys.time(), "%H:%M:%S"), ..., "\n")
write_tsv <- function(x, path) fwrite(x, path, sep = "\t", na = "NA")

# Ages sampled in the atlas, in developmental order (labels as in the atlas).
ATLAS_AGES <- c("e7.0", "e8.0", "e8.5", "e9.0", "e10.0", "e11.0", "e12.0", "e12.5", "e13.0",
                "e13.5", "e14.0", "e14.5", "e15.0", "e15.5", "e16.0", "e16.25", "e16.5",
                "e17.0", "e17.5", "e18.0")

# --- atlas object --------------------------------------------------------------
# Step 1 saves a lightweight SingleCellExperiment: cell and gene annotations in
# memory, count matrices read on demand from the loom file. If the loom file is
# moved, the object follows the path given in config/config.yaml.
load_atlas <- function() {
  sce <- readRDS(RES("01_atlas", "atlas_sce.rds"))
  if (path(assay(sce, 1, withDimnames = FALSE)) != CFG$atlas_loom) {     # loom file moved: re-link
    ds <- metadata(sce)$loom_datasets
    for (a in names(ds)) assay(sce, a, withDimnames = FALSE) <- t(HDF5Array(CFG$atlas_loom, ds[[a]]))
  }
  sce
}

# Counts of `genes` (symbols) for `cells` (column indices) from assay `assay`,
# returned as a dense matrix cells x genes. Gene symbols must be unique in the atlas.
gene_counts <- function(sce, genes, cells = seq_len(ncol(sce)), assay = "pooled") {
  i <- match(genes, rowData(sce)$Gene)
  if (anyNA(i)) stop("genes not in the atlas: ", paste(genes[is.na(i)], collapse = ", "))
  m <- t(as.matrix(assay(sce, assay, withDimnames = FALSE)[i, cells, drop = FALSE]))
  colnames(m) <- genes
  m
}

# --- CellCover panels ----------------------------------------------------------
# Each panel file lists 337 genes with 1 (in the panel) or 0. File names give the
# panel: E<day>.<hours>H, e.g. E15.96H = cells 96 h after their last division at E15.
read_panels <- function() {
  f <- list.files(CFG$cellcover_panels, pattern = "^[0-9]{2}_E1[2-5]\\.[0-9]+H\\.txt$", full.names = TRUE)
  rbindlist(lapply(f, function(x) {
    p <- fread(x, header = FALSE, col.names = c("gene", "member"))
    p[member == 1, .(panel = sub("^[0-9]{2}_(.*)\\.txt$", "\\1", basename(x)), gene)]
  }))
}
