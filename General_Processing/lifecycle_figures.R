#-------------------------------------------------------------------------------
#-- Importing ForTraCC and lightning entries with "lifecycle_data.RData"
#-- Adding hailpads data
#-- Generating table with overall information about the cases
#-- Plotting ForTraCC and lightning during life cycle
#-------------------------------------------------------------------------------

# Loading necessary scripts and packages ---------------------------------------
require(fields)
require(maptools)
require(reshape2)
require(tidyverse)
require(magrittr)
require(lubridate)
require(scales)
require(cowplot)
require(gridExtra)
require(grid)
load("General_Processing/lifecycle_data.RData")
source("Hailpads_Processing/processing_hailpads.R")
theme_set(theme_bw())

# Table with overall information -----------------------------------------------
hailpads_summary <- hailpads %>%
  separate(plate_full, into = c("case", "plate2"), sep = "\n") %>%
  group_by(case) %>%
  summarise(hail_mean = mean(value), hail_max = max(value))
brasildat_summary <- bind_cols(
  flashes_brasildat_df %>% group_by(class, case) %>% count(),
  flashes_brasildat_df %>%
    mutate(date = floor_date(date, unit = "minutes")) %>%
    group_by(date, class, case) %>%
    count() %>%
    group_by(class, case) %>%
    summarise(n = max(n))
) %>%
  select(case, class, n, n1) %>%
  rename(flash_count = n, flash_max = n1)
fams_summary <- selected_fams_df %>%
  group_by(case) %>%
  summarise(
    duration = interval(first(date), last(date)) %>% as.duration(),
    dbz_max = max(pmax), size_max = max(size)
  )
# write.csv2(hailpads_summary, file = "General_Processing/cases_hailpads", row.names = F, dec = ",")
# write.csv2(brasildat_summary, file = "General_Processing/cases_brasildat", row.names = F, dec = ",")
# write.csv2(fams_summary, file = "General_Processing/cases_fams", row.names = F, dec = ",")

# Joining dBZ, size and lightning ----------------------------------------------
plt <- plot_grid(arrangeGrob(plt_dbz, nullGrob(), ncol=1, heights = c(0.915, 0.085)),
                 arrangeGrob(plt_size, nullGrob(), ncol=1, heights = c(0.915, 0.085)), 
                 plt_flash_brasildat, labels = c("a", "b", "c"), 
                 ncol = 3, rel_widths = c(0.3, 0.3, 0.34))
save_plot("General_Processing/figures/cases_dbz_size_lightning.png",
          plot = plt, ncol = 3, base_width = 2.5, base_height = 6.5, bg = "transparent")
# save_plot("General_Processing/figures/cases_dbz_size_lightning_less.png",
  # plot = plt, ncol = 3, base_width = 3, base_height = 3) #-- For less plots
