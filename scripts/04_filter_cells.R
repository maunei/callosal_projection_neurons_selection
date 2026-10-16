# =============================================================================
# Step 4. Cells with the signature of young, superficial-layer cortical neurons
# =============================================================================
# A candidate cell is retained if
#   * it expresses at least one CPN marker (Satb2, Pou3f2 or Trim67),
#   * it is not cycling (atlas annotation IsCycling == 0),
#   * its E15.96H genes exceed its E15.24H genes: p_24h <= 0.05 / number of
#     candidates (Bonferroni over cells), i.e. it has passed the migrating stage,
#   * its E15.96H genes exceed its deep-layer markers (p_deep <= 0.05), or no
#     deep-layer marker is detected in it,
#   * it belongs to the atlas subclass "Cortical or hippocampal glutamatergic".
# Outputs: results/04_filtered_cells/retained_cells.tsv, filter_steps.tsv,
#          retained_clusters.tsv
# =============================================================================
source("scripts/_common.R")
cand  <- fread(RES("02_candidates", "candidates.tsv"))
tests <- fread(RES("03_cellcover_tests", "cell_tests.tsv.gz"), colClasses = list(character = "pos_markers"))
d <- merge(cand, tests[, !"CellID"], by = "cell")
d[is.na(pos_markers), pos_markers := ""]

ALPHA_24H   <- 0.05 / nrow(d)
ALPHA_DEEP  <- 0.05
SUBCLASS    <- "Cortical or hippocampal glutamatergic"

d[, f_marker   := pos_markers != ""]
d[, f_cycling  := IsCycling == 0]
d[, f_24h      := !is.na(p_24h) & p_24h <= ALPHA_24H]
d[, f_deep     := is.na(p_deep) | p_deep <= ALPHA_DEEP]
d[, f_subclass := Subclass == SUBCLASS]
d[, retained   := f_marker & f_cycling & f_24h & f_deep & f_subclass]

steps <- data.table(
  step = c("candidates", "+ CPN marker", "+ not cycling", "+ E15.96H > E15.24H", "+ E15.96H > deep layer", "+ glutamatergic subclass"),
  cells = c(nrow(d), d[, sum(f_marker)], d[, sum(f_marker & f_cycling)], d[, sum(f_marker & f_cycling & f_24h)],
            d[, sum(f_marker & f_cycling & f_24h & f_deep)], d[, sum(retained)]))
write_tsv(steps, RES("04_filtered_cells", "filter_steps.tsv"))
write_tsv(d, RES("04_filtered_cells", "all_candidates_with_filters.tsv"))
write_tsv(d[retained == TRUE, .(cell, CellID, ClusterName, Age, pos_markers, p_24h, p_deep)], RES("04_filtered_cells", "retained_cells.tsv"))
write_tsv(d[, .(candidates = .N, retained = sum(retained)), by = ClusterName][retained > 0][order(-retained)],
          RES("04_filtered_cells", "retained_clusters.tsv"))
log_msg("step 4 done:", d[, sum(retained)], "cells retained in", d[retained == TRUE, uniqueN(ClusterName)], "clusters")
