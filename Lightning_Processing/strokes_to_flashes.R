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

# Defining main function -------------------------------------------------------
strokes_to_flashes <- function(lightning_df, min_pts = 1,
                               eps_location = 0.5, eps_time = 0.5){
  
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
    mutate(delta_stroke = date - lag(date), delta_lat = lat - first(lat),
           delta_lon = lon - first(lon), delta_z = z - first(z)) %>%
    ungroup()

  return(list(flashes_df, strokes_df))
}

# Testing minPts (k) of DBSCAN -------------------------------------------------
# kNNdistplot(df, k = 1)
# abline(h = 10, lty = 2)

# Applying function for BrasilDAT data -----------------------------------------
data_brasildat <- read_table("Lightning_Processing/filenames_brasildat", col_names = F) %>% 
  unlist() %>%
  purrr::map(read_csv) %>%
  purrr::map(~`colnames<-`(.x, c(
    "date", "lat", "lon", "z", "peak_curr", "class", "axis_bigger", # Reading files
    "axis_smaller", "angle", "nsp"
  ))) %>%
  purrr::map(~mutate(.x, class = ifelse(class == 0, "CG", "IC"))) # Giving "IC/CG" names 
# data_brasildat[[4]] <- NULL  # For statistics
flashes_brasildat <- purrr::map(data_brasildat, ~strokes_to_flashes(.x)[[1]])

# For statistics ---------------------------------------------------------------
# strokes_brasildat <- purrr::map(data_brasildat, ~strokes_to_flashes(.x)[[2]]) %>% 
#   map_df(rbind) %>% 
#   mutate(delta_stroke = as.numeric(delta_stroke))
# 
# flashes_brasildat_df <- flashes_brasildat %>% 
#   map_df(rbind) %>% 
#   arrange(date) %>% 
#   mutate(delta_time = as.numeric(date - lag(date)))

# - Plotting statistics --------------------------------------------------------
# theme_set(theme_grey())

# plt_inter <- ggplot() +
#   scale_x_log10(limits = c(1e-4, 2e2)) +
#   stat_density(data = strokes_brasildat, geom = "line",
#                aes(x = delta_stroke, y = ..count../1e4, color = "black")) +
#   stat_density(data = flashes_brasildat_df, geom = "line",
#                aes(x = delta_time, y = ..count../1e4, color = "blue")) +
#   scale_color_manual(values = c("black", "blue"),
#                      labels = c("Interstroke", "Interflash")) +
#   labs(x = "Time (s)", y = expression("Counts ("*10^4*")"), color = "")
# 
# plt_latlon <- ggplot(strokes_brasildat) +
#   scale_x_log10(limits = c(1e-5, 1e1)) +
#   stat_density(geom = "line",
#                aes(x = delta_lat, y = ..count../1e4, color = "red")) +
#   stat_density(geom = "line",
#                aes(x = delta_lon, y = ..count../1e4, color = "darkgreen")) +
#   scale_color_manual(values = c("red", "darkgreen"),
#                      labels = c("Latitude", "Longitude")) +
#   labs(x = expression("Distance ("*degree*")"),
#        y = expression("Counts ("*10^4*")"), color = "Distance on")
# 
# plt_strperflash <- ggplot() +
#   scale_x_continuous(limits = c(0, 40)) +
#   scale_y_log10(limits = c(1, 1e5)) +
#   stat_bin(data = flashes_brasildat_df, bins = 40,
#            aes(x = strokes, y = ..count..), color = "white") +
#   labs(x = "Number of Strokes per Flash", y = "Counts")
# 
# plot_grid(plt_inter, plt_latlon, plt_strperflash, nrow = 3,
#           labels = c("a", "b", "c"))

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
# strokes_linet <- purrr::map(data_linet, ~strokes_to_flashes(.x)[[2]]) %>% 
#   map_df(rbind) %>% 
#   mutate(delta_stroke = as.numeric(delta_stroke))
# 
# flashes_linet_df <- flashes_linet %>% 
#   map_df(rbind) %>% 
#   arrange(date) %>% 
#   mutate(delta_time = as.numeric(date - lag(date)))

# - Plotting statistics --------------------------------------------------------
# theme_set(theme_grey())

# plt_inter <- ggplot() +
#   scale_x_log10(limits = c(1e-4, 2e2)) +
#   stat_density(data = strokes_linet, geom = "line",
#                aes(x = delta_stroke, y = ..count../1e4, color = "black")) +
#   stat_density(data = flashes_linet_df, geom = "line",
#                aes(x = delta_time, y = ..count../1e4, color = "blue")) +
#   scale_color_manual(values = c("black", "blue"),
#                      labels = c("Interstroke", "Interflash")) +
#   labs(x = "Time (s)", y = expression("Counts ("*10^4*")"), color = "")
# 
# plt_latlon <- ggplot(strokes_linet) +
#   scale_x_log10(limits = c(1e-5, 1e1)) +
#   stat_density(geom = "line",
#                aes(x = delta_lat, y = ..count../1e4, color = "red")) +
#   stat_density(geom = "line",
#                aes(x = delta_lon, y = ..count../1e4, color = "darkgreen")) +
#   scale_color_manual(values = c("red", "darkgreen"),
#                      labels = c("Latitude", "Longitude")) +
#   labs(x = expression("Distance ("*degree*")"),
#        y = expression("Counts ("*10^4*")"), color = "Distance on")
# 
# plt_strperflash <- ggplot() +
#   scale_x_continuous(limits = c(0, 40)) +
#   scale_y_log10(limits = c(1, 1e5)) +
#   stat_bin(data = flashes_linet_df, bins = 40,
#            aes(x = strokes, y = ..count..), color = "white") +
#   labs(x = "Number of Strokes per Flash", y = "Counts")
# 
# plot_grid(plt_inter, plt_latlon, plt_strperflash, nrow = 3,
#           labels = c("a", "b", "c"))

