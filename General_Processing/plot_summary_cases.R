# ------------------------------------------------------------------------------
# READING PRE-PROCESSED CLUSTERS AND LIGHTNING DATA AND PLOTTING
# Summary figs (system evolution during hailfall, lifecycle)
# ------------------------------------------------------------------------------

# Loading required packages ----------------------------------------------------

require(sf)
require(tidyverse)
require(lubridate)
require(reshape2)
require(ggalt)
require(scales)
require(cowplot)

# Defining functions -----------------------------------------------------------

# Selecting data of a given step/timestamp
get_data_step <- function(selected_fam_i, selected_clusters_i, selected_cappis_i, list_out) {
  clusters <- list_out[[1]]
  cappis <- list_out[[2]]
  flashes <- list_out[[3]]
  qte_flashes <- list_out[[4]]
  
  selected_date <- selected_fam_i$date
  name <- paste("SR", format.Date(selected_date, "%Y-%m-%d %H%M"), "UTC")
  selected_sys <- selected_fam_i$sys

  test <- matrix(unlist(selected_clusters_i), ncol = 500, byrow = T)
  row.names(test) <- sort(lat_vector, decreasing = F)
  colnames(test) <- lon_vector
  test_clusters <- reshape2::melt(test) %>%
    na.omit() %>%
    filter(value != selected_sys) %>%
    mutate(name = name)
  clusters <- rbind(clusters, test_clusters) %>% na.omit()

  test <- matrix(unlist(selected_cappis_i), ncol = 500, byrow = T)
  row.names(test) <- sort(lat_vector, decreasing = F)
  colnames(test) <- lon_vector
  test <- reshape2::melt(test) %>%
    na.omit() %>%
    mutate(name = name)
  cappis <- rbind(cappis, test) %>% na.omit()

  selected_flash <- selected_flashes %>%
    filter(
      (selected_flashes$date >= selected_date) &
        (selected_flashes$date < (selected_date + 600))
    ) %>%
    mutate(name = name)
  flashes <- rbind(flashes, selected_flash) %>% na.omit()

  selected_totais <- dplyr::select(selected_flash, lat, lon, date, class, case)
  selected_flash_total <- selected_totais %>%
    group_by(case, class) %>%
    count() %>%
    ungroup() %>%
    mutate(class = paste(class, "=", n), name = name) %>%
    dplyr::select(case, class, name)
  qte_flashes <- rbind(qte_flashes, selected_flash_total) %>% na.omit()
  
  return(list(clusters, cappis, flashes, qte_flashes))
}

# Generating first panel (reflectivity + lightning panel before/during/after)
plot_z_lightning_panel <- function(grid, pad) {
  # Plot settings
  theme_set(theme_bw())
  theme_update(plot.title = element_text(hjust = 0.5))
  
  plt <- ggplot() +
    # Reflectivity
    geom_raster(data = cappis, aes(x = Var2, y = Var1, fill = value)) +
    # ForTraCC clusters "smoothing"
    geom_raster(
      data = clusters, aes(x = Var2, y = Var1),
      fill = "white", alpha = 0.82
    ) +
    # Shapefiles
    geom_sf(data = cities, fill = NA, size = 0.25) +
    geom_sf(data = cities_highlight, fill = NA, size = 0.5, colour = "gray20") +
    # Lightning
    geom_point(
      data = flashes,
      aes(x = lon, y = lat, shape = forcats::fct_rev(class)),
      size = 0.75, fill = "white"
    ) +
    # Hailpad location
    geom_point(
      data = selected_hailpad, aes(x = lon, y = lat),
      pch = 24, size = 2, color = "black", fill = "cyan"
    ) +
    geom_label(
      data = filter(qte_flashes, str_detect(class, "IC")), 
      aes(x = grid$lon - pad, y = grid$lat, label = class),
      size = 3
    ) +
    geom_label(
      data = filter(qte_flashes, str_detect(class, "CG")), 
      aes(x = grid$lon + pad, y = grid$lat, label = class),
      size = 3
    ) + 
    # Limits
    coord_sf(xlim = lims_in_plot$lon, ylim = lims_in_plot$lat, expand = F) +
    scale_fill_gradientn(
      colours = c("#99CCFF", "#18A04C", "#FFDF8E", "#D64646", "#0F0D0D"),
      breaks = seq(0, 70, 10), limits = c(0, 70), guide = "legend"
    ) +
    scale_shape_manual(name = "Type", values = c(21, 4)) +
    labs(
      x = "", y = expression("Latitude (" * degree * ")"),
      fill = "Reflectivity (dBZ)"
    ) +
    guides(fill = guide_colorbar(
      title.position = "right", 
      title.theme = element_text(angle = 90), 
      title.hjust = 0.5, barheight = 8)) +
    theme(
      plot.background = element_rect(fill = "transparent", color = "transparent"),
      legend.background = element_rect(fill = "transparent", color = "transparent"),
      legend.position = "right"
    ) +
    facet_grid(. ~ name)

  return(plt)
}

