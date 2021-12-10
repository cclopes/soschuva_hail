# ------------------------------------------------------------------------------
# READING PRE-PROCESSED CLUSTERS AND GENERATING CAPPI PLOTS
# Figures in ForTraCC_Processing/figures/cappis/
# ------------------------------------------------------------------------------

# Loading required packages ----------------------------------------------------

require(tidyverse)
require(reshape2)
require(ggalt)


# Defining functions -----------------------------------------------------------

# Data processing and plotting
get_data_plot_cappi <- function(
  selected_fam_i, selected_clusters_i, selected_cappis_i, selected_hailpad) {

  # Selecting data based on data of a timestamp and plotting

  # Formatting date str
  selected_date <- selected_fam_i$date
  name <- paste("SR", format.Date(selected_date, "%Y-%m-%d %H%M"), "UTC")

  # Respective system
  selected_sys <- selected_fam_i$sys

  # Respective cluster
  test <- matrix(unlist(selected_clusters_i), ncol = 500, byrow = T)
  row.names(test) <- sort(lat_vector, decreasing = F)
  colnames(test) <- lon_vector
  clusters <- melt(test) %>%
    na.omit() %>%
    filter(value == selected_sys) %>%
    mutate(name = name)

  # Respective CAPPI field
  test <- matrix(unlist(selected_cappis_i), ncol = 500, byrow = T)
  row.names(test) <- sort(lat_vector, decreasing = F)
  colnames(test) <- lon_vector
  cappis <- melt(test) %>%
    na.omit() %>%
    mutate(name = name)

  # Plot settings
  theme_set(theme_bw())
  theme_update(plot.title = element_text(hjust = 0.5))

  # Plotting
  plt <- ggplot() +
    # Limits
    scale_x_continuous(limits = lims_in_plot$lon) +
    scale_y_continuous(limits = lims_in_plot$lat) +
    # Reflectivity
    geom_raster(data = cappis, aes(x = Var2, y = Var1, fill = value)) +
    # Cluster contour
    geom_encircle(
      data = clusters, aes(x = Var2, y = Var1), s_shape = 2,
      expand = 0.025, size = 2
    ) +
    # Hailpad position
    geom_point(
      data = selected_hailpad, aes(x = lon, y = lat),
      pch = 17, size = 2
    ) +
    # Shapefiles
    geom_path(
      data = fortify(shape_states), aes(long, lat, group = group),
      colour = "gray50", size = 0.2
    ) +
    geom_path(
      data = fortify(cities), aes(long, lat, group = group),
      colour = "gray30", size = 0.25
    ) +
    # Scales
    scale_fill_gradientn(
      colours = c("#99CCFF", "#18A04C", "#FFDF8E", "#D64646", "#0F0D0D"),
      breaks = seq(0, 70, 10), limits = c(0, 70), guide = "legend"
    ) +
    # Labels
    labs(
      title = name,
      x = expression("Longitude (" * degree * ")"),
      y = expression("Latitude (" * degree * ")"),
      fill = "Reflectivity (dBZ)"
    ) +
    # Theme settings
    guides(fill = guide_colorbar(
      title.position = "right", title.hjust = 0.5, barheight = 14,
      title.theme = element_text(angle = 90)
    )) +
    theme(
      plot.background = element_rect(fill = "transparent", color = "transparent"),
      legend.background = element_rect(fill = "transparent", color = "transparent"),
      strip.text = element_blank(),
      plot.title = element_text(hjust = 0.5, face = "bold")
    )
  
  # Saving plot
  ggsave(paste("ForTraCC_Processing/figures/cappis/", name, ".png", sep = ""),
    plt,
    dpi = 300,
    width = 5.3, height = 3.5, bg = "transparent"
  )
  
  print(paste("Plotted!", name))
}


# Loading ForTraCC pre-processing ----------------------------------------------

load("ForTraCC_Processing/fortracc_data.RData")

# Converting to datetime format
dates_clusters_cappis <- as.POSIXct(strptime(dates_clusters_cappis, "%Y%m%d%H%M", "GMT"))


# Case 2017-03-14 --------------------------------------------------------------

selected_fam <- selected_fams_df %>% filter(as.Date(date) == "2017-03-14")
selected_clusters <- data_clusters[which(dates_clusters_cappis %in% selected_fam$date,
  arr.ind = T
)]
selected_cappis <- data_cappis[which(dates_clusters_cappis %in% selected_fam$date,
  arr.ind = T
)]
selected_hailpad <- data_hailpads[1:2, ]

# Getting data and plotting for each timestamp
for(i in seq(1, length(selected_clusters))) {
  get_data_plot_cappi(
    selected_fam[i,], 
    selected_clusters[i], 
    selected_cappis[i], 
    selected_hailpad
  )
}


# Case 2017-11-15 --------------------------------------------------------------

selected_fam <- selected_fams_df %>% filter(as.Date(date) == "2017-11-15")
selected_clusters <- data_clusters[which(dates_clusters_cappis %in% selected_fam$date,
  arr.ind = T
)]
selected_cappis <- data_cappis[which(dates_clusters_cappis %in% selected_fam$date,
  arr.ind = T
)]
selected_hailpad <- data_hailpads[3, ]

# Getting data and plotting for each timestamp
for(i in seq(1, length(selected_clusters))) {
  get_data_plot_cappi(
    selected_fam[i,], 
    selected_clusters[i], 
    selected_cappis[i], 
    selected_hailpad
  )
}
