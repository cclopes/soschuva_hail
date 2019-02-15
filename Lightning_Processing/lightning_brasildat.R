#-------------------------------------------------------------------------------
# Importing entries from "processing_fortracc.R"
# Reading lightning data from BrasilDAT
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
require(cptcity)
load("ForTraCC_Processing/fortracc_data.RData") # Loading data from ForTraCC
source("Lightning_Processing/strokes_to_flashes.R")

# Updating selected_clusters and -----------------------------------------------
# creating selected_latlon with the whole families -----------------------------
selected_clusters <-
  purrr::map(
    purrr::map(selected_fams, ~select(.x, date) %>% unlist()),
    ~which(ymd_hm(dates_clusters_cappis) %in% .x, arr.ind = T) %>% data_clusters[.]
  ) %>%
  map2(
    ., purrr::map(selected_fams, ~filter(.x, date %in% ymd_hm(dates_clusters_cappis)) %>% column_to_rownames(., "date")) %>%
      purrr::map(., select, sys) %>% purrr::map(~split(.x, row.names(.x)) %>% flatten),
    ~map2(..1, ..2, ~which(.x == .y, arr.ind = T))
  ) %>%
  modify_depth(., 2, as.data.frame)
selected_latlon <- modify_depth(selected_clusters, 2, mutate,
  lon_r = round(lon_vector[row]/0.1)*0.1, lat_r = round(lat_vector[col]/0.1)*0.1
) %>%
  map2(., purrr::map(selected_fams, ~filter(.x, date %in% ymd_hm(dates_clusters_cappis)) %>%
    select(date) %>%
    unlist()), ~set_names(.x, as_datetime(.y))) #%>%
  # modify_depth(., 2, mutate,
  #   row_m1 = row - 0.01, row_p1 = row + 0.01, col_m1 = col - 0.01, col_p1 = col + 0.01,
  #   row_m2 = row - 0.02, row_p2 = row + 0.02, col_m2 = col - 0.02, col_p2 = col + 0.02
  # )
#--- If necessary, put timestamps in the clusters coordinates data
# selected_latlon <- map2(selected_latlon, purrr::map(selected_fams, ~filter(.x, date %in% ymd_hm(dates_clusters_cappis)) %>%
#                                                select(date) %>% unlist),
#                         ~map2(..1, ..2, ~mutate(.x, date = as_datetime(.y))))


# Reading/processing lightning data (strokes) ----------------------------------
data_brasildat <- read_table("Lightning_Processing/filenames_brasildat", col_names = F) %>% 
  distinct() %>% unlist() %>%
# data_brasildat <- read_table("Lightning_Processing/filenames_brasildat_less", col_names = F) %>%
  # unlist() %>% # For less plots 
  purrr::map(read_csv) %>%
  purrr::map(~`colnames<-`(.x, c(
    "date", "lat", "lon", "z", "peak_curr", "class", "axis_bigger", # Reading files
    "axis_smaller", "angle", "nsp"
  ))) %>%
  purrr::map(~mutate(.x, class = ifelse(class == 0, "CG", "IC"), lon_r = round(lon/0.1)*0.1, lat_r = round(lat/0.1)*0.1) %>% # Giving "IC/CG" names 
    mutate(period = floor_date(date, "10 minutes"))) %>% # Making with the same timestep as the radar data
  map2(
    ., purrr::map(selected_fams, ~filter(.x, date %in% ymd_hm(dates_clusters_cappis)) %>% select(date) %>% unlist()),
    ~filter(.x, period %in% .y)
  ) %>% # Selecting the same times as the radar
  purrr::map(., ~group_by(.x, period) %>% nest()) %>% # Separating into a nested list (as selected_latlon)
  purrr::map(., ~set_names(.x$data, .x$period))
# modify_depth(., 2, mutate, period = floor_date(date, "10 minutes")) # and recreating "period" column
selected_latlon <- map2(selected_latlon, data_brasildat, ~.x[names(.y)]) # Selecting matching dates between clusters and
 # lightning data
