# =============================================================================
# Step 3. CellCover panel signatures and Wilcoxon tests for each candidate cell
# =============================================================================
# CellCover panels (Ji et al., eLife 2026) are small sets of marker genes that
# together "cover" a cell state. The twelve panels used here were derived from the
# FlashTag time course of Telley et al. (Science 2019): neocortical progenitors
# dividing at E12-E15 were labelled and their progeny profiled 1 h (progenitors),
# 24 h (migrating neuroblasts) and 96 h (young neurons) later. The E15 panels
# describe the late-born lineage that gives the superficial layers:
#     E15.96H   young neurons born at E15  (signature we look for)
#     E15.24H   neuroblasts still migrating (state to exclude)
#     E15.1H    progenitors                 (state to exclude)
# plus the deep-layer markers Tbr1, Bcl11b, Fezf2 (identity to exclude) and the
# CPN markers Satb2, Pou3f2, Trim67 (identity required in step 4).
#
# For each candidate cell:
#   1. detected genes = genes with a count > 0 in the cell (pooled counts), for
#      each panel and marker set;
#   2. three one-sided Wilcoxon rank-sum tests ask whether the E15.96H genes
#      detected in the cell are expressed at higher levels, across the candidate
#      population, than the comparison genes detected in the same cell:
#        p_24h  : E15.96H genes vs E15.24H genes
#        p_1h   : E15.96H genes vs E15.1H genes
#        p_deep : E15.96H genes vs deep-layer markers
#      The values compared are the counts of those genes in all candidate cells.
#      A test is NA when one of the two gene sets is empty in the cell.
# The test is computed exactly as wilcox.test(x, y, alternative = "greater") with
# its normal approximation (tie and continuity corrections), from frequency
# tables of counts, which is fast for vectors of ~10^6 values.
# Outputs: results/03_cellcover_tests/cell_tests.tsv.gz, panels_used.tsv
# =============================================================================
source("scripts/_common.R")
sce  <- load_atlas()
cand <- fread(RES("02_candidates", "candidates.tsv"))

POS_MARKERS  <- c("Satb2", "Pou3f2", "Trim67")       # CPN markers
DEEP_MARKERS <- c("Tbr1", "Bcl11b", "Fezf2")         # deep-layer projection neuron markers

pan <- read_panels()
pan[, in_atlas := gene %in% rowData(sce)$Gene]
SETS <- list(e15_96h = pan[panel == "E15.96H" & in_atlas, gene],
             e15_24h = pan[panel == "E15.24H" & in_atlas, gene],
             e15_1h  = pan[panel == "E15.1H"  & in_atlas, gene],
             deep    = DEEP_MARKERS, pos = POS_MARKERS)
write_tsv(pan[panel %in% c("E15.96H", "E15.24H", "E15.1H")], RES("03_cellcover_tests", "panels_used.tsv"))

X <- gene_counts(sce, unique(unlist(SETS)), cand$cell, assay = "pooled")   # candidates x genes

# frequency table of each gene's counts over the candidates
ftab <- lapply(colnames(X), function(g) { t <- table(X[, g]); data.table(v = as.numeric(names(t)), n = as.numeric(t)) })
names(ftab) <- colnames(X)

# one-sided rank-sum test of genes `ga` vs genes `gb`, values over all candidates
wilcox_greater <- function(ga, gb) {
  if (!length(ga) || !length(gb)) return(NA_real_)
  a <- rbindlist(ftab[ga])[, .(na = sum(n)), by = v]
  b <- rbindlist(ftab[gb])[, .(nb = sum(n)), by = v]
  m <- merge(a, b, by = "v", all = TRUE); m[is.na(na), na := 0]; m[is.na(nb), nb := 0]; setorder(m, v)
  m[, t := na + nb][, r := cumsum(t) - (t - 1) / 2]                # mid-ranks of tied values
  nx <- sum(m$na); ny <- sum(m$nb); N <- nx + ny
  W  <- sum(m$na * m$r) - nx * (nx + 1) / 2
  sd <- sqrt((nx * ny / 12) * ((N + 1) - sum(m$t^3 - m$t) / (N * (N - 1))))
  pnorm((W - nx * ny / 2 - 0.5) / sd, lower.tail = FALSE)
}
detected <- function(i, genes) genes[X[i, genes] > 0]

one_cell <- function(i) {
  d <- lapply(SETS, function(g) detected(i, g))
  list(cell = cand$cell[i], n_96h = length(d$e15_96h), n_24h = length(d$e15_24h), n_1h = length(d$e15_1h),
       n_deep = length(d$deep), pos_markers = paste(d$pos, collapse = ","),
       p_24h = wilcox_greater(d$e15_96h, d$e15_24h), p_1h = wilcox_greater(d$e15_96h, d$e15_1h),
       p_deep = wilcox_greater(d$e15_96h, d$deep))
}
res <- rbindlist(parallel::mclapply(seq_len(nrow(cand)), one_cell, mc.cores = CFG$threads))
fwrite(merge(cand[, .(cell, CellID)], res, by = "cell"), RES("03_cellcover_tests", "cell_tests.tsv.gz"), sep = "\t")
log_msg("step 3 done:", nrow(res), "cells tested")
