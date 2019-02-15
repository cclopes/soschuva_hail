# ------------------------------------------------------------------------------
# Reading clusters and plotting with lightning data
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
selected_flashes <- flashes_brasildat_df %>% filter(as.Date(date) == "2017-03-14")
selected_clusters <- data_clusters[which(dates_clusters_cappis %in% selected_fam$date,
                                         arr.ind = T)]
selected_cappis <- data_cappis[which(dates_clusters_cappis %in% selected_fam$date,
                                         arr.ind = T)]
selected_hailpad <- data_hailpads[3,]

# - 18h30
clusters <- cappis <- flashes <- qte_flashes <- NA
for(i in seq(10, 12)){
  selected_date <- selected_fam$date[i]
  name <- paste("SR", format.Date(selected_date, "%Y-%m-%d %H%M"), "UTC")
  selected_sys <- selected_fam$sys[i]
  
  test <- matrix(unlist(selected_clusters[i]), ncol = 500, byrow = T)
  row.names(test) <- sort(lat_vector, decreasing = F); colnames(test) <- lon_vector
  test_clusters <- melt(test) %>% na.omit() %>% filter(value == selected_sys) %>% 
    mutate(name = name)
  clusters <- rbind(clusters, test_clusters) %>% na.omit()
  
  test <- matrix(unlist(selected_cappis[i]), ncol = 500, byrow = T)
  row.names(test) <- sort(lat_vector, decreasing = F); colnames(test) <- lon_vector
  test <- melt(test) %>% na.omit() %>% # semi_join(., test_clusters, by = c("Var1", "Var2"))
    mutate(name = name)
  cappis <- rbind(cappis, test) %>% na.omit()
  
  selected_flash <- selected_flashes %>%
    filter(selected_flashes$date >= selected_date & selected_flashes$date < (selected_date + 600)) %>% 
    mutate(name = name)
  flashes <- rbind(flashes, selected_flash) %>% na.omit()
  
  selected_totais <- select(selected_flash, lat, lon, date, class, case)
  selected_flash_total <- selected_totais %>%
    group_by(case, class) %>%
    count() %>%
    ungroup() %>%
    mutate(class = paste("Total", class, "=", n), name = name) %>%
    select(case, class, name)
  qte_flashes <- rbind(qte_flashes, selected_flash_total) %>% na.omit()
}

lims_in_plot$lon <- c(-47.7, -46.7); lims_in_plot$lat <- c(-23, -22)
grid <- data.frame("lon" = -47.2, "lat" = -22) # Label position
plts <- list(NA, NA, NA)
plts[[1]] <- ggplot() +
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
  labs(x = "", y = expression("Latitude ("*degree*")"),
       fill = "Refletividade (dBZ)") +  # pt-br
  guides(fill = guide_colorbar(title.position = "top", title.hjust = 0.5, barwidth = 10)) +
  theme(plot.background = element_rect(fill = "transparent", color = "transparent"),
        legend.background = element_rect(fill = "transparent", color = "transparent"),
        legend.position = "bottom", 
        strip.text = element_blank()) +
  facet_grid(name ~ .)
plts[[2]] <- ggplot() +
  scale_x_continuous(limits = lims_in_plot$lon) +
  scale_y_continuous(limits = lims_in_plot$lat, labels = NULL) +
  geom_bin2d(data = filter(flashes, class == "IC"), aes(x = lon, y = lat),
             binwidth = c(0.05, 0.05), color = "black") +
  geom_encircle(data = clusters, aes(x = Var2, y = Var1), s_shape = 0.5,
                expand = 0.01, size = 2) +
  geom_point(data = selected_hailpad, aes(x = lon, y = lat),
             pch = 17, size = 2) +
  geom_path(data = fortify(shape_states), aes(long, lat, group = group),
            colour = "gray50", size = 0.2) +
  geom_path(data = fortify(cities), aes(long, lat, group = group), inherit.aes = F,
            colour = "gray30", size = 0.25) +
  geom_label(data = filter(qte_flashes, str_detect(class, "IC")),
             aes(x = grid$lon, y = grid$lat, label = class),
             size = 3) +
  scale_fill_gradientn(colours = c("#E2E2E2", "#E9CEAE", "#C0B878", "#7F9D43", "#027C1E"),
                       values = c(0, 0.1, 0.4, 0.7, 1),
                       breaks = seq(0, 80, 10), limits = c(1, 80), guide = "legend") +
  labs(x = expression("Longitude ("*degree*")"), y = "",
    fill = expression("Flashes 10"*min^-1*" IC")) +
  guides(fill = guide_colorbar(title.position = "top", title.hjust = 0.5, barwidth = 10)) +
  theme(plot.background = element_rect(fill = "transparent", color = "transparent"),
        legend.background = element_rect(fill = "transparent", color = "transparent"),
        legend.position = "bottom", 
        strip.text = element_blank()) +
  facet_grid(name ~ .)
