#---------------------------------------------------------------------------------------------------------------------------------
#-- Importing ForTraCC and lightning entries with "lifecycle_data.RData"
#-- Adding hailpads data
#-- Generating table with overall information about the cases
#-- PlottingForTraCC and lightning during life cycle
#---------------------------------------------------------------------------------------------------------------------------------

#-- Loading necessary scripts and packages
require(fields); require(maptools); require(reshape2); require(tidyverse); require(magrittr); require(lubridate)
require(scales); require(cowplot)
load("General_Processing/lifecycle_data.RData")
source("Hailpads_Processing/processing_hailpads.R")
theme_set(theme_grey())
#---------------------------------------------------------------------------------------------------------------------------------

#-- Table with overall information
hailpads_summary <- hailpads %>% separate(plate, into = c("case", "plate"), sep = "\n") %>% 
  group_by(case) %>% summarise(hail_mean = mean(value), hail_max = max(value))
brasildat_summary <- bind_cols(data_brasildat_df %>% group_by(class, case) %>% count(),
                               data_brasildat_df %>% mutate(date = floor_date(date, unit = "minutes")) %>% 
                                 group_by(date, class, case) %>% count() %>% 
                                 group_by(class, case) %>% summarise(n = max(n))) %>% 
  select(case, class, n, n1) %>% rename(stroke_count = n, stroke_max = n1)
fams_summary <- selected_fams_df %>% group_by(case) %>% 
  summarise(duration = interval(first(date), last(date)) %>% as.duration(), 
            dbz_max = max(pmax), size_max = max(size))
write.csv2(hailpads_summary, file = "cases_hailpads", row.names = F, dec = ",")
write.csv2(brasildat_summary, file = "cases_brasildat", row.names = F, dec = ",")
write.csv2(fams_summary, file = "cases_fams", row.names = F, dec = ",")
#---------------------------------------------------------------------------------------------------------------------------------

#-- Joining dBZ, size and lightning
plt <- plot_grid(plt_dbz, plt_size, plt_brasildat, labels = c("a", "b", "c"), ncol = 3, rel_widths = c(0.4, 0.4, 0.55))
save_plot("General_Processing/figures/cases_dbz_size_lightning.png", plot = plt, ncol = 3, base_width = 3, base_height = 5)
# save_plot("General_Processing/figures/cases_dbz_size_lightning_less.png", plot = plt, ncol = 3, base_width = 3, base_height = 3) #-- For less plots