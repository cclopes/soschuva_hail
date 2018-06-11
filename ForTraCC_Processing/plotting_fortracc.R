#---------------------------------------------------------------------------------------------------------------------------------
#-- Exporting entries from "processing_fortracc.R"
#-- Plotting clusters superimposed on radar
#-- Plotting selected systems' trackings, dBZ and size during life cycle
#---------------------------------------------------------------------------------------------------------------------------------

#-- Loading necessary scripts and packages
require(scales)
source("ForTraCC_Processing/processing_fortracc.R") #-- Necessary packages are called in this script
#---------------------------------------------------------------------------------------------------------------------------------

#-- Selecting part of the families
selected_fams <- selected_fams[c(3,4,5)]
selected_fams_df <- selected_fams_df %>% filter(case == "Case 2017-03-14 " | case == "Case 2017-03-14  " | case == "Case 2017-11-15 ")
data_hailpads <- data_hailpads[3:5,]

#-- Plotting cappi + clusters in specific times (defined by "n")
# n <- 64
# 
# row.names(data_cappis[[n]]) <- sort(lon_vector); colnames(data_cappis[[n]]) <- lat_vector
# cappi <- melt(data_cappis[[n]]) %>% na.omit()
# row.names(data_clusters[[n]]) <- sort(lon_vector); colnames(data_clusters[[n]]) <- lat_vector
# cluster <- melt(data_clusters[[n]]) %>% na.omit()
# labels_cluster <- cluster %>% group_by(value) %>%
#   summarise(Var2 = mean(Var2), Var1 = mean(Var1)) %>% ungroup()
# 
# ggplot() +
#   scale_x_continuous(limits = lims_in_plot$lon) + scale_y_continuous(limits = lims_in_plot$lat) +
#   geom_raster(data = cappi, aes(x = Var1, y = Var2, fill = value)) +
#   geom_tile(data = cluster, aes(x = Var1, y = Var2), fill = "black", alpha = 0.5) +
#   geom_point(data = data_hailpads, aes(x = lon, y = lat), pch = 20, size = 5) +
#   geom_path(data = fortify(cities), aes(long, lat, group = group), inherit.aes = F, colour = "gray50") +
#   geom_label(data = labels_cluster, aes(x = Var1, y = Var2, label = value), nudge_y = 0.05, size = 2.5) +
#   scale_fill_distiller(palette = "Spectral", limits = c(10,70)) +
#   labs(title = paste(dates_clusters_cappis[n], "CAPPI 3 km"), x = "Longitude", y = "Latitude", fill = "Z (dBZ)")
# 
#-- Plotting only clusters to highlight a specific cluster
# image.plot(data_clusters[[n]], x = lon_matrix, y = lat_matrix, zlim = c(83,85))
#---------------------------------------------------------------------------------------------------------------------------------

#-- Plotting trajectories for all cases
ggplot(data = selected_fams_df) +
  scale_x_continuous(limits = lims_in_plot$lon) + scale_y_continuous(limits = lims_in_plot$lat) +
  # geom_point(aes(x = lon, y = lat, size = size, color = hour), alpha = 0.1) +
  geom_point(aes(x = lon_hailpad, y = lat_hailpad), pch = 17, size = 2) +
  geom_path(aes(x = lon, y = lat, color = hour), size = 0.5) +
  geom_point(aes(x = lon, y = lat, color = hour, shape = class), size = 2.5, position = "jitter") +
  geom_path(data = fortify(cities), aes(long, lat, group = group), inherit.aes = F, colour = "gray50", size = 0.2) +
  # scale_size_continuous(range = c(0, 20)) +
  scale_color_distiller(palette = "Set1", breaks = pretty_breaks(n = 10), trans = time_trans()) +
  scale_shape_manual(values = c(20, 15, 18, 0), labels = c("Continuity", "Merge", "New", "Split")) +
  labs(x = "Longitude", y = "Latitude", color = "Time (UTC)", shape = "Classification") +
  # guides(size = "none", color = guide_colorbar(barheight = 12)) +
  theme(legend.position = "bottom") + #-- For less plots
  guides(size = "none", color = guide_colorbar(barwidth = 15), shape = guide_legend(nrow = 2, byrow = T)) + #-- For less plots
  facet_wrap(~ case)
# ggsave("ForTraCC_Processing/figures/trajectories_cases.png", width = 8.5, height = 4.25)
ggsave("ForTraCC_Processing/figures/trajectories_cases_less.png", width = 7.5, height = 3.25) #-- For less plots

#-- Generating plots of life cycle of dBZ max and area for future plot
plt_dbz <- ggplot(data = selected_fams_df) +
  geom_path(aes(x = hour, y = pmax), color = "tomato") +
  geom_vline(aes(xintercept = date_hailpad), linetype = "dashed") +
  labs(x = "Hour (UTC)", y = "Max Reflectivity (dBZ)") +
  facet_grid(case ~ .) +
  theme(strip.text = element_blank())

plt_size <- ggplot(data = selected_fams_df) +
  geom_path(aes(x = hour, y = size), color = "navyblue") +
  geom_vline(aes(xintercept = date_hailpad), linetype = "dashed") +
  labs(x = "Hour (UTC)", y = "Size (km²)") +
  facet_grid(case ~ .) +
  theme(strip.text = element_blank())
#---------------------------------------------------------------------------------------------------------------------------------

#-- Saving variables
save.image("ForTraCC_Processing/fortracc_data.RData")
