# ------------------------------------------------------------------------------
# PLOT MISC FIGURES
#-------------------------------------------------------------------------------

# Loading necessary scripts and packages ---------------------------------------
library(ggalt)
library(tidyverse)
library(grid)
library(cowplot)
library(reshape2)
library(directlabels)
library(scales)
library(colorspace)
theme_set(theme_grey())
source("General_Processing/color_palette.R")

# Conceptual model of hydrometeor classification - Straka et al. (2000) --------
hids <- read_csv("Data/GENERAL/hids")

plt_a <- ggplot(hids %>% select(HID, Zh_low, Zh_high),
                aes(x = Zh_low, xend = Zh_high, y = HID, group = HID)) +
  geom_dumbbell(color = "firebrick2", size = 1) +
  scale_y_discrete(limits = rev(hids$HID), name = "") + 
  scale_x_continuous(name = "Reflectivity (dBZ)")

plt_b <- ggplot(hids %>% select(HID, ZDR_low, ZDR_high), 
                aes(x = ZDR_low, xend = ZDR_high, y = HID, group = HID)) +
  geom_dumbbell(color = "chartreuse3", size = 1) +
  scale_y_discrete(limits = rev(hids$HID), name = "") + 
  scale_x_continuous(name = "ZDR (dBZ)")

plt_c <- ggplot(hids %>% select(HID, KDP_low, KDP_high),
                aes(x = KDP_low, xend = KDP_high, y = HID, group = HID)) +
  geom_dumbbell(color = "darkgreen", size = 1) +
  scale_y_discrete(limits = rev(hids$HID), name = "") + 
  scale_x_continuous(name = "KDP (deg/km)")

plt_d <- ggplot(hids %>% select(HID, RHO_low, RHO_high), 
                aes(x = RHO_low, xend = RHO_high, y = HID, group = HID)) +
  geom_dumbbell(color = "deeppink", size = 1) +
  scale_y_discrete(limits = rev(hids$HID), name = "") + 
  scale_x_continuous(name = "RHO (dimensionless)")

plt <- plot_grid(plt_a, plt_b, plt_c, plt_d,
                 labels = c("a", "b", "c", "d"), ncol = 2)
title <- ggdraw() + 
  draw_label("Hydrometeor Classification - Straka et al. (2000)", 
             size = 15, fontface = "bold")
plg <- plot_grid(title, plt, ncol = 1, rel_heights = c(0.1, 1))
save_plot("General_Processing/figures/hids_strakaetal.png", plot = plg,
          ncol = 2, base_width = 5, base_height = 6)

# Reproducing Takahashi (1978) classical figure --------------------------------
takahashi <- t(as.matrix(read_table2("Data/GENERAL/tkhash.q", col_names = FALSE)))
rownames(takahashi) <- seq(0, -30, length.out = 31)
colnames(takahashi) <- exp(log(10) * seq(log10(0.01), log10(30), length.out = 30))

tak_plot <- melt(takahashi)

plt <- ggplot(tak_plot, aes(x = Var1, y = Var2)) +
  scale_x_reverse() + scale_y_log10(breaks = c(0.01, 0.05, 0.1, 0.5, 1, 5, 10, 30)) +
  geom_raster(aes(fill = value)) +
  geom_contour(aes(z = value), colour = "black",
               breaks = c(-65, -55, -45, -35, -25, -15, -5, 5, 15, 25, 35, 45, 55, 65)) +
  scale_fill_gradientn(colours = c("darkblue", "blue", "dodgerblue", "white", 
                                   "brown1", "firebrick2", "darkred"),
                       limits = c(-66, 66)) +
  labs(title = "Takahashi (1978)", fill = "fC", x = "T (°C)", y = "LWC (g/m³)") +
  theme_bw() + theme(panel.grid = element_blank(),
                     plot.title = element_text(hjust = 0.5),
                     legend.key.height = unit(x = 15, units = "mm"))
ggsave("General_Processing/figures/takahashi.png", plot = plt,
       width = 4, height = 4)