plts[[3]] <- ggplot() +
  scale_x_continuous(limits = lims_in_plot$lon) +
  scale_y_continuous(limits = lims_in_plot$lat, labels = NULL) +
  geom_bin2d(data = filter(flashes, class == "CG"), aes(x = lon, y = lat),
             binwidth = c(0.05, 0.05), color = "black") +
  geom_encircle(data = clusters, aes(x = Var2, y = Var1), s_shape = 0.5,
                expand = 0.01, size = 2) +
  geom_point(data = selected_hailpad, aes(x = lon, y = lat),
             pch = 17, size = 2) +
  geom_path(data = fortify(shape_states), aes(long, lat, group = group),
            colour = "gray50", size = 0.2) +
  geom_path(data = fortify(cities), aes(long, lat, group = group), inherit.aes = F,
            colour = "gray30", size = 0.25) +
  geom_label(data = filter(qte_flashes, str_detect(class, "CG")),
             aes(x = grid$lon, y = grid$lat, label = class),
             size = 3) +
  scale_fill_gradientn(colours = c("#E2E2E2", "#E9CEAE", "#C0B878", "#7F9D43", "#027C1E"),
                       values = c(0, 0.1, 0.4, 0.7, 1),
                       breaks = seq(0, 20, 2), limits = c(1, 20), guide = "legend") +
  labs(x = "", y = "", fill = expression("Flashes 10"*min^-1*" CG")) +
  guides(fill = guide_colorbar(title.position = "top", title.hjust = 0.5, barwidth = 10)) +
  theme(plot.background = element_rect(fill = "transparent", color = "transparent"),
        legend.background = element_rect(fill = "transparent", color = "transparent"),
        legend.position = "bottom") +
  facet_grid(name ~ .)

plt <- plot_grid(plotlist = plts, ncol = 3, labels = c("a", "b", "c"),
                 rel_widths = c(0.54, 0.46, 0.5))
save_plot(paste("General_Processing/figures/clusters_flashes_",
             "2017-03-14_1830", "_ptbr.png", sep = ""),
          plt, ncol = 3, base_width = 2.5, base_height = 7, bg = "transparent")

# - 20h00
selected_hailpad <- data_hailpads[4,]

clusters <- cappis <- flashes <- qte_flashes <- NA
for(i in seq(19, 21)){
  selected_date <- selected_fam$date[i]
  name <- paste("SR", format.Date(selected_date, "%Y-%m-%d %H%M"), "UTC")
  selected_sys <- selected_fam$sys[i]
  
  test <- matrix(unlist(selected_clusters[i]), ncol = 500, byrow = T)
  row.names(test) <- sort(lat_vector, decreasing = F); colnames(test) <- lon_vector
  test_clusters <- melt(test) %>% na.omit() %>% filter(value == selected_sys) %>% 
    mutate(name = name)
  clusters <- rbind(clusters, test_clusters) %>% na.omit()
  
  test <- matrix(unlist(selected_cappis[i]), ncol = 500, byrow = T)
  row.names(test) <- sort(lat_vector, decreasing = F); colnames(test) <- lon_vector
  test <- melt(test) %>% na.omit() %>% # semi_join(., test_clusters, by = c("Var1", "Var2"))
    mutate(name = name)
  cappis <- rbind(cappis, test) %>% na.omit()
  
  selected_flash <- selected_flashes %>%
    filter(selected_flashes$date >= selected_date & selected_flashes$date < (selected_date + 600)) %>% 
    mutate(name = name)
  flashes <- rbind(flashes, selected_flash) %>% na.omit()
  
  selected_totais <- select(selected_flash, lat, lon, date, class, case)
  selected_flash_total <- selected_totais %>%
    group_by(case, class) %>%
    count() %>%
    ungroup() %>%
    mutate(class = paste("Total", class, "=", n), name = name) %>%
    select(case, class, name)
  qte_flashes <- rbind(qte_flashes, selected_flash_total) %>% na.omit()
}

