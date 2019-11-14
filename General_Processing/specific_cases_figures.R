#-------------------------------------------------------------------------------
#-- Importing ForTraCC and lightning entries with "lifecycle_data.RData"
#-- Modifying for specific cases - plots
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
require(gridExtra)
require(grid)
require(cptcity)
load("General_Processing/lifecycle_data.RData")
theme_set(theme_bw())

# 2017-03-14 -------------------------------------------------------------------
fams_df <- selected_fams_df %>% 
  filter(as.Date(date) == "2017-03-14")
grid_df <- grid[c(1,2),]

plt_fortracc <- ggplot(data = fams_df) +
  scale_x_continuous(limits = lims_in_plot$lon) + 
  scale_y_continuous(limits = lims_in_plot$lat) +
  # geom_point(aes(x = lon, y = lat, size = size, color = hour), alpha = 0.1) +
  geom_point(aes(x = lon_hailpad, y = lat_hailpad), pch = 17, size = 2) +
  geom_path(aes(x = lon, y = lat, color = hour), size = 0.5) +
  geom_point(aes(x = lon, y = lat, color = hour, shape = class), 
             size = 2.5, position = "jitter") +
  geom_path(data = fortify(cities), aes(long, lat, group = group), inherit.aes = F, 
            colour = "gray50", size = 0.2) +
  # scale_size_continuous(range = c(0, 20)) +
  scale_color_gradientn(colours = cpt(pal = "oc_zeu"), labels = date_format("%H%M"),
                        breaks = pretty_breaks(n = 10), trans = time_trans()) +
  scale_shape_manual(values = c(20, 15, 18, 0),
                     labels = c("Continuity", "Merge", "New", "Split")) +
  # scale_shape_manual(values = c(20, 15, 18, 0), 
  #                    labels = c("Continuidade", "Fusão", "Novo", "Separação")) +  # pt-br
  labs(
    x = expression("Longitude (" * degree * ")"), y = expression("Latitude (" * degree * ")"),
    color = "Time (UTC)", shape = "Classification"
  ) +
  # labs(
  #   x = expression("Longitude (" * degree * ")"), y = expression("Latitude (" * degree * ")"),
  #   color = "Hora (UTC)", shape = "Classificação"
  # ) +  # pt-br
  guides(size = "none", color = F,
         shape = guide_legend(title.position = "top", title.hjust = 0.5)) +
  theme(
    plot.background = element_rect(fill = "transparent", color = "transparent"),
    legend.background = element_rect(fill = "transparent"),
    legend.position = "bottom"
  )

flashes_df <- flashes_brasildat_df %>% 
  filter(as.Date(date) == "2017-03-14")
flashes_df_total <- flashes_qte_total %>% 
  filter(str_sub(case, -11, -2) == "2017-03-14")
plt_flashes <- ggplot(data = flashes_df) +
  scale_x_continuous(limits = lims_in_plot$lon) + scale_y_continuous(limits = lims_in_plot$lat) +
  geom_point(aes(x = lon, y = lat, shape = class, color = hour)) +
  geom_point(aes(x = lon_hailpad, y = lat_hailpad), pch = 17, size = 2) +
  geom_path(data = fortify(cities), aes(long, lat, group = group), inherit.aes = F, colour = "gray50", size = 0.2) +
  geom_label(data = flashes_df_total, aes(x = grid_df$lon, y = grid_df$lat, label = class), size = 3) +
  scale_color_gradientn(colours = cpt(pal = "oc_zeu"), labels = date_format("%H%M"),
                        breaks = pretty_breaks(n = 10), trans = time_trans()) +
  scale_shape_manual(values = c(4, 1)) +
  labs(x = expression("Longitude ("*degree*")"), y = expression("Latitude ("*degree*")"),
       color = "Time (UTC)", shape = "Flash Type") +
  # labs(x = expression("Longitude ("*degree*")"), y = expression("Latitude ("*degree*")"),
  #      color = "Hora (UTC)", shape = "Tipo de Flash") +  # pt-br
  guides(size = "none", color = F,
         shape = guide_legend(title.position = "top", title.hjust = 0.5)) +
  theme(
    plot.background = element_rect(fill = "transparent", color = "transparent"),
    legend.background = element_rect(fill = "transparent"),
    legend.position = "bottom"
  )