# Data available per case ------------------------------------------------------
files_sr <- c(
  dir(path = "Data/RADAR/SR/level_0/2016-12-25/", pattern = "*.mvol", full.names = T),
  dir(path = "Data/RADAR/SR/level_0/2017-01-31/", pattern = "*.mvol", full.names = T),
  dir(path = "Data/RADAR/SR/level_0/2017-03-14/", pattern = "*.mvol", full.names = T),
  dir(path = "Data/RADAR/SR/level_0/2017-11-15/", pattern = "*.mvol", full.names = T),
  dir(path = "Data/RADAR/SR/level_0/2017-11-16/", pattern = "*.mvol", full.names = T)
) %>%
  as.data.frame() %>%
  `colnames<-`("date") %>%
  mutate(date = str_extract(date, "201\\d-\\d\\d-\\d\\d--\\d\\d-\\d\\d")) %>%
  mutate(date = lubridate::ymd_hm(date)) %>%
  mutate(hour = date) %>%
  mutate(date = as.character(lubridate::date(date))) %>%
  mutate(Radar = "SR")

files_cth <- c(
  dir(path = "Data/RADAR/CTH/level_0_hdf5/2016-12-25/", pattern = "*.HDF5", full.names = T),
  dir(path = "Data/RADAR/CTH/level_0_hdf5/2017-01-31/", pattern = "*.HDF5", full.names = T),
  dir(path = "Data/RADAR/CTH/level_0_hdf5/2017-03-14/", pattern = "*.HDF5", full.names = T),
  dir(path = "Data/RADAR/CTH/level_0_hdf5/2017-11-15/", pattern = "*.HDF5", full.names = T),
  dir(path = "Data/RADAR/CTH/level_0_hdf5/2017-11-16/", pattern = "*.HDF5", full.names = T)
) %>%
  as.data.frame() %>%
  `colnames<-`("date") %>%
  mutate(date = str_extract(date, "201\\d\\d\\d\\d\\d\\d\\d\\d\\d")) %>%
  mutate(date = lubridate::ymd_hm(date)) %>%
  mutate(hour = date) %>%
  mutate(date = as.character(lubridate::date(date))) %>%
  mutate(Radar = "FCTH")
lubridate::date(files_sr$hour) <- lubridate::date(files_cth$hour) <- "2017-01-01"

files <- rbind(files_sr, files_cth)

plt <- ggplot(files) +
  geom_tile(aes(y = hour, x = date, fill = Radar),
            position = position_dodge(width = 0.5)) +
  scale_fill_manual(values = c("slateblue", "peru")) +
  labs(title = "'level_0' Weather Radar Data Availability",
       x = "Case", y = "Hour UTC") +
  scale_y_datetime(labels = date_format("%H:%M")) +
  theme(plot.title = element_text(hjust = 0.5), legend.position = "bottom",
        axis.text.y = element_text(angle = 90, hjust = 0.5)) +
  coord_flip()
ggsave("General_Processing/figures/data_availability.png", plot = plt,
       width = 8, height = 5.5)

# Radar strategies -------------------------------------------------------------

#-- Constantes
a <- 6378 #-- km
ke <- 4 / 3
r <- seq(0, 300, .25) #-- km

cth_elevs <- c(1, 1.6, 2.4, 3.2, 4.2, 5.5, 6.9, 8.6)
sr_elevs <- c(
  0.49987793, 0.99975586, 1.99951172, 2.99926758, 3.99902344, 4.9987793,
  5.99853516, 6.99829102, 7.99804688, 8.99780273, 9.99755859, 12.00256348,
  14.0020752, 16.00158691, 18.00109863
)
xpol_elevs <- c(.5, 1.8, 3.1, 4.4, 5.7, 7, 8.3, 9.6, 10.9, 13, 15, 18, 22, 26,
                32, 40, 55)

cth_scan <- merge(r, cth_elevs) %>%
  rename(r = x, elev = y) %>%
  mutate(h = sqrt(r^2 + (ke * a)^2 + 2 * r * ke * a * sin(elev * pi / 180)) - ke * a,
         h_up = sqrt(r^2 + (ke * a)^2 + 2 * r * ke * a * sin((elev + 0.5) * pi / 180)) - ke * a,
         h_down = sqrt(r^2 + (ke * a)^2 + 2 * r * ke * a * sin((elev - 0.5) * pi / 180)) - ke * a,
         elev = as.factor(elev))

sr_scan <- merge(r, sr_elevs) %>%
  rename(r = x, elev = y) %>%
  mutate(h = sqrt(r^2 + (ke * a)^2 + 2 * r * ke * a * sin(elev * pi / 180)) - ke * a,
         h_up = sqrt(r^2 + (ke * a)^2 + 2 * r * ke * a * sin((elev + 1) * pi / 180)) - ke * a,
         h_down = sqrt(r^2 + (ke * a)^2 + 2 * r * ke * a * sin((elev - 1) * pi / 180)) - ke * a,
         elev = round(elev, 1) %>% as.factor(.))

