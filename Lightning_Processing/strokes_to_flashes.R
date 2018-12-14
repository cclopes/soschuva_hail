#-------------------------------------------------------------------------------
# Defining strokes_to_flashes function
# Reading lightning data from BrasilDAT and LINET
# Applying functions, defining flashes_brasildat and flashes_linet
#-------------------------------------------------------------------------------

# Loading necessary scripts and packages ---------------------------------------
require(dbscan)
require(tidyverse)
require(magrittr)
require(lubridate)
require(cowplot)
require(colorspace)
require(scales)

# Defining main function -------------------------------------------------------
strokes_to_flashes <- function(lightning_df, min_pts = 1,
                               eps_location = 0.025, eps_time = 0.5){
  
  # Clusters strokes data into flashes using DBSCAN
  
  # Parameters:
  # -----------
  # lightning_df: lightning dataframe with the following information
  #   - date (POSIXct format supported)
  #   - latitude (lat), longitude (lon), height(z) location
  #   - peak current (peak_curr)
  #   - IC/CG classification (class)
  #   - other columns are ignored.
  # min_pts: Minimum points to be used in both steps of DBSCAN
  # eps_location: location interval (degrees)
  # eps_time: time interval (seconds)
  
  # Returns:
  # --------
  # lightning_df: dataframe with date, lat, lon, peak_curr, class and
  #   number of strokes
  # strokes_df: dataframe with date, delta_stroke, delta_y, delta_x and
  #   delta_z for flash statistics
  
  # Step 1: Clustering according to time only
  time_df <- (hour(lightning_df$date)*3600 + minute(lightning_df$date)*60 + 
                second(lightning_df$date)) %>% as.matrix()
  # fr <- frNN(time_df, eps = eps_time)
  # return(fr)
  lightning_df$clusters_time <- dbscan(time_df, eps = eps_time, 
                                       minPts = min_pts)$cluster

  # Creating function to be applied on lightning_df
  dbfun <- function(df) dbscan(as.matrix(df[, c("lat", "lon")]),
                               eps = eps_location, minPts = min_pts)$cluster

  # Step 2: Clusters according to location
  lightning_df %<>%
    group_by(clusters_time) %>%
    nest() %>%
    mutate(clusters_latlon = purrr::map(data, dbfun)) %>%
    unnest()

  # Join time and location clustering, getting flash information
  flashes_df <- lightning_df %>%
    group_by(clusters_time, clusters_latlon) %>%
    arrange(date) %>%
    summarise(date = first(date), lat = first(lat), lon = first(lon),
              z = first(z), peak_curr = first(peak_curr),
              class = ifelse(any(class == "CG"), "CG", "IC"),
              strokes = n()) %>%
    ungroup() %>%
    select(date, lat, lon, z, peak_curr, class, strokes)

  # Join time and location clustering, keeping stroke information for statistics
  strokes_df <- lightning_df %>%
    group_by(clusters_time, clusters_latlon) %>%
    arrange(date) %>%
    mutate(delta_stroke = date - lag(date), delta_y = (lat - first(lat))*100,
           delta_x = (lon - first(lon))*100, delta_z = z - first(z)) %>%
    ungroup()

  return(list(flashes_df, strokes_df))
}

# Testing minPts (k) of DBSCAN -------------------------------------------------
# kNNdistplot(df, k = 1)
# abline(h = 10, lty = 2)

# Applying function for BrasilDAT data -----------------------------------------
data_brasildat <- read_table("Lightning_Processing/filenames_brasildat", col_names = F) %>% 
  distinct() %>% # REMOVING SECOND 2017-03-14 FAMILY
  unlist() %>%
  purrr::map(read_csv) %>%
  purrr::map(~`colnames<-`(.x, c(
    "date", "lat", "lon", "z", "peak_curr", "class", "axis_bigger", # Reading files
    "axis_smaller", "angle", "nsp"
  ))) %>%
  purrr::map(~mutate(.x, class = ifelse(class == 0, "CG", "IC"))) # Giving "IC/CG" names 
flashes_brasildat <- purrr::map(data_brasildat, ~strokes_to_flashes(.x)[[1]])