lims_in_plot$lon <- c(-47.9, -46.9); lims_in_plot$lat <- c(-23.4, -22.4)
grid <- data.frame("lon" = -47.4, "lat" = -22.4) # Label position
plts <- list(NA, NA, NA)
plts[[1]] <- ggplot() +
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
  labs(x = "", y = expression("Latitude ("*degree*")"),
       fill = "Refletividade (dBZ)") +  # pt-br
  guides(fill = guide_colorbar(title.position = "top", title.hjust = 0.5, barwidth = 10)) +
  theme(plot.background = element_rect(fill = "transparent", color = "transparent"),
        legend.background = element_rect(fill = "transparent", color = "transparent"),
        legend.position = "bottom", 
        strip.text = element_blank()) +
  facet_grid(name ~ .)
plts[[2]] <- ggplot() +
  scale_x_continuous(limits = lims_in_plot$lon) +
  scale_y_continuous(limits = lims_in_plot$lat, labels = NULL) +
  geom_bin2d(data = filter(flashes, class == "IC"), aes(x = lon, y = lat),
             binwidth = c(0.05, 0.05), color = "black") +
  geom_encircle(data = clusters, aes(x = Var2, y = Var1), s_shape = 0.5,
                expand = 0.01, size = 2) +
  geom_point(data = selected_hailpad, aes(x = lon, y = lat),
             pch = 17, size = 2) +
  geom_path(data = fortify(shape_states), aes(long, lat, group = group),
            colour = "gray50", size = 0.2) +
  geom_path(data = fortify(cities), aes(long, lat, group = group), inherit.aes = F,
            colour = "gray30", size = 0.25) +
  geom_label(data = filter(qte_flashes, str_detect(class, "IC")),
             aes(x = grid$lon, y = grid$lat, label = class),
             size = 3) +
  scale_fill_gradientn(colours = c("#E2E2E2", "#E9CEAE", "#C0B878", "#7F9D43", "#027C1E"),
                       values = c(0, 0.1, 0.4, 0.7, 1),
                       breaks = seq(0, 80, 10), limits = c(1, 80), guide = "legend") +
  labs(x = expression("Longitude ("*degree*")"), y = "",
       fill = expression("Flashes 10"*min^-1*" IC")) +
  guides(fill = guide_colorbar(title.position = "top", title.hjust = 0.5, barwidth = 10)) +
  theme(plot.background = element_rect(fill = "transparent", color = "transparent"),
        legend.background = element_rect(fill = "transparent", color = "transparent"),
        legend.position = "bottom", 
        strip.text = element_blank()) +
  facet_grid(name ~ .)
plts[[3]] <- ggplot() +
  scale_x_continuous(limits = lims_in_plot$lon) +
  scale_y_continuous(limits = lims_in_plot$lat, labels = NULL) +
  geom_bin2d(data = filter(flashes, class == "CG"), aes(x = lon, y = lat),
             binwidth = c(0.05, 0.05), color = "black") +
  geom_encircle(data = clusters, aes(x = Var2, y = Var1), s_shape = 0.5,
                expand = 0.01, size = 2) +
  geom_point(data = selected_hailpad, aes(x = lon, y = lat),
             pch = 17, size = 2) +
  geom_path(data = fortify(shape_states), aes(long, lat, group = group),
            colour = "gray50", size = 0.2) +
  geom_path(data = fortify(cities), aes(long, lat, group = group), inherit.aes = F,
            colour = "gray30", size = 0.25) +
  geom_label(data = filter(qte_flashes, str_detect(class, "CG")),
             aes(x = grid$lon, y = grid$lat, label = class),
             size = 3) +
  scale_fill_gradientn(colours = c("#E2E2E2", "#E9CEAE", "#C0B878", "#7F9D43", "#027C1E"),
                       values = c(0, 0.1, 0.4, 0.7, 1),
                       breaks = seq(0, 20, 2), limits = c(1, 20), guide = "legend") +
  labs(x = "", y = "", fill = expression("Flashes 10"*min^-1*" CG")) +
  guides(fill = guide_colorbar(title.position = "top", title.hjust = 0.5, barwidth = 10)) +
  theme(plot.background = element_rect(fill = "transparent", color = "transparent"),
        legend.background = element_rect(fill = "transparent", color = "transparent"),
        legend.position = "bottom") +
  facet_grid(name ~ .)