# Generating second panel (IWC, area, lightning lifecycle)
plot_lifecycle <- function(case_name) {
  # Plot settings
  theme_set(theme_bw())
  theme_update(plot.title = element_text(hjust = 0.5))
  
  plt_1 <- ggplot(data = total_im %>% filter(case == case_name)) +
    scale_x_datetime(labels = date_format("%H%M")) +
    geom_path(aes(x = hour, y = im, color = level)) +
    geom_point(aes(x = hour, y = im, color = level), shape = 1) +
    geom_vline(aes(xintercept = date_hailpad), linetype = "dashed") +
    scale_y_log10() +
    scale_color_manual(values = c("#bdc9e1", "#2b8cbe", "#045a8d")) +
    theme(
      plot.background = element_rect(fill = "transparent", color = "transparent"),
      legend.background = element_rect(fill = "transparent"),
      axis.title.x = element_blank()
    ) +
    labs(y = expression("Total Ice Mass (" * kg * ")"), color = "")
  
  plt_2 <- ggplot(data = selected_fam) +
    scale_x_datetime(labels = date_format("%H%M")) +
    geom_path(aes(x = hour, y = size), color = "tomato") +
    geom_point(aes(x = hour, y = size), color = "tomato", shape = 1) +
    geom_vline(aes(xintercept = date_hailpad), linetype = "dashed") +
    theme(
      plot.background = element_rect(fill = "transparent", color = "transparent"),
      legend.background = element_rect(fill = "transparent"),
      axis.title.x = element_blank()
    ) +
    labs(y = expression("Area (" * km^2 * ")"))
  
  plt_3 <- ggplot(filter(flashes_rcount, case == case_name)) +
    scale_x_datetime(labels = date_format("%H%M")) +
    geom_histogram(binwidth = 60, aes(x = hour, ..count.., fill = forcats::fct_rev(class))) +
    geom_vline(aes(xintercept = date_hailpad), linetype = "dashed") +
    scale_fill_manual(values = c("darkgoldenrod1", "darkorchid")) +
    theme(
      plot.background = element_rect(fill = "transparent", color = "transparent"),
      legend.background = element_rect(fill = "transparent"),
      legend.position = "right",
      legend.justification = "left"
    ) +
    labs(x = "Time (UTC)", y = expression("Flashes" ~ min^-1), fill = "Type")
  
  if(case_name == "Case 1\n2017-03-14"){
    labels <- c("c", "d", "e")
  }
  else{
    labels <- c("b", "c", "d")
  }
  
  plt <- plot_grid(
    plot_grid(plt_1 + theme(legend.position = "none"), plt_2, plt_3 + theme(legend.position = "none"), 
              ncol = 1, align = "v", labels = labels, 
              rel_heights = c(0.43, 0.43, 0.5)
    ),
    plot_grid(get_legend(plt_1),
              ggplot() +
                theme_void(),
              get_legend(plt_3),
              ggplot() +
                theme_void(),
              ncol = 1, align = "hv", axis = "l", 
              rel_heights = c(0.5, 0.5, 0.5, 0.1)
    ),
    ncol = 2, rel_widths = c(0.7, 0.1), align = "hv"
  )
  
  return(plt)
}

