#-------------------------------------------------------------------------------
# Importing entries from "processing_fortracc.R"
# Reading lightning data from LINET
# Plotting IC/CG/total lightning distribution and rate during life cycle
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
load("ForTraCC_Processing/fortracc_data.RData") # Loading data from ForTraCC

# Updating selected_clusters and -----------------------------------------------
# creating selected_latlon with the whole families -----------------------------

#-- Selecting part of the families
selected_fams <- selected_fams[c(5, 6)]
selected_fams_df <- selected_fams_df %>% filter(case == "Case 2017-11-15 " | case == "Case 2017-11-16 ")
data_hailpads <- data_hailpads[5:6,]

selected_clusters <-
  purrr::map(
    purrr::map(selected_fams, ~select(.x, date) %>% unlist()),
    ~which(ymd_hm(dates_clusters_cappis) %in% .x, arr.ind = T) %>% data_clusters[.]
  ) %>%
  map2(
    ., purrr::map(selected_fams, ~filter(.x, date %in% ymd_hm(dates_clusters_cappis))) %>%
      purrr::map(., select, sys),
    ~map2(..1, ..2, ~which(.x == .y, arr.ind = T))
  ) %>%
  modify_depth(., 2, as.data.frame)
selected_latlon <- modify_depth(selected_clusters, 2, mutate,
                                row = lon_vector[row] %>% round(digits = 2), col = lat_vector[col] %>% round(digits = 2)
) %>%
  map2(., purrr::map(selected_fams, ~filter(.x, date %in% ymd_hm(dates_clusters_cappis)) %>%
                       select(date) %>%
                       unlist()), ~set_names(.x, as_datetime(.y))) %>%
  modify_depth(., 2, mutate,
               row_m1 = row - 0.01, row_p1 = row + 0.01, col_m1 = col - 0.01, col_p1 = col + 0.01,
               row_m2 = row - 0.02, row_p2 = row + 0.02, col_m2 = col - 0.02, col_p2 = col + 0.02
  )
#--- If necessary, put timestamps in the clusters coordinates data
# selected_latlon <- map2(selected_latlon, purrr::map(selected_fams, ~filter(.x, date %in% ymd_hm(dates_clusters_cappis)) %>%
#                                                select(date) %>% unlist),
#                         ~map2(..1, ..2, ~mutate(.x, date = as_datetime(.y))))


# Reading/processing lightning data
data_linet <- read_table("Lightning_Processing/filenames_linet", col_names = F) %>% unlist() %>%
  # data_linet <- read_table("Lightning_Processing/filenames_linet_less", col_names = F) %>% unlist() %>% # For less plots 
  purrr::map(~read_table2(.x, col_names = F)) %>% map_df(rbind) %>% 
  set_colnames(c("small_date", "time", "lat", "lon", "z", "class", "peak_curr", "none")) %>% 
  mutate(date = paste(small_date, time)) %>% 
  mutate(date = as.POSIXct(strptime(date, format = "%Y%m%d %H:%M:%S", "GMT")))
data_linet <- split(data_linet, data_linet$small_date) %>% 
  purrr::map(~mutate(.x, class = ifelse(class == 1, "CG", "IC")) %>% # Giving "IC/CG" names
               mutate(period = floor_date(date, "10 minutes"))) %>% # Making with the same timestep as the radar data
  map2(
    ., purrr::map(selected_fams, ~filter(.x, date %in% ymd_hm(dates_clusters_cappis)) %>% select(date) %>% unlist()),
    ~filter(.x, period %in% .y)
  ) %>% # Selecting the same times as the radar
  purrr::map(., ~group_by(.x, period) %>% nest()) %>% # Separating into a nested list (as selected_latlon)
  purrr::map(., ~set_names(.x$data, .x$period))
# modify_depth(., 2, mutate, period = floor_date(date, "10 minutes")) # and recreating "period" column
selected_latlon <- map2(selected_latlon, data_linet, ~.x[names(.y)]) # Selecting matching dates between clusters and lightning data
data_linet <- map2(
  data_linet, selected_latlon, # Matching with lat, lon with 0.02 degree "uncertainty"
  ~map2_df(..1, ..2, ~filter(.x, round(lon, 2) %in% c(.y$row, .y$row_m1, .y$row_p1, .y$row_m2, .y$row_p2) &
                               round(lat, 2) %in% c(.y$col, .y$col_m1, .y$col_p1, .y$col_m2, .y$col_p2)))
)