data_brasildat <- map2(
  data_brasildat, selected_latlon, # Matching with lat, lon with 0.02 degrees "uncertainty"
  ~map2_df(..1, ..2, ~semi_join(.x, .y))
  # ~map2_df(..1, ..2, ~filter(.x, round(lon, 2) %in% c(.y$row, .y$row_m1, .y$row_p1, .y$row_m2, .y$row_p2) &
  #   round(lat, 2) %in% c(.y$col, .y$col_m1, .y$col_p1, .y$col_m2, .y$col_p2)))
)

# Reading/processing lightning data (flashes) ----------------------------------
flashes_brasildat <- flashes_brasildat %>% 
  purrr::map(~mutate(.x, lon_r = round(lon/0.1)*0.1, lat_r = round(lat/0.1)*0.1)) %>%
  purrr::map(~mutate(.x, period = floor_date(date, "10 minutes"))) %>% # Making with the same timestep as the radar data
  map2(
    ., purrr::map(selected_fams, ~filter(.x, date %in% ymd_hm(dates_clusters_cappis)) %>% select(date) %>% unlist()),
    ~filter(.x, period %in% .y)
  ) %>% # Selecting the same times as the radar
  purrr::map(., ~group_by(.x, period) %>% nest()) %>% # Separating into a nested list (as selected_latlon)
  purrr::map(., ~set_names(.x$data, .x$period))
# modify_depth(., 2, mutate, period = floor_date(date, "10 minutes")) # and recreating "period" column
selected_latlon <- map2(selected_latlon, flashes_brasildat, ~.x[names(.y)]) # Selecting matching dates between clusters and
# lightning data
flashes_brasildat <- map2(
  flashes_brasildat, selected_latlon, # Matching with lat, lon with 0.02 degrees "uncertainty"
  ~map2_df(..1, ..2, ~semi_join(.x, .y))
  # ~map2_df(..1, ..2, ~filter(.x, round(lon, 2) %in% c(.y$row, .y$row_m1, .y$row_p1, .y$row_m2, .y$row_p2) &
  #                              round(lat, 2) %in% c(.y$col, .y$col_m1, .y$col_p1, .y$col_m2, .y$col_p2)))
)

opt <- c("", "", "", "", "")
# opt <- c("", " ", "") # For less plots
data_brasildat_df <- map2(data_brasildat, opt, ~mutate(.x, case = paste("Case", lubridate::date(date), .y))) %>%
  map2(., data_hailpads$lon, ~mutate(.x, lon_hailpad = .y)) %>%
  map2(., data_hailpads$lat, ~mutate(.x, lat_hailpad = .y)) %>%
  map2(., data_hailpads$date, ~mutate(.x, date_hailpad = .y)) %>%
  map_df(rbind) %>%
  mutate(hour = date)
lubridate::date(data_brasildat_df$hour) <- lubridate::date(data_brasildat_df$date_hailpad) <- "2017-01-01"
data_brasildat_df$lon_hailpad[data_brasildat_df$case == "Case 2017-03-14 "][1] <- selected_fams_df$lon_hailpad[selected_fams_df$case == "Case 2017-03-14 "][1]
data_brasildat_df$lat_hailpad[data_brasildat_df$case == "Case 2017-03-14 "][1] <- selected_fams_df$lat_hailpad[selected_fams_df$case == "Case 2017-03-14 "][1]
data_brasildat_df$date_hailpad[data_brasildat_df$case == "Case 2017-03-14 "][1] <- "2017-01-01 18:00:00"
data_brasildat_df$case <- str_replace(data_brasildat_df$case, "Case ", "Caso de ")  # pt-br

totais <- select(data_brasildat_df, lat, lon, date, class, case)
qte_total <- totais %>%
  group_by(case, class) %>%
  count() %>%
  ungroup() %>%
  mutate(class = paste("Total", class, "=", n)) %>%
  select(case, class)
rcount <- select(data_brasildat_df, case, hour, class, date_hailpad) %>%
  mutate(case = str_replace(string = case, pattern = " ", replacement = "\n"))