# Loading ForTraCC + lightning pre-processing ----------------------------------

load("General_Processing/lifecycle_data.RData")

# Converting to datetime format
dates_clusters_cappis <- as.POSIXct(strptime(dates_clusters_cappis, "%Y%m%d%H%M", "GMT"))

# Loading shapefiles -----------------------------------------------------------

sao_paulo <- st_read("Data/GENERAL/shapefiles/sao_paulo.shp",
  stringsAsFactors = F
)
cities <- sao_paulo %>%
  filter(NOMEMUNICP %in% c(
    "AMERICANA",
    "ARTUR NOGUEIRA",
    "ENGENHEIRO COELHO",
    "HOLAMBRA",
    "HORTOLÂNDIA",
    "ITATIBA",
    "JAGUARIUNA",
    "MONTE MOR",
    "MORUNGABA",
    "NOVA ODESSA",
    "PAULINIA",
    "PEDREIRA",
    "SANTA BARBARA D'OESTE",
    "SANTO ANTONIO DE POSSE",
    "SUMARE",
    "VALINHOS",
    "VINHEDO"
  ))
cities_highlight <- sao_paulo %>%
  filter(NOMEMUNICP %in% c("CAMPINAS", "COSMOPOLIS", "INDAIATUBA"))

# Plotting ---------------------------------------------------------------------

# Case 2017-03-14 --------------------------------------------------------------

# ForTraCC/lightning data for the case
selected_fam <- selected_fams_df %>% filter(as.Date(date) == "2017-03-14")
selected_flashes <- flashes_brasildat_df %>% filter(as.Date(date) == "2017-03-14")
selected_clusters <- data_clusters[which(dates_clusters_cappis %in% selected_fam$date,
  arr.ind = T
)]
selected_cappis <- data_cappis[which(dates_clusters_cappis %in% selected_fam$date,
  arr.ind = T
)]

# Total ice mass retrieval
total_im <- 
  read_csv(
    "Radar_Processing/data_files/total_im_2017-03-14.csv",
    col_types = cols(...1 = col_skip(), 
                     time = col_datetime(format = "%Y-%m-%d %H:%M:%S"))) %>% 
  mutate(case = str_replace(case, "1 ", "1\n"),
         hour = time,
         level = factor(level, levels = c("Above -40°C", "0°C > T > -40°C", "Below 0°C")),
         date_hailpad = selected_fam$date_hailpad[2])
lubridate::date(total_im$hour) <- "2017-01-01"
total_im$date_hailpad[1] <- selected_fam$date_hailpad[1]

# Plots list
plts <- list(NA, NA, NA)

# - 18h30 ----------------------------------------------------------------------

# Hailpad location
selected_hailpad <- data_hailpads[1, ]

# Before/during/after hailfall data
clusters <- cappis <- flashes <- qte_flashes <- NA
list_out <- list(NA, NA, NA, NA)
for (i in seq(10, 12)) {
  list_out <- get_data_step(
    selected_fam[i, ],
    selected_clusters[i],
    selected_cappis[i],
    list_out
  )
}

clusters <- list_out[[1]]
cappis <- list_out[[2]]
flashes <- list_out[[3]]
qte_flashes <- list_out[[4]]
rm(list_out)

# Plot settings
lims_in_plot$lon <- c(-47.7, -46.7)
lims_in_plot$lat <- c(-23, -22)
grid_1 <- data.frame("lon" = -47.2, "lat" = -22.05) # Label position

# Reflectivity + lightning panel plot
plts[[1]] <- plot_z_lightning_panel(grid_1, 0.15)

# - 20h00 ----------------------------------------------------------------------

# Hailpad location
selected_hailpad <- data_hailpads[2, ]

