# Callosal projection neurons in the developing mouse brain atlas

This workflow identifies clusters of callosal projection neurons (CPNs) in the La Manno et al. (2021) single-cell atlas of the developing mouse brain. It then measures, age by age, the expression of *Ephb2* and of marker genes in these clusters and in comparison groups. These are the data of Fig. 4a and Extended Data Fig. 4a of the EPHB2 manuscript.

Sections marked ▸ open on a click. They explain the ideas taken from the papers the method rests on: the atlas (La Manno et al. 2021), the FlashTag birth-dating experiment (Telley et al. 2019; Magrinelli et al. 2022) and the CellCover marker panels (Ji et al. 2026). References are at the end.

## The approach

The atlas does not annotate CPNs, and at embryonic ages no single gene identifies them reliably. The workflow therefore combines three kinds of information.

1. **When a cell was born and how far it has differentiated.** CellCover marker panels describe cortical cells 1 h, 24 h and 96 h after their last division, for divisions on embryonic days E12 to E15. They were derived from the FlashTag time course of Telley et al. Neurons born around E15 form the superficial layers, where most CPNs are. The E15.96H panel (young neurons born at E15) is therefore the signature sought. The E15.24H panel (cells still migrating) and the E15.1H panel (progenitors) describe states to exclude.
2. **Identity markers.** The CPN markers *Satb2*, *Pou3f2* and *Trim67* are required. The deep-layer projection neuron markers *Tbr1*, *Bcl11b* and *Fezf2* argue against a CPN identity.
3. **The atlas annotation.** Candidates are neurons dissected from the dorsal forebrain between E15.0 and E18.0. Retained cells must belong to the subclass "Cortical or hippocampal glutamatergic".

Retained cells point to atlas clusters. Each of these clusters is then described with all its cells. The clusters with high *Satb2*, low *Fezf2* and *Bcl11b*, and the E15.96H signature are taken as CPN clusters. Finally, expression is summarised by age in these clusters and in three comparison groups: forebrain neurons, forebrain radial glia and forebrain neuroblasts.

All expression values come from the `pooled` layer of the atlas, normalised by median scaling of each cell's pooled library size. The `pooled` layer is part of the atlas file as distributed; the workflow does not create it (see the block on the `pooled` layer below).

<details>
<summary>Why look for cells born at E15: birth date, layers and callosal neurons</summary>

The neocortex is built from the inside out. Apical progenitors divide at the ventricle, and their daughter neurons migrate past earlier-born neurons to the surface. Neurons born first form the deep layers (6 and 5); neurons born last form the superficial layers (4 and 2/3). In the mouse, the neurons of layers 6, 5, 4 and 2/3 are generated in succession between E12 and E15 (Telley et al. 2019).

CPNs send their axon across the corpus callosum to the other hemisphere. Most of them lie in layers 2/3, with a smaller population in layer 5. Among neurons born at E13.5, those labelled by retrograde tracing from the contralateral hemisphere lie in layers 2/3 and 5a (Magrinelli et al. 2022). SATB2 is the classical marker of these intracortically projecting neurons. It is mostly expressed by superficial-layer neurons, but also by a fraction of deep-layer neurons (Magrinelli et al. 2022). A single marker is therefore not enough, and the workflow combines the markers with a birth-date signature.

Birth date predicts identity better late in corticogenesis than early. Neurons born together early (around E13.5) scatter over several layers and adopt different projection types and molecular identities. Neurons born late (around E15.5) form a compact, homogeneous layer (Magrinelli et al. 2022). The E15-born cohort is thus a good proxy for superficial-layer, mostly callosal, neurons.

Late-born neurons also pass through a transient stage. One day after birth, they still express some deep-layer genes. By four days, layer-specific markers such as *Bcl11b* (layer 5) and *Pou3f2* (layers 2/3) have become mutually exclusive (Telley et al. 2019). This is why the workflow looks for the 96-hour signature and excludes cells whose profile is still that of 24-hour cells.

</details>

<details>
<summary>The FlashTag time course behind the panels (Telley et al. 2019)</summary>