flashes_brasildat_df <- map2(flashes_brasildat, opt, ~mutate(.x, case = paste("Case", lubridate::date(date), .y))) %>%
  map2(., data_hailpads$lon, ~mutate(.x, lon_hailpad = .y)) %>%
  map2(., data_hailpads$lat, ~mutate(.x, lat_hailpad = .y)) %>%
  map2(., data_hailpads$date, ~mutate(.x, date_hailpad = .y)) %>%
  map_df(rbind) %>%
  mutate(hour = date)
lubridate::date(flashes_brasildat_df$hour) <- lubridate::date(flashes_brasildat_df$date_hailpad) <- "2017-01-01"
flashes_brasildat_df$lon_hailpad[flashes_brasildat_df$case == "Case 2017-03-14 "][1] <- selected_fams_df$lon_hailpad[selected_fams_df$case == "Case 2017-03-14 "][1]
flashes_brasildat_df$lat_hailpad[flashes_brasildat_df$case == "Case 2017-03-14 "][1] <- selected_fams_df$lat_hailpad[selected_fams_df$case == "Case 2017-03-14 "][1]
flashes_brasildat_df$date_hailpad[flashes_brasildat_df$case == "Case 2017-03-14 "][1] <- "2017-01-01 18:00:00"
flashes_brasildat_df$case <- str_replace(flashes_brasildat_df$case, "Case ", "Caso de ")  # pt-br

flashes_totais <- select(flashes_brasildat_df, lat, lon, date, class, case)
flashes_qte_total <- flashes_totais %>%
  group_by(case, class) %>%
  count() %>%
  ungroup() %>%
  mutate(class = paste("Total", class, "=", n)) %>%
  select(case, class)
flashes_rcount <- select(flashes_brasildat_df, case, hour, class, date_hailpad) %>%
  # mutate(case = str_replace(string = case, pattern = " ", replacement = "\n"))
  mutate(case = str_replace(string = case, pattern = "de ", replacement = "de\n"))  # pt-br

# Plotting spatial distribution ------------------------------------------------
theme_set(theme_bw())
grid <- data.frame("lon" = rep(c(-47.5, -46.5), 5), "lat" = rep(-22, 10)) # Label positions
# grid <- data.frame("lon" = rep(c(-47.5, -46.5), 3), "lat" = rep(-22, 6)) # Label positions for less plots

ggplot(data = data_brasildat_df) +
  scale_x_continuous(limits = lims_in_plot$lon) + scale_y_continuous(limits = lims_in_plot$lat) +
  geom_point(aes(x = lon, y = lat, shape = class, color = hour)) +
  geom_point(aes(x = lon_hailpad, y = lat_hailpad), pch = 17, size = 2) +
  geom_path(data = fortify(cities), aes(long, lat, group = group), inherit.aes = F, colour = "gray50", size = 0.2) +
  geom_label(data = qte_total, aes(x = grid$lon, y = grid$lat, label = class), size = 3, inherit.aes = F) +
  scale_color_gradientn(colours = cpt(pal = "oc_zeu"), labels = date_format("%H%M"),
                        breaks = pretty_breaks(n = 10), trans = time_trans()) +
  scale_shape_manual(values = c(4, 1)) +
  # labs(x = expression("Longitude ("*degree*")"), y = expression("Latitude ("*degree*")"),
  #      color = "Time (UTC)", shape = "Stroke\nType") +
  labs(x = expression("Longitude ("*degree*")"), y = expression("Latitude ("*degree*")"),
       color = "Hora (UTC)", shape = "Tipo de\nStroke") +  # pt-br
  guides(size = "none", color = guide_colorbar(barheight = 12)) +
  theme(
    plot.background = element_rect(fill = "transparent", color = "transparent"),
    legend.background = element_rect(fill = "transparent")
  ) +
  # theme(legend.position = "bottom") + # For less plots
  # guides(size = "none", color = guide_colorbar(barwidth = 15)) + # For less plots
  facet_wrap(~case)
# ggsave("Lightning_Processing/figures/brasildat_location.png", bg = "transparent",
#        width = 8.5, height = 4.25)
ggsave("Lightning_Processing/figures/brasildat_location_ptbr.png", bg = "transparent",
       width = 8.5, height = 4.25)  # pt-br
