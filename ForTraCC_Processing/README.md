# ForTraCC_Processing [R scripts]
Processing ForTraCC-Radar clusters and families per case as lists using `tidyverse` functions.

## Main scripts
- [`cappis_fortracc_figs.R`](fortracc_figs.R): reading pre-processed clusters and generating CAPPI plots (figures in [`ForTraCC_Processing/figures/cappis/`](figures/cappis/))

- [`extracting_clusters_info.R`](extracting_clusters_info.R): reading pre-processed clusters and extracting "box limits" around them (to be used on FCTH data)