opt <- c("", "")
# opt <- c("", " ", "") # For less plots
data_linet_df <- map2(data_linet, opt, ~mutate(.x, case = paste("Case", lubridate::date(date), .y))) %>%
  map2(., data_hailpads$lon, ~mutate(.x, lon_hailpad = .y)) %>%
  map2(., data_hailpads$lat, ~mutate(.x, lat_hailpad = .y)) %>%
  map2(., data_hailpads$date, ~mutate(.x, date_hailpad = .y)) %>%
  map_df(rbind) %>%
  mutate(hour = date)
lubridate::date(data_linet_df$hour) <- lubridate::date(data_linet_df$date_hailpad) <- "2017-01-01"

totais <- select(data_linet_df, lat, lon, date, class, case)
qte_total <- totais %>%
  group_by(case, class) %>%
  count() %>%
  ungroup() %>%
  mutate(class = paste("Total", class, "=", n)) %>%
  select(case, class)
rcount <- select(data_linet_df, case, hour, class, date_hailpad) %>%
  mutate(case = str_replace(string = case, pattern = " ", replacement = "\n"))
height_rcount_linet <- select(data_linet_df, hour, class, case, z, date_hailpad) %>% 
  filter(class == "IC") %>% 
  mutate(case = str_replace(string = case, pattern = " ", replacement = "\n"))

# Plotting spatial distribution
theme_set(theme_grey())
grid <- data.frame("lon" = rep(c(-47.5, -46.5), 2), "lat" = rep(-22, 4)) # Label positions

ggplot(data = data_linet_df) +
  scale_x_continuous(limits = lims_in_plot$lon) + scale_y_continuous(limits = lims_in_plot$lat) +
  geom_point(aes(x = lon, y = lat, shape = class, color = hour)) +
  geom_point(aes(x = lon_hailpad, y = lat_hailpad), pch = 17, size = 2) +
  geom_path(data = fortify(cities), aes(long, lat, group = group), inherit.aes = F, colour = "gray50", size = 0.2) +
  geom_label(data = qte_total, aes(x = grid$lon, y = grid$lat, label = class), size = 3) +
  scale_color_distiller(palette = "Set1", breaks = pretty_breaks(n = 5), trans = time_trans()) +
  scale_shape_manual(values = c(4, 1)) +
  labs(x = "Longitude", y = "Latitude", color = "Time (UTC)", shape = "Type") +
  theme(
    legend.position = "bottom",
    plot.background = element_rect(fill = "transparent"),
    legend.background = element_rect(fill = "transparent")
  ) +
  guides(color = guide_colorbar(barwidth = 10)) +
  facet_wrap(~case)
ggsave("Lightning_Processing/figures/linet_location.png", width = 5.5, height = 3.25)

# Plotting temporal distribution
plt_linet <- ggplot(rcount) +
  geom_histogram(binwidth = 60, aes(x = hour, ..count.., fill = forcats::fct_rev(class))) +
  geom_vline(aes(xintercept = date_hailpad), linetype = "dashed") +
  scale_fill_manual(name = "Type", values = c("darkgoldenrod1", "darkorchid")) +
  theme(
    plot.background = element_rect(fill = "transparent"),
    legend.background = element_rect(fill = "transparent")
  ) +
  labs(x = "Hour (UTC)", y = "Strokes/min") +
  facet_grid(case ~ ., scales = "free")

plt_linet_height <- ggplot(height_rcount_linet) +
  geom_bin2d(aes(x = hour, y = z), binwidth = c(60, 1)) +
  geom_vline(aes(xintercept = date_hailpad), linetype = "dashed") +
  scale_fill_distiller(palette = "YlGnBu", breaks = pretty_breaks(n = 5), name = "Strokes/min/km") +
  guides(fill = guide_colorbar(barheight = 10)) +
  theme(
    plot.background = element_rect(fill = "transparent"),
    legend.background = element_rect(fill = "transparent")
  ) +
  labs(x = "Hour (UTC)", y = "Height (km)") +
  facet_grid(case ~ ., scales = "free_x")

# Saving variables
save.image("General_Processing/lifecycle_data.RData")