xpol_scan <- merge(r, xpol_elevs) %>%
  rename(r = x, elev = y) %>%
  mutate(h = sqrt(r^2 + (ke * a)^2 + 2 * r * ke * a * sin(elev * pi / 180)) - ke * a,
         h_up = sqrt(r^2 + (ke * a)^2 + 2 * r * ke * a * sin((elev + 0.65) * pi / 180)) - ke * a,
         h_down = sqrt(r^2 + (ke * a)^2 + 2 * r * ke * a * sin((elev - 0.65) * pi / 180)) - ke * a,
         elev = round(elev, 1) %>% as.factor(.))

ggplot(cth_scan, aes(x = r)) +
  geom_ribbon(aes(ymax = h_up, ymin = h_down, fill = elev, color = elev),
              alpha = 0.6, size = 0.1) +
  geom_line(aes(y = h, color = elev), size = 1, linetype = "dotted") +
  labs(
    title = "FCTH Scan Strategy", x = "Range (km)", y = "Height (km)",
    fill = expression("Elevation ("*degree*")"),
    color = expression("Elevation ("*degree*")")
  ) +
  scale_fill_manual(values = pal_scan(length(cth_elevs))) +
  scale_color_manual(values = pal_scan(length(cth_elevs))) +
  coord_cartesian(ylim = c(0, 20), xlim = c(0, 250)) +
  theme(
    plot.title = element_text(hjust = 0.5), legend.position = "bottom",
    plot.background = element_rect(fill = "transparent"),
    legend.background = element_rect(fill = "transparent")
  ) +
  guides(fill = guide_legend(nrow = 1), color = guide_legend(nrow = 1))
ggsave("General_Processing/figures/scan_strategy_cth.png",
       width = 6, height = 4, bg = "transparent")

ggplot(sr_scan, aes(x = r)) +
  geom_ribbon(aes(ymax = h_up, ymin = h_down, fill = elev, color = elev),
              alpha = 0.6, size = 0.1) +
  geom_line(aes(y = h, color = elev), size = 1, linetype = "dotted") +
  labs(
    title = "São Roque Scan Strategy", x = "Range (km)", y = "Height (km)",
    fill = expression("Elevation ("*degree*")"),
    color = expression("Elevation ("*degree*")")
  ) +
  scale_fill_manual(values = pal_scan(length(sr_elevs))) +
  scale_color_manual(values = pal_scan(length(sr_elevs))) +
  coord_cartesian(ylim = c(0, 20), xlim = c(0, 250)) +
  theme(
    plot.title = element_text(hjust = 0.5), legend.position = "bottom",
    plot.background = element_rect(fill = "transparent"),
    legend.background = element_rect(fill = "transparent")
  ) +
  guides(fill = guide_legend(nrow = 2, byrow = T),
         color = guide_legend(nrow = 2, byrow = T))
ggsave("General_Processing/figures/scan_strategy_sr.png",
       width = 6, height = 4.2, bg = "transparent")

ggplot(xpol_scan, aes(x = r)) +
  geom_ribbon(aes(ymax = h_up, ymin = h_down, fill = elev, color = elev),
              alpha = 0.6, size = 0.1) +
  geom_line(aes(y = h, color = elev), size = 1, linetype = "dotted") +
  labs(
    title = "UNICAMP XPOL Scan Strategy", x = "Range (km)", y = "Height (km)",
    fill = expression("Elevation ("*degree*")"),
    color = expression("Elevation ("*degree*")")
  ) +
  scale_fill_manual(values = pal_scan(length(xpol_elevs))) +
  scale_color_manual(values = pal_scan(length(xpol_elevs))) +
  coord_cartesian(ylim = c(0, 20), xlim = c(0, 80)) +
  theme(
    plot.title = element_text(hjust = 0.5), legend.position = "bottom",
    plot.background = element_rect(fill = "transparent"),
    legend.background = element_rect(fill = "transparent")
  ) +
  guides(fill = guide_legend(nrow = 3, byrow = T),
         color = guide_legend(nrow = 3, byrow = T))
ggsave("General_Processing/figures/scan_strategy_xpol.png",
       width = 5.5, height = 5, bg = "transparent")