legend <- get_legend(
  ggplot(data = flashes_df) +
    scale_x_continuous(limits = lims_in_plot$lon) +
    scale_y_continuous(limits = lims_in_plot$lat) +
    geom_point(aes(x = lon, y = lat, shape = class, color = hour)) +
    geom_point(aes(x = lon_hailpad, y = lat_hailpad), pch = 17, size = 2) +
    geom_path(data = fortify(cities), aes(long, lat, group = group),
              inherit.aes = F, colour = "gray50", size = 0.2) +
    geom_label(data = flashes_df_total, aes(x = grid_df$lon, y = grid_df$lat,
                                            label = class), size = 3) +
    scale_color_gradientn(colours = cpt(pal = "oc_zeu"), labels = date_format("%H%M"),
                          breaks = pretty_breaks(n = 10), trans = time_trans()) +
    scale_shape_manual(values = c(4, 1)) +
    labs(x = expression("Longitude ("*degree*")"), y = expression("Latitude ("*degree*")"),
         color = "Time (UTC)", shape = "Flash\nType") +
    # labs(x = expression("Longitude ("*degree*")"), y = expression("Latitude ("*degree*")"),
    #      color = "Hora (UTC)", shape = "Tipo de\nFlash") +  # pt-br
    guides(size = "none", shape = F, color = guide_colorbar(barheight = 12)) +
    theme(
      plot.background = element_rect(fill = "transparent", color = "transparent"),
      legend.background = element_rect(fill = "transparent")
    )
)

plt <- plot_grid(plt_fortracc, plt_flashes, legend, labels = c("a", "b"), 
                 ncol = 3, rel_widths = c(0.4, 0.4, 0.12))
save_plot("General_Processing/figures/track_flashes_20170314.png",
          plot = plt, ncol = 3, base_width = 2.5, base_height = 3.4, bg = "transparent")
# save_plot("General_Processing/figures/track_flashes_20170314_ptbr.png",
#           plot = plt, ncol = 3, base_width = 2.5, base_height = 3.4, bg = "transparent")  # pt-br

# 2017-11-15 -------------------------------------------------------------------
fams_df <- selected_fams_df %>% 
  filter(as.Date(date) == "2017-11-15")
grid_df <- grid[c(1,2),]

plt_fortracc <- ggplot(data = fams_df) +
  scale_x_continuous(limits = lims_in_plot$lon) + 
  scale_y_continuous(limits = lims_in_plot$lat) +
  # geom_point(aes(x = lon, y = lat, size = size, color = hour), alpha = 0.1) +
  geom_point(aes(x = lon_hailpad, y = lat_hailpad), pch = 17, size = 2) +
  geom_path(aes(x = lon, y = lat, color = hour), size = 0.5) +
  geom_point(aes(x = lon, y = lat, color = hour, shape = class), 
             size = 2.5, position = "jitter") +
  geom_path(data = fortify(cities), aes(long, lat, group = group), inherit.aes = F, 
            colour = "gray50", size = 0.2) +
  # scale_size_continuous(range = c(0, 20)) +
  scale_color_gradientn(colours = cpt(pal = "oc_zeu"), labels = date_format("%H%M"),
                        breaks = pretty_breaks(n = 10), trans = time_trans()) +
  # scale_shape_manual(values = c(20, 15, 18, 0), 
  #                    labels = c("Continuity", "Merge", "New", "Split")) +
  scale_shape_manual(values = c(20, 15, 18, 0), 
                     labels = c("Continuidade", "Fusão", "Novo", "Separação")) +  # pt-br
  # labs(
  #   x = expression("Longitude (" * degree * ")"), y = expression("Latitude (" * degree * ")"),
  #   color = "Time (UTC)", shape = "Classification"
  # ) +
  labs(
    x = expression("Longitude (" * degree * ")"), y = expression("Latitude (" * degree * ")"),
    color = "Hora (UTC)", shape = "Classificação"
  ) +  # pt-br
  guides(size = "none", color = F,
         shape = guide_legend(title.position = "top", title.hjust = 0.5)) +
  theme(
    plot.background = element_rect(fill = "transparent", color = "transparent"),
    legend.background = element_rect(fill = "transparent"),
    legend.position = "bottom"
  )

