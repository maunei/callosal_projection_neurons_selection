# =============================================================================
# Step 5. CPN clusters
# =============================================================================
# Step 4 retains single cells (3,004 cells sampled at E15.0-E18.0) that look like
# young E15-born superficial-layer neurons. They are spread over 30 atlas
# clusters, some with many retained cells and some with few. The figures need
# the CPN population followed across all atlas ages (E13.0-E18.0), which single
# retained cells cannot give, so the unit used downstream is the atlas cluster:
# all its cells, at every age. The question here is therefore which of the 30
# clusters, taken as a whole, are callosal projection neurons.
#
# To answer it, each cluster was looked at with ALL its atlas cells (any age, any
# dissection) in two dot plots, by cluster and age:
#   * CellCover panels (E15.1H, E15.24H, E15.96H): does the cluster carry the
#     late-born signature (E15.96H) rather than the younger ones? colour = mean
#     normalised expression averaged over the panel genes (log1p scale);
#     size = percentage of cells expressing a panel gene, averaged over the genes;
#   * markers Satb2 (CPN), Fezf2 and Bcl11b (deep layers): is it callosal and
#     not deep-layer? colour = mean normalised expression (log1p); size =
#     percentage of cells expressing.
# The CPN clusters were originally chosen by eye from these plots, as the clusters
# that combine two patterns no other cluster shows together:
#   * panels: a strong E15.96H signal (dark, large dots) with a weak E15.24H
#     signal and almost no E15.1H, and cells present mainly from E14.5-E15.0
#     on, as expected for E15-born neurons. Several clusters show the reverse
#     (E15.24H as strong as or stronger than E15.96H), Neur505 among them;
#   * markers: high Satb2 at every age with low Fezf2 and Bcl11b that fade with
#     age. Some clusters with a strong E15.96H signal fail here (e.g. Neur522:
#     high Fezf2; Neur518, Neur523-526: strong Fezf2 and/or Bcl11b).
# This script writes that visual choice as a rule; the thresholds were set to
# reproduce it (they were not fixed in advance). The CPN clusters are those
# that, over all their cells, show
#   1. callosal identity:      mean Satb2           >= 60
#   2. no deep-layer identity: mean Fezf2 + Bcl11b  <= 10
#   3. the late-born neuron signature: mean E15.96H coverage >= 0.40
#      (coverage = fraction of the E15.96H panel genes detected in a cell)
# Seven clusters pass conditions 1 and 2; condition 3 leaves out Neur505
# (mean Satb2 80.8, Fezf2 + Bcl11b 6.6, E15.96H coverage 0.378), giving the
# six CPN clusters Neur512-Neur517.
# Normalised expression = pooled count x size factor (step 1).
# Outputs: results/05_cpn_clusters/cluster_table.tsv (values and pass/fail per
#          cluster), cpn_clusters.tsv, dotplot_panels.png, dotplot_markers.png
# =============================================================================
source("scripts/_common.R")
suppressPackageStartupMessages(library(ggplot2))
sce <- load_atlas()
retained <- fread(RES("04_filtered_cells", "retained_clusters.tsv"))
panels <- fread(RES("03_cellcover_tests", "panels_used.tsv"))[in_atlas == TRUE]

MIN_SATB2     <- 60
MAX_DEEP      <- 10      # Fezf2 + Bcl11b
MIN_E15_96H   <- 0.40

clusters <- retained$ClusterName
cells <- which(sce$ClusterName %in% clusters)
info  <- data.table(cell = cells, ClusterName = sce$ClusterName[cells], Age = sce$Age[cells])
markers <- c("Satb2", "Fezf2", "Bcl11b", "Tbr1")
pg <- split(panels$gene, panels$panel)                      # E15.1H, E15.24H, E15.96H
X <- gene_counts(sce, unique(c(markers, unlist(pg))), cells, assay = "pooled")
E <- X * sce$size_factor_pooled[cells]                       # normalised expression