# For statistics ---------------------------------------------------------------
# strokes_brasildat <- purrr::map(data_brasildat, ~strokes_to_flashes(.x)[[2]]) %>%
#   map_df(rbind) %>%
#   mutate(delta_stroke = as.numeric(delta_stroke)) %>% 
#   na_if(0)
# 
# flashes_brasildat_df <- flashes_brasildat %>%
#   map_df(rbind) %>%
#   arrange(date) %>%
#   mutate(delta_time = as.numeric(date - lag(date)))

# - Plotting statistics --------------------------------------------------------
# theme_set(theme_bw())
# 
# plt_inter <- ggplot() +
#   scale_x_log10(limits = c(1e-4, 2e2)) +
#   stat_density(data = strokes_brasildat, geom = "line",
#                aes(x = delta_stroke, y = ..count../1e4, color = "black")) +
#   stat_density(data = flashes_brasildat_df, geom = "line",
#                aes(x = delta_time, y = ..count../1e4, color = "blue")) +
#   scale_color_manual(values = c("black", "blue"),
#                      labels = c("Interstroke", "Interflash")) +
#   theme(legend.position = "bottom", legend.box.margin = margin(-10, 0, 0, 0),
#         plot.margin = unit(c(2, 2, 0.5, 2), "mm"),
#         plot.background = element_rect(fill = "transparent"),
#         legend.background = element_rect(fill = "transparent")) +
#   labs(x = "Time (s)", y = expression("Counts ("*10^4*")"), color = "")
# 
# plt_dist <- ggplot(strokes_brasildat, aes(x = delta_x, y = delta_y)) +
#   coord_cartesian(xlim = c(-6, 6), ylim = c(-6, 6)) +
#   geom_bin2d(binwidth = 0.1) +
#   scale_fill_gradientn(name = "Counts", 
#                        colors = heat_hcl(n = 1000, h = c(0, -100), l = c(95, 40),
#                                          c = c(40, 80), power = 4),
#                        breaks = pretty_breaks(n = 4)) +
#   theme(legend.position = "bottom",
#         plot.background = element_rect(fill = "transparent"),
#         legend.background = element_rect(fill = "transparent")) +
#   guides(fill = guide_colorbar(barwidth = 7)) +
#   labs(x = "Longitudinal Distance (km)", y = "Latitudinal Distance (km)")

# ggplot(strokes_brasildat, aes(x = delta_x, y = delta_y)) +
#   coord_cartesian(xlim = c(-6, 6), ylim = c(-6, 6)) +
#   geom_bin2d(binwidth = 0.1) +
#   scale_fill_distiller(name = "Counts", 
#                        palette = "Set1", 
#                        breaks = pretty_breaks(n = 20),
#                        direction = 1,
#                        limits = c(1, 40),
#                        oob = squish) +
#   theme(legend.position = "bottom",
#         plot.background = element_rect(fill = "transparent"),
#         legend.background = element_rect(fill = "transparent")) +
#   guides(fill = guide_colorbar(barwidth = 25)) +
#   labs(x = "Longitudinal Distance (km)", y = "Latitudinal Distance (km)")

# plt_strperflash <- ggplot(data = flashes_brasildat_df, 
#                           aes(x = strokes, y = ..count..)) +
#   scale_x_continuous(limits = c(0, 21)) +
#   scale_y_log10(limits = c(1, 1e5)) +
#   stat_bin(binwidth = 1, color = "white") +
#   labs(x = "Number of Strokes per Flash", y = "Counts") +
#   theme(plot.background = element_rect(fill = "transparent"),
#         legend.background = element_rect(fill = "transparent"))

# plg <- plot_grid(plot_grid(plt_inter, plt_strperflash, labels = c("a", "b"), 
#                     nrow = 2, rel_heights = c(0.55, 0.45), label_y = c(0.2, 0.2)), 
#           plt_dist, ncol = 2,
#           rel_widths = c(0.6, 0.4), labels = c("", "c"), label_y = c(0, 0.1))
# save_plot("Lightning_Processing/figures/brasildat_flash_stats.png", plg,
#           base_width = 6.5, base_height = 3.25, bg = "transparent")