FlashTag is a fluorescent dye injected into the lateral ventricle. It labels only the progenitors dividing at the ventricle at that moment, so it marks a cohort of cells born at the same time. Telley et al. injected it at E12, E13, E14 or E15. They then collected labelled cells from the putative somatosensory cortex at three times:

- after 1 h, while the apical progenitors are still dividing;
- after 24 h, when daughter cells are passing through the subventricular zone (basal progenitors and one-day-old neurons);
- after 96 h, when the daughter neurons have entered the cortical plate.

Single-cell RNA sequencing of these 12 conditions (4 days × 3 times) gave 2,756 cells. Each cell carries two exact time labels: the day it was born, and the time since its last division.

Two axes organise the data. One is a birth-date axis: progenitors change their transcriptional state from E12 to E15, and pass these "birthmarks" to their daughter neurons. The other is a differentiation axis: newborn neurons follow largely the same maturation program whatever their birth date. The CellCover panels use both axes: one panel for each birth day and each time after division.

</details>

<details>
<summary>CellCover marker panels (Ji et al. 2026) and how they are used here</summary>

**The idea.** Usual marker genes are chosen one gene at a time, by differential expression. CellCover instead chooses a *set* of genes that together identify a cell class. A cell is "covered at depth *d*" by a panel if at least *d* of the panel's genes are detected in it (count ≥ 1). A panel is chosen so that nearly all cells of the class are covered (covering rate 1 − α, for example 98 %). Its genes are also chosen to be rarely expressed outside the class. The search is solved as an integer linear program (a minimal set-covering problem).

Because the panel works as a set, it tolerates the many zeros of single-cell data: a given cell may miss some panel genes but still show enough of the others. Panels can be transferred to another dataset by measuring, in each cell, how many panel genes are detected.

**The twelve Telley panels.** Ji et al. built one panel for each of the 12 FlashTag conditions, E12.1H to E15.96H. They transferred the panels into the La Manno atlas (their Fig. 4A). Radial glia showed the highest covering rates for the 1H panels, neuroblasts for the 24H panels and neurons for the 96H panels. Transferred into laser-microdissected macaque cortex, the E15.96H panel was elevated specifically in the most superficial, latest-born neurons (their Fig. 5B). These results are the basis for using E15.96H as the signature of young superficial-layer neurons in the atlas.

Ji et al. also report three properties that are relevant here:

- 24H markers are also found in some neurons, because 24 hours after division some cells have already become neurons while others are still progenitors;
- the E15.96H panel also carries a signal of the onset of gliogenesis, which is one reason why the workflow does not rely on the panel alone;
- a panel is named by the day of labelling, so E15.96H cells were profiled about four days later, near birth.

**The panel files.** The panels were copied by hand from the NeMO Analytics gene cart "TelleyCellCover12sets" (see `input/README.md`). Of the panel genes, 34 of 41 (E15.96H), 41 of 45 (E15.24H) and 23 of 35 (E15.1H) are present in the atlas. The missing genes are pseudogenes, predicted genes (*Gm…*) and a mitochondrial tRNA. Ji et al. note that such genes are part of their panels.

**How the workflow uses the panels.** Two uses follow the CellCover idea, and one is the workflow's own:

- step 5 uses the *coverage*: the fraction of panel genes detected in a cell, which is the transfer measure of Ji et al.;
- step 3 compares, within each cell, the expression of its E15.96H genes with that of its E15.24H genes, its E15.1H genes and its deep-layer markers, using rank tests. These tests are the workflow's own way of asking which state dominates in a cell; they are not part of CellCover (see the block on steps 3 and 4).

</details>

<details>
<summary>The atlas (La Manno et al. 2021)</summary>

The atlas profiles the embryonic mouse brain every day from E7 to E18 with droplet-based single-cell RNA sequencing (10x Genomics Chromium v1). After quality control it holds 292,495 cells from 93 samples (215 embryos). Cells were grouped into 798 clusters with the Cytograph pipeline. Clusters were manually annotated with a class (for example radial glia, neuroblast, neuron), a subclass and a probable location.

The dissections changed with age:

- from E12 to E15, the forebrain was divided into dorsal (including the hemispheres) and ventral parts;
- from E16 to E18, it was divided into dorsal, ventral and thalamic parts.

The workflow uses these annotations:

- dissected region (`Tissue`);
- age (`Age`);
- cluster number and name (`Clusters`, `ClusterName`);
- class and subclass;
- the cell-cycle call (`IsCycling`; about a third of all atlas cells are cycling).

The atlas also describes the cortical excitatory lineage. Along it, the transcription factors *Emx1*, *Eomes*, *Tbr1* and *Satb2* are expressed in an ordered progression from E11 to E18.

</details>

<details>
<summary>The <code>pooled</code> layer: what it is and where it comes from</summary>

**It is part of the atlas file.** `dev_all.loom` holds the raw counts (main matrix) and four layers: `spliced`, `unspliced`, `expected` and `pooled`. The workflow reads `pooled` as it is. Step 1 only links it into the R object, and the workflow computes nothing to create it.

**How the atlas authors made it.** The layer comes from the "Poisson pooling" step of their Cytograph pipeline. The Methods give `k_pooling: 10` and cite Cytograph commit `2e8eb79`. That commit is in the repository `linnarsson-lab/cytograph-dev`, file `cytograph/preprocessing/poisson_pooling.py`. The pooling step works as follows:

1. Cells are placed in a reduced space by hierarchical Poisson factorization.
2. The 10 nearest neighbours of each cell, including the cell itself, are found using the Jensen–Shannon distance.
3. For each cell, the counts of these 10 cells are summed, each weighted by its similarity to the cell (1 − distance; the cell itself has weight 1).
4. This is done separately for spliced and unspliced counts; `pooled` is their sum, stored as integers.

**A check on the atlas file agrees.** In 300 random cells and 12 genes, every `pooled` value is at least the raw count. Across all cells, the median ratio of pooled to raw library size is 10.3 (raw median 5,410 counts per cell, pooled 56,190).

**What it means for the analysis.**

- Pooling fills in many of the zeros of single-cell data, so panel genes and markers are detected more often. Detection-based measures are therefore higher than they would be on raw counts: the coverage of a panel, and the number of cells in which a gene is detected (`n_pos`).
- Each pooled value is a local average of similar cells. Values of neighbouring cells share counts, so they are not independent observations. The standard errors in the tables describe the spread of pooled values, not independent cells.

**Normalisation.** A cell's pooled values are its own, even though each was computed from several cells. Step 1 computes, for each cell, its pooled library size: the sum of its pooled values over all genes. The cell's size factor is the median pooled library size of all atlas cells divided by the cell's own pooled library size. Normalised expression is the cell's pooled count times its own size factor. The pooled library size already reflects the sequencing depth and weights of the neighbours that went into the pooled values, so no other factor is needed. A size factor from raw counts is also computed and stored, but not used.

</details>

## Steps

| Step | Script | What it does | Main outputs (`results/`) |
|---|---|---|---|
| 1 | `01_build_atlas_object.R` | the atlas as a SingleCellExperiment (annotations; count matrices linked to the loom file); library sizes and size factors | `01_atlas/atlas_sce.rds` |
| 2 | `02_select_candidates.R` | candidate cells: dorsal forebrain neurons, E15.0–E18.0 | `02_candidates/candidates.tsv` |
| 3 | `03_cellcover_tests.R` | per cell: detected panel genes and markers; one-sided Wilcoxon tests of E15.96H against E15.24H, E15.1H and the deep-layer markers | `03_cellcover_tests/cell_tests.tsv.gz` |
| 4 | `04_filter_cells.R` | cells with a CPN marker, not cycling, past the 24-hour stage, without a deep-layer signature, in the glutamatergic subclass | `04_filtered_cells/retained_cells.tsv`, `filter_steps.tsv`, `retained_clusters.tsv` |
| 5 | `05_select_cpn_clusters.R` | per-cluster description, dot plots by cluster and age, selection of the CPN clusters | `05_cpn_clusters/cluster_table.tsv`, `cpn_clusters.tsv`, `dotplot_*.png` |
| 6 | `06_expression_tables.R` | expression by age per cluster and per group | `06_expression/expression_by_age.xlsx`, `expression_sce.rds`, `.tsv` tables |
| 7 | `07_figures.R` | Fig. 4a and Extended Data Fig. 4a (mean ± SEM, standard error of the mean) | `07_figures/*.png` and data |