plt <- plot_grid(plotlist = plts, ncol = 3, labels = c("a", "b", "c"),
                 rel_widths = c(0.54, 0.46, 0.5))
save_plot(paste("General_Processing/figures/clusters_flashes_",
                "2017-03-14_2000", "_ptbr.png", sep = ""),
          plt, ncol = 3, base_width = 2.5, base_height = 7, bg = "transparent")

# Case 2017-11-15
selected_fam <- selected_fams_df %>% filter(as.Date(date) == "2017-11-15")
selected_flashes <- flashes_brasildat_df %>% filter(as.Date(date) == "2017-11-15")
selected_clusters <- data_clusters[which(dates_clusters_cappis %in% selected_fam$date,
                                         arr.ind = T)]
selected_cappis <- data_cappis[which(dates_clusters_cappis %in% selected_fam$date,
                                     arr.ind = T)]
selected_hailpad <- data_hailpads[4,]

clusters <- cappis <- flashes <- qte_flashes <- NA
for(i in seq(5, 7)){
  selected_date <- selected_fam$date[i]
  name <- paste("SR", format.Date(selected_date, "%Y-%m-%d %H%M"), "UTC")
  selected_sys <- selected_fam$sys[i]
  
  test <- matrix(unlist(selected_clusters[i]), ncol = 500, byrow = T)
  row.names(test) <- sort(lat_vector, decreasing = F); colnames(test) <- lon_vector
  test_clusters <- melt(test) %>% na.omit() %>% filter(value == selected_sys) %>% 
    mutate(name = name)
  clusters <- rbind(clusters, test_clusters) %>% na.omit()
  
  test <- matrix(unlist(selected_cappis[i]), ncol = 500, byrow = T)
  row.names(test) <- sort(lat_vector, decreasing = F); colnames(test) <- lon_vector
  test <- melt(test) %>% na.omit() %>% # semi_join(., test_clusters, by = c("Var1", "Var2"))
    mutate(name = name)
  cappis <- rbind(cappis, test) %>% na.omit()
  
  selected_flash <- selected_flashes %>%
    filter(selected_flashes$date >= selected_date & selected_flashes$date < (selected_date + 600)) %>% 
    mutate(name = name)
  flashes <- rbind(flashes, selected_flash) %>% na.omit()
  
  selected_totais <- select(selected_flash, lat, lon, date, class, case)
  selected_flash_total <- selected_totais %>%
    group_by(case, class) %>%
    count() %>%
    ungroup() %>%
    mutate(class = paste("Total", class, "=", n), name = name) %>%
    select(case, class, name)
  qte_flashes <- rbind(qte_flashes, selected_flash_total) %>% na.omit()
}

lims_in_plot$lon <- c(-47.5, -47); lims_in_plot$lat <- c(-23.25, -22.75)
grid <- data.frame("lon" = -47.25, "lat" = -22.75) # Label position
plts <- list(NA, NA, NA)
plts[[1]] <- ggplot() +
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
  labs(x = "", y = expression("Latitude ("*degree*")"),
       fill = "Refletividade (dBZ)") +  # pt-br
  guides(fill = guide_colorbar(title.position = "top", title.hjust = 0.5, barwidth = 10)) +
  theme(plot.background = element_rect(fill = "transparent", color = "transparent"),
        legend.background = element_rect(fill = "transparent", color = "transparent"),
        legend.position = "bottom", 
        strip.text = element_blank()) +
  facet_grid(name ~ .)