# Applying function for LINET data ---------------------------------------------
data_linet <- read_table("Lightning_Processing/filenames_linet", col_names = F) %>%
  unlist() %>%
  purrr::map(~read_table2(.x, col_names = F,
                          col_types = cols(X1 = "i", X2 = "c", X3 = "d", X4 = "d",
                                           X5 = "d", X6 = "i", X7 = "d", X8 = "d"))) %>% 
  map_df(rbind) %>% 
  set_colnames(c("small_date", "time", "lat", "lon", "z", "class", "peak_curr", "none")) %>% 
  mutate(date = paste(small_date, time)) %>% 
  mutate(date = as.POSIXct(strptime(date, format = "%Y%m%d %H:%M:%OS", "GMT"))) %>% 
  split(., .$small_date) %>% 
  purrr::map(~mutate(.x, class = ifelse(class == 1, "CG", "IC"))) # Giving "IC/CG" names
flashes_linet <- purrr::map(data_linet, ~strokes_to_flashes(.x)[[1]])

# For statistics ---------------------------------------------------------------
# strokes_linet <- purrr::map(data_linet,
#                             ~strokes_to_flashes(.x)[[2]]) %>%
#   map_df(rbind) %>%
#   mutate(delta_stroke = as.numeric(delta_stroke)) %>% 
#   na_if(0)
# 
# flashes_linet_df <- flashes_linet %>%
#   map_df(rbind) %>%
#   arrange(date) %>%
#   mutate(delta_time = as.numeric(date - lag(date)))

# - Plotting statistics --------------------------------------------------------
# theme_set(theme_bw())
# 
# plt_inter <- ggplot() +
#   scale_x_log10(limits = c(1e-4, 2e2)) +
#   stat_density(data = strokes_linet, geom = "line",
#                aes(x = delta_stroke, y = ..count../1e4, color = "black")) +
#   stat_density(data = flashes_linet_df, geom = "line",
#                aes(x = delta_time, y = ..count../1e4, color = "blue")) +
#   scale_color_manual(values = c("black", "blue"),
#                      labels = c("Interstroke", "Interflash")) +
#   theme(legend.position = "bottom", legend.box.margin = margin(-10, 0, 0, 0),
#         plot.margin = unit(c(2, 2, 0.5, 2), "mm"),
#         plot.background = element_rect(fill = "transparent"),
#         legend.background = element_rect(fill = "transparent")) +
#   labs(x = "Time (s)", y = expression("Counts ("*10^4*")"), color = "")
# 
# plt_dist <- ggplot(strokes_linet, aes(x = delta_x, y = delta_y)) +
#   coord_cartesian(xlim = c(-6, 6), ylim = c(-6, 6)) +
#   geom_bin2d(binwidth = 0.1) +
#   scale_fill_gradientn(name = "Counts", 
#                        colors = heat_hcl(n = 1000, h = c(0, -100), l = c(95, 40),
#                                          c = c(40, 80), power = 4),
#                        breaks = pretty_breaks(n = 4)) +
#   theme(legend.position = "bottom",
#         plot.background = element_rect(fill = "transparent"),
#         legend.background = element_rect(fill = "transparent")) +
#   guides(fill = guide_colorbar(barwidth = 7)) +
#   labs(x = "Longitudinal Distance (km)", y = "Latitudinal Distance (km)")
# 
# plt_strperflash <- ggplot(data = flashes_linet_df, 
#                           aes(x = strokes, y = ..count..)) +
#   scale_x_continuous(limits = c(0, 21)) +
#   scale_y_log10(limits = c(1, 1e5)) +
#   stat_bin(binwidth = 1, color = "white") +
#   labs(x = "Number of Strokes per Flash", y = "Counts") +
#   theme(plot.background = element_rect(fill = "transparent"),
#         legend.background = element_rect(fill = "transparent"))
# 
# plg <- plot_grid(plot_grid(plt_inter, plt_strperflash, labels = c("a", "b"), 
#                            nrow = 2, rel_heights = c(0.55, 0.45), label_y = c(0.2, 0.2)), 
#                  plt_dist, ncol = 2,
#                  rel_widths = c(0.6, 0.4), labels = c("", "c"), label_y = c(0, 0.1))
# save_plot("Lightning_Processing/figures/linet_flash_stats.png", plg,
#           base_width = 6.5, base_height = 3.25, bg = "transparent")