Every script begins with a description of its logic. The definitions it applies (ages, markers, thresholds, groups) are named constants at its top.

<details>
<summary>Steps 2 to 4: from candidate cells to retained cells</summary>

**Step 2, candidates.** These are cells dissected from the dorsal forebrain (`Tissue` = ForebrainDorsal), in atlas clusters 492–797 (the neuron clusters), sampled between E15.0 and E18.0. E15-born neurons exist as young postmitotic neurons only in this window, and the atlas ends at E18.

**Step 3, signatures and tests.** For each candidate cell, the genes of each panel and marker set that are detected in the cell (pooled count > 0) are listed. Three one-sided Wilcoxon rank-sum tests then ask whether the cell's E15.96H genes are expressed at higher levels than its comparison genes:

- `p_24h`: against its E15.24H genes;
- `p_1h`: against its E15.1H genes;
- `p_deep`: against its deep-layer markers (*Tbr1*, *Bcl11b*, *Fezf2*).

The values compared are the counts of those genes in all candidate cells. A test is missing (NA) when one of the two gene sets is not detected in the cell. The tests are computed exactly as R's `wilcox.test(x, y, alternative = "greater")`, using its normal approximation with tie and continuity corrections, from frequency tables of counts.

**Step 4, filters.** A candidate is retained if all of the following hold:

1. it expresses at least one CPN marker (*Satb2*, *Pou3f2* or *Trim67*);
2. it is not cycling;
3. `p_24h` ≤ 0.05 divided by the number of candidates (a Bonferroni correction over cells), so its profile is past the 24-hour stage;
4. `p_deep` ≤ 0.05, or no deep-layer marker is detected in it;
5. it belongs to the subclass "Cortical or hippocampal glutamatergic".

`p_1h` is reported in the output but not used as a filter.

On the atlas, the filters leave the following numbers of cells (`filter_steps.tsv`):

| After | Cells |
|---|---|
| candidates | 17,917 |
| CPN marker | 17,255 |
| not cycling | 17,238 |
| E15.96H > E15.24H | 15,362 |
| E15.96H > deep layer | 3,054 |
| glutamatergic subclass | 3,004 (in 30 clusters) |

</details>

<details>
<summary>Step 5: from retained cells to CPN clusters</summary>

The retained cells spread over 30 atlas clusters. Clusters are the unit used downstream, so each of these 30 clusters is described with *all* its atlas cells, of any age and dissection.

Two dot plots show the clusters by age:

- the E15.1H, E15.24H and E15.96H panels;
- the markers *Satb2*, *Fezf2* and *Bcl11b*.

In both plots, the colour is the mean normalised expression and the size is the percentage of expressing cells. These plots were used to choose the CPN clusters by eye. The workflow writes the same choice as a rule. A CPN cluster has, over all its cells:

1. callosal identity: mean *Satb2* ≥ 60;
2. no deep-layer identity: mean *Fezf2* + *Bcl11b* ≤ 10;
3. the late-born neuron signature: mean E15.96H coverage ≥ 0.40.

Of the 30 clusters, 7 pass the first two conditions. Six of these also pass the third: Neur512 to Neur517. The seventh, Neur505, has mean *Satb2* 80.8 and *Fezf2* + *Bcl11b* 6.6, but an E15.96H coverage of 0.378. `cluster_table.tsv` gives every value and every pass/fail.

</details>

<details>
<summary>Steps 6 and 7: expression by age</summary>

**The groups.** Expression is summarised in four groups of clusters, using every atlas cell of the clusters whatever its age or dissection:

| Group | Clusters |
|---|---|
| `cpn_clusters` | the 6 CPN clusters from step 5 |
| `forebrain_neurons` | 120 clusters of class Neuron, subclasses cortical or hippocampal glutamatergic, forebrain glutamatergic, forebrain GABAergic (includes the CPN clusters) |
| `forebrain_radial_glia` | 32 clusters of class Radial glia, subclasses dorsal forebrain, forebrain, cortical hem |
| `forebrain_neuroblasts` | 28 clusters of class Neuroblast, subclasses forebrain, forebrain glutamatergic, forebrain GABAergic |

**The statistics.** For each gene, each age and each cluster or group, the tables give:

- `n_cells`: the number of cells;
- `n_pos`: the number of those cells in which the gene of the row is detected (expression > 0); it depends on the gene, while `n_cells` does not;
- the mean, standard deviation (SD) and standard error of the mean (SEM) of normalised expression (SEM = SD / √`n_cells`).

The 13 genes are *Bcl11b*, *Cux2*, *Eomes*, *Epha3*, *Epha4*, *Ephb1*, *Ephb2*, *Ephb3*, *Fezf2*, *L1cam*, *Pax6*, *Satb2* and *Tbr1*.

**The figures.** Step 7 plots the mean ± SEM at the ages at which the CPN clusters contain cells.

</details>

## Preparing the folder

A copy of the repository holds the scripts, the settings, the CellCover panels, the expected validation table and the recipes of the two software environments. It does not hold the atlas file (10 GB), the built environments or any result; the steps below add them.

Requirements:

- R 4.5.1 (the version is checked when the R environment is built);
- conda, for the Snakemake route;
- about 11 GB of disk for the atlas, 1–2 GB for the environments and 170 MB per results folder.

```bash
# 1. the atlas: downloads input/atlas/dev_all.loom and checks its MD5
bash input/get_atlas.sh
# 2. the R environment (CRAN snapshot 2025-12-01, Bioconductor 3.21), in envs/r/renv/
cd envs/r && Rscript build_env.R && cd ../..
# 3. the Snakemake environment, in envs/snakemake/ (only for the Snakemake route)
conda env create -p envs/snakemake -f envs/snakemake.yaml
```

- `input/get_atlas.sh` creates `input/atlas/`, downloads the file from the Linnarsson lab's distribution (see `input/README.md`) and checks it against `input/CHECKSUMS.md5`. An interrupted download resumes when the script is run again. A copy of `dev_all.loom` obtained otherwise can be placed in `input/atlas/` instead; the script then only checks it.
- `build_env.R` checks that it runs under R 4.5.1. If the `Rscript` found first on your system is another version, call R 4.5.1 by its full path, e.g. `/path/to/R-4.5.1/bin/Rscript build_env.R`, and set `RSCRIPT=/path/to/R-4.5.1/bin/Rscript` for the runs (see Running).
- The two environments are built once and stay inside the folder. To keep conda's package downloads inside the folder as well, prefix the conda command with `CONDA_PKGS_DIRS=$PWD/envs/conda_pkgs`.
- `input/atlas/` comes with a note on how to get the atlas (`command_to_download_the_atlas.txt`). `results/` and `results_snakemake/` come with their eight empty step folders, and `logs/` with its `snakemake/` subfolder, so the structure is visible before a run. Each of these folders holds an empty `.gitkeep` file, which only lets git keep the folder. `results/` receives the outputs of `run_all.sh` and of the plain Snakemake command; `results_snakemake/` those of the Snakemake command with `--config results_dir=results_snakemake`.

## Running

```bash
# either: step by step
bash run_all.sh --validate
# or: Snakemake
envs/snakemake/bin/snakemake -s workflow/Snakefile --cores 8 all validate
# Snakemake into another results folder (settings after --config, targets before it)
envs/snakemake/bin/snakemake -s workflow/Snakefile --cores 8 all validate --config results_dir=results_snakemake
```

- **Where results go.** `run_all.sh` and the plain Snakemake command both read `config/config.yaml` and write to `results/`.
  - `run_all.sh` always re-runs all seven steps and overwrites `results/`.
  - Snakemake re-runs only what is missing or out of date. After a `run_all.sh` run it reports "Nothing to be done"; add `--forceall` to make it re-run everything.
  - `--config results_dir=<folder>` sends a Snakemake run to another folder and leaves `results/` untouched, for example to compare two runs. The analysis is the same; only the location of the outputs changes.
