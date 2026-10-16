# =============================================================================
# Step 6. Expression by age in CPN clusters and in comparison groups
# =============================================================================
# Groups of clusters:
#   cpn_clusters           the CPN clusters selected in step 5
#   forebrain_neurons      all clusters of class Neuron, subclasses
#                          cortical or hippocampal glutamatergic, forebrain glutamatergic,
#                          forebrain GABAergic (includes the CPN clusters)
#   forebrain_radial_glia  all clusters of class Radial glia, subclasses
#                          dorsal forebrain, forebrain, cortical hem
#   forebrain_neuroblasts  all clusters of class Neuroblast, subclasses
#                          forebrain, forebrain glutamatergic, forebrain GABAergic
# Every atlas cell of these clusters is used, whatever its age or dissection.
# For each gene, the normalised expression of a cell is its pooled count x size
# factor (step 1). For every age of the atlas we report
#   n_cells (cells; the same for every gene), n_pos (cells in which this gene has
#   expression > 0), mean_norm, sd_norm and
#   sem_norm = sd_norm / sqrt(n_cells)   (sd and sem need at least 2 cells).
# Outputs (results/06_expression/):
#   expression_by_age.xlsx   tab full_resolution: per cluster and age
#                            tab grouped_chosen_Clusters: per group and age
#   expression_per_cluster.tsv, expression_per_group.tsv (same tables)
#   group_clusters.tsv       clusters of each group
#   expression_sce.rds       SingleCellExperiment of all cells of the groups for the
#                            genes below: pooled counts and normalised values,
#                            cell annotations and group membership
# =============================================================================
source("scripts/_common.R")
sce <- load_atlas()

GENES <- c("Bcl11b", "Cux2", "Eomes", "Epha3", "Epha4", "Ephb1", "Ephb2", "Ephb3",
           "Fezf2", "L1cam", "Pax6", "Satb2", "Tbr1")
GROUP_DEFINITIONS <- list(
  forebrain_neurons     = list(class = "Neuron", subclass = c("Cortical or hippocampal glutamatergic", "Forebrain glutamatergic", "Forebrain GABAergic")),
  forebrain_radial_glia = list(class = "Radial glia", subclass = c("Dorsal forebrain", "Forebrain", "Cortical hem")),
  forebrain_neuroblasts = list(class = "Neuroblast", subclass = c("Forebrain", "Forebrain glutamatergic", "Forebrain GABAergic")))

ann <- as.data.table(as.data.frame(colData(sce)[, c("CellID", "Age", "Class", "Subclass", "ClusterName")]))
ann[, cell := .I]
clusters_of <- function(def) ann[Class == def$class & Subclass %in% def$subclass, sort(unique(ClusterName))]
groups <- c(list(cpn_clusters = fread(RES("05_cpn_clusters", "cpn_clusters.tsv"))$ClusterName),
            lapply(GROUP_DEFINITIONS, clusters_of))
gc <- rbindlist(lapply(names(groups), function(g) data.table(group = g, ClusterName = groups[[g]])))
write_tsv(gc, RES("06_expression", "group_clusters.tsv"))

# normalised expression of all cells of all groups
cells <- ann[ClusterName %in% gc$ClusterName, cell]
counts <- gene_counts(sce, GENES, cells, assay = "pooled")
norm <- counts * sce$size_factor_pooled[cells]
acc <- setNames(rowData(sce)$Accession[match(GENES, rowData(sce)$Gene)], GENES)
long <- melt(data.table(ann[cells, .(ClusterName, Age)], norm), id.vars = c("ClusterName", "Age"),
             variable.name = "Gene", value.name = "x", variable.factor = FALSE)
stats <- function(x) list(n_cells = length(x), n_pos = sum(x > 0),
                          mean_norm = if (length(x)) mean(x) else NA_real_,
                          sd_norm = if (length(x) > 1) sd(x) else NA_real_)
all_ages <- function(dt, keys) {   # one row for every key x age, n_cells = 0 where no cell
  grid <- unique(dt[, ..keys])[, .(Age = ATLAS_AGES), by = keys]
  dt <- merge(grid, dt, by = c(keys, "Age"), all.x = TRUE)
  dt[is.na(n_cells), `:=`(n_cells = 0L, n_pos = 0L)][, sem_norm := sd_norm / sqrt(n_cells)]
  dt[, Age := factor(Age, ATLAS_AGES)]
}

# tab 1: per cluster and age
membership <- gc[, .(group = paste(group, collapse = ",")), by = ClusterName]
cl_info <- unique(ann[cells, .(ClusterName, Class, Subclass)])
pc <- long[, stats(x), by = .(Gene, ClusterName, Age)]
pc <- all_ages(pc, c("Gene", "ClusterName"))
pc <- merge(merge(pc, cl_info, by = "ClusterName"), membership, by = "ClusterName")
pc[, Accession := acc[Gene]]
setcolorder(pc, c("Gene", "Accession", "Class", "Subclass", "ClusterName", "group", "Age",
                  "n_cells", "n_pos", "mean_norm", "sd_norm", "sem_norm"))
setorder(pc, Gene, Class, Subclass, ClusterName, Age)

# tab 2: per group and age (cells pooled over the group's clusters)
pg <- rbindlist(lapply(names(groups), function(g) {
  d <- long[ClusterName %in% groups[[g]]]
  s <- d[, stats(x), by = .(Gene, Age)]
  lab <- ann[cells][ClusterName %in% groups[[g]], .(Class = paste(sort(unique(Class)), collapse = ","),
                                                     Subclass = paste(sort(unique(Subclass)), collapse = ",")), by = Age]
  s <- merge(s, lab, by = "Age")
  s[, group := g]
}))
pg <- all_ages(pg, c("Gene", "group"))
pg[, Accession := acc[Gene]]
setcolorder(pg, c("Gene", "Accession", "group", "Class", "Subclass", "Age",
                  "n_cells", "n_pos", "mean_norm", "sd_norm", "sem_norm"))
pg[, group := factor(group, names(groups))]; setorder(pg, Gene, group, Age)

write_tsv(pc, RES("06_expression", "expression_per_cluster.tsv"))
write_tsv(pg, RES("06_expression", "expression_per_group.tsv"))
writexl::write_xlsx(list(full_resolution = pc[, Age := as.character(Age)],
                         grouped_chosen_Clusters = pg[, `:=`(Age = as.character(Age), group = as.character(group))]),
                    RES("06_expression", "expression_by_age.xlsx"))

# expression object for further work
cd <- colData(sce)[cells, ]
for (g in names(groups)) cd[[paste0("in_", g)]] <- cd$ClusterName %in% groups[[g]]
ex <- SingleCellExperiment(assays = list(counts = t(counts), normalised = t(norm)),
                           colData = cd, rowData = rowData(sce)[match(GENES, rowData(sce)$Gene), ])
rownames(ex) <- GENES
saveRDS(ex, RES("06_expression", "expression_sce.rds"))
log_msg("step 6 done:", nrow(pc), "cluster rows,", nrow(pg), "group rows,", length(cells), "cells in the groups")
