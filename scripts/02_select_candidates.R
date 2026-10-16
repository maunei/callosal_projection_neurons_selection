# =============================================================================
# Step 2. Candidate cells
# =============================================================================
# Callosal projection neurons (CPNs) are excitatory neurons of the cortex. Most
# are born around E15 and settle in the superficial layers. As candidates we take
#   * cells dissected from the dorsal forebrain (the future cortex),
#   * belonging to atlas clusters 492-797 (the clusters annotated as neurons),
#   * sampled between E15.0 and E18.0, when E15-born neurons exist as young
#     postmitotic neurons.
# Output: results/02_candidates/candidates.tsv (one row per candidate cell)
# =============================================================================
source("scripts/_common.R")
sce <- load_atlas()

CANDIDATE_TISSUE   <- "ForebrainDorsal"
CANDIDATE_CLUSTERS <- 492:797
CANDIDATE_AGES     <- c("e15.0", "e15.5", "e16.0", "e16.25", "e16.5", "e17.0", "e17.5", "e18.0")

cd <- as.data.table(as.data.frame(colData(sce)[, c("CellID", "Age", "Tissue", "Class", "Subclass",
                                                    "ClusterName", "Clusters", "IsCycling")]))
cd[, cell := .I]                                  # column index in the atlas object
cand <- cd[Tissue == CANDIDATE_TISSUE & Clusters %in% CANDIDATE_CLUSTERS & Age %in% CANDIDATE_AGES]
write_tsv(cand, RES("02_candidates", "candidates.tsv"))
log_msg("step 2 done:", nrow(cand), "candidate cells in", uniqueN(cand$ClusterName), "clusters")