# ggsave("Lightning_Processing/figures/brasildat_location_less.png", width = 7.5, height = 3.25, bg = "transparent") # For less plots

ggplot(data = flashes_brasildat_df) +
  scale_x_continuous(limits = lims_in_plot$lon) + scale_y_continuous(limits = lims_in_plot$lat) +
  geom_point(aes(x = lon, y = lat, shape = class, color = hour)) +
  geom_point(aes(x = lon_hailpad, y = lat_hailpad), pch = 17, size = 2) +
  geom_path(data = fortify(cities), aes(long, lat, group = group), inherit.aes = F, colour = "gray50", size = 0.2) +
  geom_label(data = flashes_qte_total, aes(x = grid$lon, y = grid$lat, label = class), size = 3) +
  scale_color_gradientn(colours = cpt(pal = "oc_zeu"), labels = date_format("%H%M"),
                        breaks = pretty_breaks(n = 10), trans = time_trans()) +
  scale_shape_manual(values = c(4, 1)) +
  # labs(x = expression("Longitude ("*degree*")"), y = expression("Latitude ("*degree*")"),
  #      color = "Time (UTC)", shape = "Flash\nType") +
  labs(x = expression("Longitude ("*degree*")"), y = expression("Latitude ("*degree*")"),
       color = "Hora (UTC)", shape = "Tipo de\nFlash") +  # pt-br
  guides(size = "none", color = guide_colorbar(barheight = 12)) +
  theme(
    plot.background = element_rect(fill = "transparent", color = "transparent"),
    legend.background = element_rect(fill = "transparent")
  ) +
  # theme(legend.position = "bottom") + # For less plots
  # guides(size = "none", color = guide_colorbar(barwidth = 15)) + # For less plots
  facet_wrap(~case)
# ggsave("Lightning_Processing/figures/brasildat_flash_location.png", bg = "transparent",
#        width = 8.5, height = 4.25)
ggsave("Lightning_Processing/figures/brasildat_flash_location_ptbr.png", bg = "transparent",
       width = 8.5, height = 4.25)  # pt-br
# ggsave("Lightning_Processing/figures/brasildat_flash_location_less.png", width = 7.5, height = 3.25, bg = "transparent") # For less plots

# Plotting temporal distribution
plt_brasildat <- ggplot(rcount) +
  scale_x_datetime(labels = date_format("%H%M")) +
  geom_histogram(binwidth = 60, aes(x = hour, ..count.., fill = forcats::fct_rev(class))) +
  geom_vline(aes(xintercept = date_hailpad), linetype = "dashed") +
  scale_fill_manual(values = c("darkgoldenrod1", "darkorchid")) +
  theme(
    plot.background = element_rect(fill = "transparent", color = "transparent"),
    legend.background = element_rect(fill = "transparent"),
    legend.position = "bottom"
  ) +
  # labs(x = "Time (UTC)", y = expression("Strokes"~min^-1), fill = "Type") +
  labs(x = "Hora (UTC)", y = expression("Strokes"~min^-1), fill = "Tipo") +  # pt-br
  facet_wrap(case ~ ., scales = "free", ncol = 1, strip.position = 'right')

plt_flash_brasildat <- ggplot(flashes_rcount) +
  scale_x_datetime(labels = date_format("%H%M")) +
  geom_histogram(binwidth = 60, aes(x = hour, ..count.., fill = forcats::fct_rev(class))) +
  geom_vline(aes(xintercept = date_hailpad), linetype = "dashed") +
  scale_fill_manual(values = c("darkgoldenrod1", "darkorchid")) +
  theme(
    plot.background = element_rect(fill = "transparent", color = "transparent"),
    legend.background = element_rect(fill = "transparent"),
    legend.position = "bottom"
  ) +
  # labs(x = "Time (UTC)", y = expression("Flashes"~min^-1), fill = "Type") +
  labs(x = "Hora (UTC)", y = expression("Flashes"~min^-1), fill = "Tipo") +  # pt-br
  facet_wrap(case ~ ., scales = "free", ncol = 1, strip.position = 'right')

# Saving variables
save.image("General_Processing/lifecycle_data.RData")
