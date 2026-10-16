# =============================================================================
# Validation (not part of the analysis): compare the table produced by the
# workflow, results/06_expression/expression_by_age.xlsx, with the expected
# table validation/expected/soon_gene_norm_stats4.xlsx (the published export).
# Rows are matched on their keys; counts must be equal and statistics equal
# within a relative tolerance of 1e-9. Group names of the expected table map to
# the workflow's group names as listed below.
# Output: results/validation/validation_report.txt (PASS / FAIL)
# =============================================================================
source("scripts/_common.R")
EXPECTED <- file.path(ROOT, "validation", "expected", "soon_gene_norm_stats4.xlsx")
GROUP_NAMES <- c(soon_chosen_callosal_clusters = "cpn_clusters", soon_chosen_Neuron_clusters_1 = "forebrain_neurons",
                 soon_chosen_RGC_clusters_clusters = "forebrain_radial_glia", soon_chosen_neuroblast_clusters = "forebrain_neuroblasts")
ours <- RES("06_expression", "expression_by_age.xlsx")
rd <- function(f, s) as.data.table(readxl::read_excel(f, sheet = s))
rename_groups <- function(x) vapply(strsplit(x, ","), function(v) paste(GROUP_NAMES[v], collapse = ","), "")
TOL <- 1e-9
same_num <- function(a, b) (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & abs(a - b) <= TOL * pmax(1, abs(a)))
check <- function(sheet, keys, group_col) {
  e <- rd(EXPECTED, sheet); o <- rd(ours, sheet)
  setnames(e, group_col, "group"); e[, group := rename_groups(group)]
  m <- merge(e, o, by = keys, suffixes = c("_exp", "_ours"))
  ok_rows <- nrow(m) == nrow(e) && nrow(m) == nrow(o)
  r <- list(rows_expected = nrow(e), rows_ours = nrow(o), rows_matched = nrow(m),
            n_cells_equal = sum(m$n_cells_exp == m$n_cells_ours), n_pos_equal = sum(m$n_pos_exp == m$n_pos_ours))
  for (v in c("mean_norm", "sd_norm", "sem_norm")) r[[paste0(v, "_equal")]] <- sum(same_num(m[[paste0(v, "_exp")]], m[[paste0(v, "_ours")]]))
  r$pass <- ok_rows && all(unlist(r[grep("_equal$", names(r))]) == nrow(m))
  c(sheet = sheet, r)
}
res <- list(check("full_resolution", c("Gene", "ClusterName", "Age"), "Soon_chosen_Clusters"),
            check("grouped_chosen_Clusters", c("Gene", "group", "Age"), "Soon_chosen_Clusters"))
out <- unlist(lapply(res, function(r) c(sprintf("[%s] %s", if (r$pass) "PASS" else "FAIL", r$sheet),
                                         sprintf("    %s: %s", names(r)[-1], unlist(r[-1])))))
out <- c(out, sprintf("OVERALL: %s", if (all(vapply(res, `[[`, TRUE, "pass"))) "PASS - the expected table is reproduced" else "FAIL"))
writeLines(out, RES("validation", "validation_report.txt")); cat(out, sep = "\n")
