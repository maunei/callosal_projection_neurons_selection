# Inputs

Everything the analysis reads is in this folder. The CellCover panels come with the repository; the atlas file is downloaded into `atlas/` with `bash input/get_atlas.sh`, which also checks it (see `atlas/command_to_download_the_atlas.txt`). Checksums: `CHECKSUMS.md5` (`md5sum -c CHECKSUMS.md5` from this folder, once the atlas is present).

## atlas/

| File | Content |
|---|---|
| `dev_all.loom` (10,268,831,815 bytes) | La Manno et al. 2021 developing mouse brain atlas: 292,495 cells × 31,053 genes; main matrix (raw counts) and layers `pooled`, `spliced`, `unspliced`, `expected`; cell and gene annotations. |

This is the only atlas file the workflow reads. Every per-cluster and per-group value is computed from its single cells. The atlas release also includes `dev_all.agg.loom` (the atlas aggregated by cluster), which the workflow does not use.

**Where to get it.** The file is distributed by the Linnarsson lab at https://linnarssonlab.org/develmouse/ ("Download complete dataset (loom format), 31053 genes x 292495 cells"). The direct link points to Dropbox:
https://www.dropbox.com/scl/fi/nr6ny2ysiqi7hqg7x5rm3/dev_all.loom?rlkey=lk62mswfiuxgypt0urhtmnnhv&dl=1

**Equivalence with the file on that page.** The copy with which this workflow was developed and validated was downloaded in May 2021 from the address then in use: `https://storage.googleapis.com/linnarsson-lab-loom/dev_all.loom`, linked from `http://mousebrain.org/development/downloads.html`. That address returned HTTP 404 on 2026-10-15. On 2026-10-16 the file was downloaded again from the Dropbox link above and is byte-identical to that copy:

- size 10,268,831,815 bytes;
- MD5 `02c96443f5eea83fe79b385cf89dc134`, as in `CHECKSUMS.md5`.

A file downloaded from the page is therefore the file the workflow was validated with. `get_atlas.sh` downloads it from the Dropbox link above and checks its MD5.

The raw sequencing data are at SRA, BioProject PRJNA637987.

Reference: La Manno et al. 2021 [1].

## cellcover_panels/

| File | Content |
|---|---|
| `01_E12.1H.txt` … `12_E15.96H.txt` | the twelve CellCover marker panels: each file lists the same 337 genes with `1` (gene in the panel) or `0`. Panel name = age of the last progenitor division (E12–E15) and time after it (1 h, 24 h, 96 h). The workflow uses E15.1H (35 genes), E15.24H (45) and E15.96H (41). |
| `00_info_TelleyCellCover12sets.txt` | source notes |

Source: NeMO Analytics (built on the gEAR portal), gene cart "TelleyCellCover12sets", binary display:
https://nemoanalytics.org/p?p=p&l=CellCover&c=TelleyCellCover12sets&algo=binary
The panel memberships were copied by hand from that page into these files (they are displayed on the page, not offered as files to download).

The panels are those of Ji et al. 2026 [2], derived from the FlashTag data of Telley et al. 2019 [3]; NeMO Analytics is built on gEAR [4]. The main `README.md` explains how the workflow uses the panels and the atlas.

## References

1. La Manno, G., Siletti, K., Furlan, A. et al. Molecular architecture of the developing mouse brain. *Nature* 596, 92–96 (2021). https://doi.org/10.1038/s41586-021-03775-x. Atlas data: https://linnarssonlab.org/develmouse/
2. Ji, L., Wang, A., Sonthalia, S. et al. CellCover defines marker gene panels capturing developmental progression in neocortical neural stem cell identity. *eLife* 14, RP107531 (2026). https://doi.org/10.7554/eLife.107531
3. Telley, L., Agirman, G., Prados, J. et al. Temporal patterning of apical progenitors and their daughter neurons in the developing neocortex. *Science* 364, eaav2522 (2019). https://doi.org/10.1126/science.aav2522
4. Orvis, J., Gottfried, B., Kancherla, J. et al. gEAR: Gene Expression Analysis Resource portal for community-driven, multi-omic data exploration. *Nature Methods* 18, 843–844 (2021). https://doi.org/10.1038/s41592-021-01200-9. Portal used for the panels: NeMO Analytics, https://nemoanalytics.org/p?p=p&l=CellCover&c=TelleyCellCover12sets&algo=binary