flashes_df <- flashes_brasildat_df %>% 
  filter(as.Date(date) == "2017-11-15")
flashes_df_total <- flashes_qte_total %>% 
  filter(str_sub(case, -11, -2) == "2017-11-15")
plt_flashes <- ggplot(data = flashes_df) +
  scale_x_continuous(limits = lims_in_plot$lon) + scale_y_continuous(limits = lims_in_plot$lat) +
  geom_point(aes(x = lon, y = lat, shape = class, color = hour)) +
  geom_point(aes(x = lon_hailpad, y = lat_hailpad), pch = 17, size = 2) +
  geom_path(data = fortify(cities), aes(long, lat, group = group), inherit.aes = F, colour = "gray50", size = 0.2) +
  geom_label(data = flashes_df_total, aes(x = grid_df$lon, y = grid_df$lat, label = class), size = 3) +
  scale_color_gradientn(colours = cpt(pal = "oc_zeu"), labels = date_format("%H%M"),
                        breaks = pretty_breaks(n = 10), trans = time_trans()) +
  scale_shape_manual(values = c(4, 1)) +
  # labs(x = expression("Longitude ("*degree*")"), y = expression("Latitude ("*degree*")"),
  #      color = "Time (UTC)", shape = "Flash Type") +
  labs(x = expression("Longitude ("*degree*")"), y = expression("Latitude ("*degree*")"),
       color = "Hora (UTC)", shape = "Tipo de Flash") +  # pt-br
  guides(size = "none", color = F,
         shape = guide_legend(title.position = "top", title.hjust = 0.5)) +
  theme(
    plot.background = element_rect(fill = "transparent", color = "transparent"),
    legend.background = element_rect(fill = "transparent"),
    legend.position = "bottom"
  )

legend <- get_legend(
  ggplot(data = flashes_df) +
    scale_x_continuous(limits = lims_in_plot$lon) +
    scale_y_continuous(limits = lims_in_plot$lat) +
    geom_point(aes(x = lon, y = lat, shape = class, color = hour)) +
    geom_point(aes(x = lon_hailpad, y = lat_hailpad), pch = 17, size = 2) +
    geom_path(data = fortify(cities), aes(long, lat, group = group),
              inherit.aes = F, colour = "gray50", size = 0.2) +
    geom_label(data = flashes_df_total, aes(x = grid_df$lon, y = grid_df$lat,
                                            label = class), size = 3) +
    scale_color_gradientn(colours = cpt(pal = "oc_zeu"), labels = date_format("%H%M"),
                          breaks = pretty_breaks(n = 6), trans = time_trans()) +
    scale_shape_manual(values = c(4, 1)) +
    # labs(x = expression("Longitude ("*degree*")"), y = expression("Latitude ("*degree*")"),
    #      color = "Time (UTC)", shape = "Flash\nType") +
    labs(x = expression("Longitude ("*degree*")"), y = expression("Latitude ("*degree*")"),
         color = "Hora (UTC)", shape = "Tipo de\nFlash") +  # pt-br
    guides(size = "none", shape = F, color = guide_colorbar(barheight = 12)) +
    theme(
      plot.background = element_rect(fill = "transparent", color = "transparent"),
      legend.background = element_rect(fill = "transparent")
    )
)

plt <- plot_grid(plt_fortracc, plt_flashes, legend, labels = c("a", "b"), 
                 ncol = 3, rel_widths = c(0.4, 0.4, 0.12))
# save_plot("General_Processing/figures/track_flashes_20171115.png",
#           plot = plt, ncol = 3, base_width = 2.5, base_height = 3.4, bg = "transparent")
save_plot("General_Processing/figures/track_flashes_20171115_ptbr.png",
          plot = plt, ncol = 3, base_width = 2.5, base_height = 3.4, bg = "transparent")  # pt-br