# --- per-cluster summary and selection rule ----------------------------------------
cov <- sapply(pg, function(g) rowMeans(X[, g, drop = FALSE] > 0))
per_cell <- data.table(info[, .(ClusterName)], E[, markers], cov)
tab <- per_cell[, c(.(cells = .N), lapply(.SD, mean)), by = ClusterName]
setnames(tab, c("E15.1H", "E15.24H", "E15.96H"), c("cov_E15.1H", "cov_E15.24H", "cov_E15.96H"))
tab <- merge(retained[, .(ClusterName, retained_cells = retained)], tab, by = "ClusterName")
tab[, deep := Fezf2 + Bcl11b]
tab[, `:=`(pass_satb2 = Satb2 >= MIN_SATB2, pass_deep = deep <= MAX_DEEP, pass_e15_96h = cov_E15.96H >= MIN_E15_96H)]
tab[, cpn := pass_satb2 & pass_deep & pass_e15_96h]
setorder(tab, -Satb2)
write_tsv(tab, RES("05_cpn_clusters", "cluster_table.tsv"))
cpn <- tab[cpn == TRUE, sort(ClusterName)]
write_tsv(data.table(ClusterName = cpn), RES("05_cpn_clusters", "cpn_clusters.tsv"))

# --- dot plots by cluster and age --------------------------------------------------
long <- melt(data.table(info[, .(ClusterName, Age)], E), id.vars = c("ClusterName", "Age"), variable.name = "gene")
agg  <- long[, .(mean_expr = mean(value), pct_expr = 100 * mean(value > 0)), by = .(ClusterName, Age, gene)]
lev_age <- ATLAS_AGES[ATLAS_AGES %in% agg$Age]
lev_cl  <- tab$ClusterName[order(tab$Satb2)]                 # highest Satb2 at the top
lab_cl  <- function(x) ifelse(x %in% cpn, paste0(x, "  [CPN]"), x)
dot <- function(d, colour, size, facet, title, size_lab, colour_lab) {
  d[, Age := factor(Age, lev_age)][, ClusterName := factor(ClusterName, lev_cl)]
  ggplot(d, aes(Age, ClusterName, colour = log1p(.data[[colour]]), size = .data[[size]])) +
    geom_point() + facet_wrap(as.formula(paste("~", facet)), nrow = 1) +
    scale_colour_gradient(low = "grey92", high = "black") + scale_size_area(max_size = 4) +
    scale_y_discrete(labels = lab_cl) + theme_bw(9) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1), strip.text = element_text(face = "bold")) +
    labs(x = "Age", y = NULL, colour = colour_lab, size = size_lab, title = title)
}
pm <- agg[gene %in% c("Fezf2", "Bcl11b", "Satb2")][, gene := factor(gene, c("Fezf2", "Bcl11b", "Satb2"))]
ggsave(RES("05_cpn_clusters", "dotplot_markers.png"),
       dot(pm, "mean_expr", "pct_expr", "gene", "Markers by cluster and age (all cells of each cluster)",
           "% cells expressing", "mean expression (log1p)"), width = 11, height = 0.22 * length(lev_cl) + 1.6, dpi = 150)
gmap <- rbindlist(lapply(names(pg), function(p) data.table(panel = p, gene = pg[[p]])))
pp <- merge(agg, gmap, by = "gene", allow.cartesian = TRUE)[, .(mean_over_genes = mean(mean_expr), pct_over_genes = mean(pct_expr)),
                                                           by = .(ClusterName, Age, panel)]
pp[, panel := factor(panel, c("E15.1H", "E15.24H", "E15.96H"))]
ggsave(RES("05_cpn_clusters", "dotplot_panels.png"),
       dot(pp, "mean_over_genes", "pct_over_genes", "panel", "CellCover panels by cluster and age (all cells of each cluster)",
           "% cells expressing (mean over genes)", "mean over genes (log1p)"), width = 11, height = 0.22 * length(lev_cl) + 1.6, dpi = 150)
log_msg("step 5 done:", length(cpn), "CPN clusters:", paste(cpn, collapse = ", "))