plts[[2]] <- ggplot() +
  scale_x_continuous(limits = lims_in_plot$lon) +
  scale_y_continuous(limits = lims_in_plot$lat, labels = NULL) +
  geom_bin2d(data = filter(flashes, class == "IC"), aes(x = lon, y = lat),
             binwidth = c(0.025, 0.025), color = "black") +
  geom_encircle(data = clusters, aes(x = Var2, y = Var1), s_shape = 0.5,
                expand = 0.01, size = 2) +
  geom_point(data = selected_hailpad, aes(x = lon, y = lat),
             pch = 17, size = 2) +
  geom_path(data = fortify(shape_states), aes(long, lat, group = group),
            colour = "gray50", size = 0.2) +
  geom_path(data = fortify(cities), aes(long, lat, group = group), inherit.aes = F,
            colour = "gray30", size = 0.25) +
  geom_label(data = filter(qte_flashes, str_detect(class, "IC")),
             aes(x = grid$lon, y = grid$lat, label = class),
             size = 3) +
  scale_fill_gradientn(colours = c("#E2E2E2", "#E9CEAE", "#C0B878", "#7F9D43", "#027C1E"),
                       values = c(0, 0.1, 0.4, 0.7, 1),
                       breaks = seq(0, 7, 1), limits = c(1, 7), guide = "legend") +
  labs(x = expression("Longitude ("*degree*")"), y = "",
       fill = expression("Flashes 10"*min^-1*" IC")) +
  guides(fill = guide_colorbar(title.position = "top", title.hjust = 0.5, barwidth = 10)) +
  theme(plot.background = element_rect(fill = "transparent", color = "transparent"),
        legend.background = element_rect(fill = "transparent", color = "transparent"),
        legend.position = "bottom", 
        strip.text = element_blank()) +
  facet_grid(name ~ .)
plts[[3]] <- ggplot() +
  scale_x_continuous(limits = lims_in_plot$lon) +
  scale_y_continuous(limits = lims_in_plot$lat, labels = NULL) +
  geom_bin2d(data = filter(flashes, class == "CG"), aes(x = lon, y = lat),
             binwidth = c(0.025, 0.025), color = "black") +
  geom_encircle(data = clusters, aes(x = Var2, y = Var1), s_shape = 0.5,
                expand = 0.01, size = 2) +
  geom_point(data = selected_hailpad, aes(x = lon, y = lat),
             pch = 17, size = 2) +
  geom_path(data = fortify(shape_states), aes(long, lat, group = group),
            colour = "gray50", size = 0.2) +
  geom_path(data = fortify(cities), aes(long, lat, group = group), inherit.aes = F,
            colour = "gray30", size = 0.25) +
  geom_label(data = filter(qte_flashes, str_detect(class, "CG")),
             aes(x = grid$lon, y = grid$lat, label = class),
             size = 3) +
  scale_fill_gradientn(colours = c("#E2E2E2", "#E9CEAE", "#C0B878", "#7F9D43", "#027C1E"),
                       values = c(0, 0.1, 0.4, 0.7, 1),
                       breaks = seq(0, 5, 1), limits = c(1, 5), guide = "legend") +
  labs(x = "", y = "", fill = expression("Flashes 10"*min^-1*" CG")) +
  guides(fill = guide_colorbar(title.position = "top", title.hjust = 0.5, barwidth = 10)) +
  theme(plot.background = element_rect(fill = "transparent", color = "transparent"),
        legend.background = element_rect(fill = "transparent", color = "transparent"),
        legend.position = "bottom") +
  facet_grid(name ~ .)

plt <- plot_grid(plotlist = plts, ncol = 3, labels = c("a", "b", "c"),
                 rel_widths = c(0.54, 0.46, 0.5))
save_plot(paste("General_Processing/figures/clusters_flashes_",
                "2017-11-15_2150", "_ptbr.png", sep = ""),
          plt, ncol = 3, base_width = 2.5, base_height = 7, bg = "transparent")
