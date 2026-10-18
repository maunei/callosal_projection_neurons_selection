# Validation

`expected/soon_gene_norm_stats4.xlsx` is the table from which the manuscript's line plots of expression by age (the main and extended figures, see the main README) were drawn. The analysis does not read it. It is only the reference that the workflow's own table is compared with.

The line plots of the manuscript (mean ± SEM by age) are drawn from the `grouped_chosen_Clusters` tab. Because that tab is reproduced, so are the plotted values. Step 7 draws the same plots from the workflow's table (`results/07_figures/`, with the plotted values in the `*_data.tsv` files). The plots can also be redrawn from the Excel file (`grouped_chosen_Clusters` tab).

## Which workflow file corresponds to it

The workflow writes the equivalent table to **`results/06_expression/expression_by_age.xlsx`**. The two files have the same tabs, rows and statistics:

| Tab (same name in both files) | One row per | Rows | Also written by the workflow as |
|---|---|---|---|
| `full_resolution` | gene × atlas cluster × age | 46,800 | `results/06_expression/expression_per_cluster.tsv` |
| `grouped_chosen_Clusters` | gene × group × age | 1,040 | `results/06_expression/expression_per_group.tsv` |

## Differences in names only

The column that gives the group is called `Soon_chosen_Clusters` in the expected file and `group` in the workflow's file. Group names differ as follows:

| Expected file (`Soon_chosen_Clusters`) | Workflow (`group`) | Clusters |
|---|---|---|
| `soon_chosen_callosal_clusters` | `cpn_clusters` | the six CPN clusters (Neur512–Neur517) |
| `soon_chosen_Neuron_clusters_1` | `forebrain_neurons` | 120 forebrain neuron clusters |
| `soon_chosen_RGC_clusters_clusters` | `forebrain_radial_glia` | 32 forebrain radial glia clusters |
| `soon_chosen_neuroblast_clusters` | `forebrain_neuroblasts` | 28 forebrain neuroblast clusters |

The clusters in each group are listed in `results/06_expression/group_clusters.tsv`. In `full_resolution`, a cluster that belongs to several groups has its groups separated by commas. All other columns have the same names and meaning in both files:

- `Gene` and `Accession`: the gene.
- `Class`, `Subclass` and `ClusterName`: the atlas annotation.
- `Age`: the atlas age.
- `n_cells`: the number of cells.
- `n_pos`: the number of cells with at least one count (pooled count) of the gene.
- `mean_norm`, `sd_norm` and `sem_norm`: the mean, standard deviation and standard error of the mean of normalised expression.

## The comparison

`check_against_expected.R` reads both files and renames the expected groups as in the table above. It then matches rows on their keys: `Gene`, `ClusterName` and `Age` in `full_resolution`, and `Gene`, group and `Age` in `grouped_chosen_Clusters`. The check requires that:

- both files have the same number of rows and every row is matched;
- `n_cells` and `n_pos` are equal;
- `mean_norm`, `sd_norm` and `sem_norm` agree within a relative tolerance of 1e-9 (missing values must be missing in both files).

Run it with `bash run_all.sh --validate` or the Snakemake target `validate`. The result goes to `results/validation/validation_report.txt`, with one PASS or FAIL per tab and an overall verdict.
