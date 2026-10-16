# =============================================================================
# Step 7. Figures: expression by age (Fig. 4a and Extended Data Fig. 4a)
# =============================================================================
# Mean normalised expression +/- SEM by age, for the ages at which the CPN
# clusters contain cells.
#   fig4a.png      Ephb2, Satb2, Fezf2, Eomes in the CPN clusters
#   extfig4a.png   Eph receptors, CPN markers, progenitor and deep-layer markers
#                  in the CPN clusters, and Ephb2 in the three comparison groups
# The data behind each figure are written next to it (.tsv).
# =============================================================================
source("scripts/_common.R")
suppressPackageStartupMessages(library(ggplot2))
pg <- fread(RES("06_expression", "expression_per_group.tsv"))
ages <- pg[group == "cpn_clusters" & n_cells > 0, unique(Age)]
ages <- ATLAS_AGES[ATLAS_AGES %in% ages]
pg <- pg[Age %in% ages][, Age := factor(Age, ages, sub("e", "E", ages))]

draw <- function(d, ncol, title) {
  ggplot(d, aes(Age, mean_norm, group = 1, colour = colour)) + geom_line() + geom_point(size = 1.3) +
    geom_errorbar(aes(ymin = pmax(mean_norm - sem_norm, 0), ymax = mean_norm + sem_norm), width = 0.3, colour = "black") +
    facet_wrap(~panel, scales = "free_y", ncol = ncol) + expand_limits(y = 0) + scale_colour_identity() +
    theme_bw(9) + theme(axis.text.x = element_text(angle = 45, hjust = 1), strip.text = element_text(face = "italic")) +
    labs(x = NULL, y = "Mean expression (± SEM)", title = title)
}
COL <- c(eph = "#009E73", cpn = "#D55E00", prog = "#0072B2", deep = "#CC79A7", other = "grey40")

f4 <- pg[group == "cpn_clusters" & Gene %in% c("Ephb2", "Satb2", "Fezf2", "Eomes")]
f4[, panel := factor(Gene, c("Ephb2", "Satb2", "Fezf2", "Eomes"))]
f4[, colour := COL[c(Ephb2 = "eph", Satb2 = "cpn", Fezf2 = "deep", Eomes = "prog")[as.character(Gene)]]]
ggsave(RES("07_figures", "fig4a.png"), draw(f4, 2, "Gene expression in CPN clusters"), width = 6, height = 4.6, dpi = 200)
write_tsv(f4, RES("07_figures", "fig4a_data.tsv"))

kind <- c(Ephb2 = "eph", Ephb1 = "eph", Ephb3 = "eph", Epha3 = "eph", Epha4 = "eph", Satb2 = "cpn", Cux2 = "cpn",
          L1cam = "cpn", Eomes = "prog", Pax6 = "prog", Fezf2 = "deep", Bcl11b = "deep")
e1 <- pg[group == "cpn_clusters" & Gene %in% names(kind)][, panel := as.character(Gene)]
e2 <- pg[Gene == "Ephb2" & group != "cpn_clusters"]
e2[, panel := c(forebrain_neurons = "Ephb2: forebrain neurons", forebrain_radial_glia = "Ephb2: forebrain radial glia",
                forebrain_neuroblasts = "Ephb2: forebrain neuroblasts")[group]]
ef <- rbind(e1, e2)
ef[, colour := fifelse(group == "cpn_clusters", COL[kind[as.character(Gene)]], COL[["other"]])]
ef[, panel := factor(panel, c(names(kind), "Ephb2: forebrain neurons", "Ephb2: forebrain radial glia", "Ephb2: forebrain neuroblasts"))]
ggsave(RES("07_figures", "extfig4a.png"), draw(ef, 5, "Expression in CPN clusters (first 12 panels) and Ephb2 in comparison groups"),
       width = 12, height = 7, dpi = 200)
write_tsv(ef, RES("07_figures", "extfig4a_data.tsv"))
log_msg("step 7 done")