- **Settings.** Paths and the number of threads are set in `config/config.yaml`. If the R executable is not `/opt/R/4.5.1/bin/Rscript`, set `RSCRIPT=/path/to/Rscript`.
- **Run time.** The whole run takes about 10 minutes with 8 threads. Step 1 makes one pass over the 10 GB atlas file.
- **Logs.** `run_all.sh` writes its logs to `logs/`, Snakemake to `logs/snakemake/`. Snakemake also writes the settings it used to `<results folder>/config_used.yaml`.

## Validation

`validation/expected/soon_gene_norm_stats4.xlsx` is the table used for the manuscript figures. `validation/check_against_expected.R` compares it row by row with `results/06_expression/expression_by_age.xlsx` and writes `results/validation/validation_report.txt`. It is run by `run_all.sh --validate` or the Snakemake target `validate`, and is not used by the analysis.

The two files have the same two tabs; only the group names differ. `validation/README.md` gives the correspondence of files, tabs, columns and group names.

## Folder layout

```
In the repository
  input/        CellCover panels, input/README.md (sources), CHECKSUMS.md5, get_atlas.sh,
                atlas/command_to_download_the_atlas.txt
  config/       config.yaml: paths, results folder, threads
  scripts/      one R script per step; _common.R (shared set-up); run_r.sh (runs a script in the R environment)
  workflow/     Snakefile
  envs/         r/ (renv.lock, build_env.R, env.sh) and snakemake.yaml
  validation/   expected table, comparison script, README.md
  results/      the eight step folders, empty (.gitkeep files)
  results_snakemake/   the same, for a second Snakemake run (see Running)
  logs/         empty, with logs/snakemake/ (.gitkeep files)
Added when preparing the folder
  input/atlas/          dev_all.loom
  envs/r/renv/ …        R package library (and renv cache and build folders)
  envs/snakemake/       Snakemake environment
Created by the runs
  results/…     outputs, in the step folders (see below); results_snakemake/… the same
  logs/…        one log per step (logs/snakemake/ for the Snakemake route)
  .snakemake/   Snakemake's own records (Snakemake route only)
```

<details>
<summary>Files produced by a run (results folder)</summary>

Sizes are those of the run on which this workflow was validated.

```
results/
├── 01_atlas/
│   ├── atlas_sce.rds                      140 MB   the atlas as a SingleCellExperiment (counts stay in the loom file)
│   └── atlas_summary.txt                 0.7 kB   cells, genes, assays, median library sizes, cell attributes
├── 02_candidates/
│   └── candidates.tsv                    2.2 MB   candidate cells (dorsal forebrain neurons, E15.0–E18.0)
├── 03_cellcover_tests/
│   ├── cell_tests.tsv.gz                 298 kB   per candidate: detected panel genes and markers, Wilcoxon p-values
│   └── panels_used.tsv                   2.9 kB   genes of the E15 panels and whether each is in the atlas
├── 04_filtered_cells/
│   ├── all_candidates_with_filters.tsv   3.4 MB   every candidate with the result of each filter
│   ├── filter_steps.tsv                  0.2 kB   cells left after each filter
│   ├── retained_cells.tsv                286 kB   cells passing all filters
│   └── retained_clusters.tsv             0.5 kB   atlas clusters of the retained cells
├── 05_cpn_clusters/
│   ├── cluster_table.tsv                 5.4 kB   per cluster: Satb2, Fezf2, Bcl11b, Tbr1, panel coverage, pass/fail
│   ├── cpn_clusters.tsv                  0.1 kB   the CPN clusters
│   ├── dotplot_markers.png               427 kB   Satb2, Fezf2, Bcl11b by cluster and age
│   └── dotplot_panels.png                372 kB   E15.1H, E15.24H, E15.96H by cluster and age
├── 06_expression/
│   ├── expression_by_age.xlsx            2.6 MB   tabs full_resolution and grouped_chosen_Clusters
│   ├── expression_per_cluster.tsv        6.1 MB   = tab full_resolution
│   ├── expression_per_group.tsv          164 kB   = tab grouped_chosen_Clusters
│   ├── expression_sce.rds                9.5 MB   cells of the groups × 13 genes: counts, normalised values, groups
│   └── group_clusters.tsv                5.7 kB   clusters of each group
├── 07_figures/
│   ├── fig4a.png                         104 kB   Fig. 4a
│   ├── fig4a_data.tsv                    7.1 kB   data of Fig. 4a
│   ├── extfig4a.png                      291 kB   Extended Data Fig. 4a
│   └── extfig4a_data.tsv                  28 kB   data of Extended Data Fig. 4a
├── validation/
│   └── validation_report.txt             0.5 kB   PASS / FAIL per tab (only with --validate or the target validate)
└── config_used.yaml                      0.1 kB   settings used (Snakemake route only)
```