# Before/during/after hailfall data
clusters <- cappis <- flashes <- qte_flashes <- NA
list_out <- list(NA, NA, NA, NA)
for (i in seq(19, 21)) {
  list_out <- get_data_step(
    selected_fam[i, ],
    selected_clusters[i],
    selected_cappis[i],
    list_out
  )
}

clusters <- list_out[[1]]
cappis <- list_out[[2]]
flashes <- list_out[[3]]
qte_flashes <- list_out[[4]]
rm(list_out)

# Plot settings
lims_in_plot$lon <- c(-47.9, -46.9)
lims_in_plot$lat <- c(-23.4, -22.4)
grid_2 <- data.frame("lon" = -47.4, "lat" = -22.45) # Label position

# Reflectivity + lightning panel plot
plts[[2]] <- plot_z_lightning_panel(grid_2, 0.15)

# Lifecycle plots --------------------------------------------------------------

plts[[3]] <- plot_lifecycle(case_name = "Case 1\n2017-03-14")

plt <- plot_grid(
  plotlist = plts, nrow = 3, labels = c("a", "b", ""),
  rel_heights = c(0.45, 0.45, 0.8)
)

save_plot(
  paste(
    "General_Processing/figures/clusters_flashes_",
    "2017-03-14", ".png",
    sep = ""
  ),
  plt, base_width = 9, base_height = 11, dpi = 300, bg = "transparent"
)

# Case 2017-11-15 --------------------------------------------------------------

# ForTraCC/lightning data for the case
selected_fam <- selected_fams_df %>% filter(as.Date(date) == "2017-11-15")
selected_flashes <- flashes_brasildat_df %>% filter(as.Date(date) == "2017-11-15")
selected_clusters <- data_clusters[which(dates_clusters_cappis %in% selected_fam$date,
                                         arr.ind = T)]
selected_cappis <- data_cappis[which(dates_clusters_cappis %in% selected_fam$date,
                                     arr.ind = T)]

# Hailpad location
selected_hailpad <- data_hailpads[3, ]

# Total ice mass retrieval
total_im <- 
  read_csv(
    "Radar_Processing/data_files/total_im_2017-11-15.csv",
    col_types = cols(...1 = col_skip(), 
                     time = col_datetime(format = "%Y-%m-%d %H:%M:%S"))) %>% 
  mutate(case = str_replace(case, "2 ", "2\n"),
         hour = time,
         level = factor(level, levels = c("Above -40°C", "0°C > T > -40°C", "Below 0°C")),
         date_hailpad = selected_fam$date_hailpad[1])
lubridate::date(total_im$hour) <- "2017-01-01"


# Before/during/after hailfall data
clusters <- cappis <- flashes <- qte_flashes <- NA
list_out <- list(NA, NA, NA, NA)
for (i in seq(5, 7)) {
  list_out <- get_data_step(
    selected_fam[i, ],
    selected_clusters[i],
    selected_cappis[i],
    list_out
  )
}

clusters <- list_out[[1]]
cappis <- list_out[[2]]
flashes <- list_out[[3]]
qte_flashes <- list_out[[4]]
rm(list_out)

# Plots list -------------------------------------------------------------------
plts <- list(NA, NA)

# Plot settings
lims_in_plot$lon <- c(-47.5, -46.99)
lims_in_plot$lat <- c(-23.25, -22.75)
grid <- data.frame("lon" = -47.25, "lat" = -22.78) # Label position

# Reflectivity + lightning panel plot
plts[[1]] <- plot_z_lightning_panel(grid, 0.075)

# Lifecycle plots 
plts[[2]] <- plot_lifecycle(case_name = "Case 2\n2017-11-15")

plt <- plot_grid(
  plotlist = plts, nrow = 2, labels = c("a", ""),
  rel_heights = c(0.45, 0.75)
)

save_plot(
  paste(
    "General_Processing/figures/clusters_flashes_",
    "2017-11-15", ".png",
    sep = ""
  ),
  plt, base_width = 9, base_height = 8.5, dpi = 300, bg = "transparent"
)

