# ------------------------------------------------------------------------------
# Reading clusters and plotting
# ------------------------------------------------------------------------------

require(ggalt)
require(fields)
require(maptools)
require(reshape2)
require(tidyverse)
require(magrittr)
require(lubridate)
require(scales)
require(cowplot)
require(cptcity)
theme_set(theme_bw())
# ForTraCC pre-processing
load("General_Processing/lifecycle_data.RData")

dates_clusters_cappis <- as.POSIXct(strptime(dates_clusters_cappis, "%Y%m%d%H%M", "GMT"))

# Case 2017-03-14
selected_fam <- selected_fams_df %>% filter(as.Date(date) == "2017-03-14")
selected_clusters <- data_clusters[which(dates_clusters_cappis %in% selected_fam$date,
                                         arr.ind = T)]
selected_cappis <- data_cappis[which(dates_clusters_cappis %in% selected_fam$date,
                                     arr.ind = T)]
selected_hailpad <- data_hailpads[3:4,]

for(i in seq(1, length(selected_clusters))){
  selected_date <- selected_fam$date[i]
  name <- paste("SR", format.Date(selected_date, "%Y-%m-%d %H%M"), "UTC")
  selected_sys <- selected_fam$sys[i]
  
  test <- matrix(unlist(selected_clusters[i]), ncol = 500, byrow = T)
  row.names(test) <- sort(lat_vector, decreasing = F); colnames(test) <- lon_vector
  clusters <- melt(test) %>% na.omit() %>% filter(value == selected_sys) %>% 
    mutate(name = name)

  test <- matrix(unlist(selected_cappis[i]), ncol = 500, byrow = T)
  row.names(test) <- sort(lat_vector, decreasing = F); colnames(test) <- lon_vector
  cappis <- melt(test) %>% na.omit() %>% # semi_join(., test_clusters, by = c("Var1", "Var2"))
    mutate(name = name)
  
  plt <- ggplot() +
    scale_x_continuous(limits = lims_in_plot$lon) +
    scale_y_continuous(limits = lims_in_plot$lat) +
    geom_raster(data = cappis, aes(x = Var2, y = Var1, fill = value)) +
    geom_encircle(data = clusters, aes(x = Var2, y = Var1), s_shape = 0.5,
                  expand = 0.01, size = 2) +
    geom_point(data = selected_hailpad, aes(x = lon, y = lat),
               pch = 17, size = 2) +
    geom_path(data = fortify(shape_states), aes(long, lat, group = group),
              colour = "gray50", size = 0.2) +
    geom_path(data = fortify(cities), aes(long, lat, group = group),
              colour = "gray30", size = 0.25) +
    scale_fill_gradientn(colours = c("#99CCFF", "#18A04C", "#FFDF8E", "#D64646", "#0F0D0D"),
                         breaks = seq(0, 70, 10), limits = c(0, 70), guide = "legend") +
    labs(title = name,
         x = expression("Longitude ("*degree*")"), y = expression("Latitude ("*degree*")"),
         fill = "Refletividade (dBZ)") +  # pt-br
    guides(fill = guide_colorbar(title.position = "right", title.hjust = 0.5, barheight = 14,
                                 title.theme = element_text(angle = 90))) +
    theme(plot.background = element_rect(fill = "transparent", color = "transparent"),
          legend.background = element_rect(fill = "transparent", color = "transparent"),
          strip.text = element_blank(),
          plot.title = element_text(hjust = 0.5, face = "bold"))
  ggsave(paste("General_Processing/figures/cappis/", name, ".png", sep = ''), plt, dpi = 300,
         width = 5.3, height = 3.5, bg = "transparent")
}

# Case 2017-11-15
selected_fam <- selected_fams_df %>% filter(as.Date(date) == "2017-11-15")
selected_clusters <- data_clusters[which(dates_clusters_cappis %in% selected_fam$date,
                                         arr.ind = T)]
selected_cappis <- data_cappis[which(dates_clusters_cappis %in% selected_fam$date,
                                     arr.ind = T)]
selected_hailpad <- data_hailpads[4,]

for(i in seq(1, length(selected_clusters))){
  selected_date <- selected_fam$date[i]
  name <- paste("SR", format.Date(selected_date, "%Y-%m-%d %H%M"), "UTC")
  selected_sys <- selected_fam$sys[i]
  
  test <- matrix(unlist(selected_clusters[i]), ncol = 500, byrow = T)
  row.names(test) <- sort(lat_vector, decreasing = F); colnames(test) <- lon_vector
  clusters <- melt(test) %>% na.omit() %>% filter(value == selected_sys) %>% 
    mutate(name = name)
  
  test <- matrix(unlist(selected_cappis[i]), ncol = 500, byrow = T)
  row.names(test) <- sort(lat_vector, decreasing = F); colnames(test) <- lon_vector
  cappis <- melt(test) %>% na.omit() %>% # semi_join(., test_clusters, by = c("Var1", "Var2"))
    mutate(name = name)
  
  plt <- ggplot() +
    scale_x_continuous(limits = lims_in_plot$lon) +
    scale_y_continuous(limits = lims_in_plot$lat) +
    geom_raster(data = cappis, aes(x = Var2, y = Var1, fill = value)) +
    geom_encircle(data = clusters, aes(x = Var2, y = Var1), s_shape = 0.5,
                  expand = 0.01, size = 2) +
    geom_point(data = selected_hailpad, aes(x = lon, y = lat),
               pch = 17, size = 2) +
    geom_path(data = fortify(shape_states), aes(long, lat, group = group),
              colour = "gray50", size = 0.2) +
    geom_path(data = fortify(cities), aes(long, lat, group = group),
              colour = "gray30", size = 0.25) +
    scale_fill_gradientn(colours = c("#99CCFF", "#18A04C", "#FFDF8E", "#D64646", "#0F0D0D"),
                         breaks = seq(0, 70, 10), limits = c(0, 70), guide = "legend") +
    labs(title = name,
         x = expression("Longitude ("*degree*")"), y = expression("Latitude ("*degree*")"),
         fill = "Refletividade (dBZ)") +  # pt-br
    guides(fill = guide_colorbar(title.position = "right", title.hjust = 0.5, barheight = 14,
                                 title.theme = element_text(angle = 90))) +
    theme(plot.background = element_rect(fill = "transparent", color = "transparent"),
          legend.background = element_rect(fill = "transparent", color = "transparent"),
          strip.text = element_blank(),
          plot.title = element_text(hjust = 0.5, face = "bold"))
  ggsave(paste("General_Processing/figures/cappis/", name, ".png", sep = ''), plt, dpi = 300,
         width = 5.3, height = 3.5, bg = "transparent")
}