In all, 23 files (24 with `config_used.yaml`) and about 166 MB, most of it `atlas_sce.rds`.

</details>

<details>
<summary>Glossary</summary>

| Term | Meaning |
|---|---|
| CPN | callosal projection neuron: a cortical neuron whose axon crosses the corpus callosum to the other hemisphere |
| E15, E15.5 … | embryonic day |
| FlashTag | a dye injected into the ventricle that labels only the progenitors dividing at that moment, marking cells born at the same time |
| E15.96H (etc.) | CellCover panel of cells labelled at E15 and collected 96 h later; 1H = progenitors, 24H = cells in transit, 96H = young neurons |
| coverage | fraction of a panel's genes detected (count > 0) in a cell |
| covering rate | fraction of the cells of a class in which at least *d* panel genes are detected (Ji et al.) |
| deep and superficial layers | layers 6–5 (born first) and 4–2/3 (born last) of the neocortex |
| apical, basal progenitors | progenitors dividing at the ventricle; progenitors dividing away from it, in the subventricular zone |
| `pooled` layer | counts of each cell summed with those of its 9 nearest neighbours, weighted by similarity (atlas pipeline) |
| size factor | median pooled library size of all atlas cells divided by the cell's own pooled library size (sum of its pooled values over all genes) |
| `n_cells`, `n_pos` | cells in a cluster or group at one age (the same for every gene); cells among them in which the gene of the row is detected, expression > 0 (different for each gene) |
| SD, SEM | standard deviation; standard error of the mean (SD / √`n_cells`) |
| Bonferroni correction | dividing the significance threshold by the number of tests, here the number of candidate cells |

</details>

## References

1. La Manno, G., Siletti, K., Furlan, A. et al. Molecular architecture of the developing mouse brain. *Nature* 596, 92–96 (2021). https://doi.org/10.1038/s41586-021-03775-x. Atlas data: https://linnarssonlab.org/develmouse/. Cytograph pipeline: the paper cites <https://github.com/linnarsson-lab/cytograph2>, but the commit it names (2e8eb79a5f83bd9dda15503d9b2476ebdd8fa0b3) is at <https://github.com/linnarsson-lab/cytograph-dev>
2. Ji, L., Wang, A., Sonthalia, S. et al. CellCover defines marker gene panels capturing developmental progression in neocortical neural stem cell identity. *eLife* 14, RP107531 (2026). https://doi.org/10.7554/eLife.107531
3. Telley, L., Agirman, G., Prados, J. et al. Temporal patterning of apical progenitors and their daughter neurons in the developing neocortex. *Science* 364, eaav2522 (2019). https://doi.org/10.1126/science.aav2522
4. Magrinelli, E., Baumann, N., Wagener, R. J. et al. Heterogeneous fates of simultaneously-born neurons in the cortical ventricular zone. *Scientific Reports* 12, 6022 (2022). https://doi.org/10.1038/s41598-022-09740-6
5. Orvis, J., Gottfried, B., Kancherla, J. et al. gEAR: Gene Expression Analysis Resource portal for community-driven, multi-omic data exploration. *Nature Methods* 18, 843–844 (2021). https://doi.org/10.1038/s41592-021-01200-9. Portal used for the panels: NeMO Analytics, https://nemoanalytics.org/p?p=p&l=CellCover&c=TelleyCellCover12sets&algo=binary
