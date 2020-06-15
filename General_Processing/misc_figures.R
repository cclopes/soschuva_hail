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
theme_set(theme_bw())
source("General_Processing/color_palette.R")

# Conceptual model of hydrometeor classification - Straka et al. (2000) --------
hids <- read_csv("Data/GENERAL/hids")
hids$HID <- c("Chuvisco", "Chuva", "Cristais de Gelo", "Agregados", "Neve Molhada",
              "Gelo Vertical", "Graupel de Densidade Baixa", "Graupel de Densidade Alta",
              "Granizo", "Gotas Grandes", "Chuva + Granizo")  # pt-br

plt_a <- ggplot(hids %>% select(HID, Zh_low, Zh_high),
                aes(x = Zh_low, xend = Zh_high, y = HID, group = HID)) +
  geom_dumbbell(color = "firebrick2", size = 1) +
  theme(
    plot.background = element_rect(fill = "transparent", color = "transparent"),
    legend.background = element_rect(fill = "transparent")
  ) +
  scale_y_discrete(limits = rev(hids$HID), name = "") + 
  # scale_x_continuous(name = "Reflectivity (dBZ)")
  scale_x_continuous(name = "Refletividade (dBZ)")  # pt-br

plt_b <- ggplot(hids %>% select(HID, ZDR_low, ZDR_high), 
                aes(x = ZDR_low, xend = ZDR_high, y = HID, group = HID)) +
  geom_dumbbell(color = "chartreuse3", size = 1) +
  theme(
    plot.background = element_rect(fill = "transparent", color = "transparent"),
    legend.background = element_rect(fill = "transparent")
  ) +
  scale_y_discrete(limits = rev(hids$HID), name = "") + 
  # scale_x_continuous(name = "Differential Reflectivity (dB)")
  scale_x_continuous(name = "Refletividade Diferencial (dB)")  # pt-br

plt_c <- ggplot(hids %>% select(HID, KDP_low, KDP_high),
                aes(x = KDP_low, xend = KDP_high, y = HID, group = HID)) +
  geom_dumbbell(color = "darkgreen", size = 1) +
  theme(
    plot.background = element_rect(fill = "transparent", color = "transparent"),
    legend.background = element_rect(fill = "transparent")
  ) +
  scale_y_discrete(limits = rev(hids$HID), name = "") + 
  # scale_x_continuous(name = expression("Specific Differential Phase ("*degree*km^-1*")"))
  scale_x_continuous(name = expression("Fase Diferencial Específica ("*degree*km^-1*")"))  # pt-br

plt_d <- ggplot(hids %>% select(HID, RHO_low, RHO_high), 
                aes(x = RHO_low, xend = RHO_high, y = HID, group = HID)) +
  geom_dumbbell(color = "deeppink", size = 1) +
  theme(
    plot.background = element_rect(fill = "transparent", color = "transparent"),
    legend.background = element_rect(fill = "transparent")
  ) +
  scale_y_discrete(limits = rev(hids$HID), name = "") + 
  # scale_x_continuous(name = "Cross Correlation Ratio (dimensionless)")
  scale_x_continuous(name = "Razão de Correlação Cruzada (adimensional)") # pt-br

plt <- plot_grid(plt_a, plt_b, plt_c, plt_d,
                 labels = c("a", "b", "c", "d"), ncol = 2)
# save_plot("General_Processing/figures/hids_strakaetal.png", plot = plt,
#           ncol = 2, base_width = 5, base_height = 6, bg = "transparent")
save_plot("General_Processing/figures/hids_strakaetal_ptbr.png", plot = plt,
          ncol = 2, base_width = 5, base_height = 6, bg = "transparent")  # pt-br

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
  # labs(fill = "fC", x = expression("Temperature ("*degree*"C)"),
  #      y = expression("Liquid Water Content (g"*m^-3*")")) +
  labs(fill = "fC", x = expression("Temperatura ("*degree*"C)"),
       y = expression("Conteúdo de Água Líquida (g"*m^-3*")")) +  # pt-br
  theme(panel.grid = element_blank(),
        plot.title = element_text(hjust = 0.5),
        legend.key.height = unit(x = 15, units = "mm"),
        plot.background = element_rect(fill = "transparent", color = "transparent"),
        legend.background = element_rect(fill = "transparent"))
# ggsave("General_Processing/figures/takahashi.png", plot = plt,
#        width = 4, height = 4, bg = "transparent")
ggsave("General_Processing/figures/takahashi_ptbr.png", plot = plt,
       width = 4, height = 4, bg = "transparent")  # pt-br

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

files_xpol <- c(
  dir(path = "Data/RADAR/UNICAMP/level_0/2017-11-15/", pattern = "*.HDF5", full.names = T),
  dir(path = "Data/RADAR/UNICAMP/level_0/2017-11-16/", pattern = "*.HDF5", full.names = T)
) %>%
  as.data.frame() %>%
  `colnames<-`("date") %>%
  mutate(date = str_extract(date, "201\\d\\d\\d\\d\\d\\d\\d\\d\\d")) %>%
  mutate(date = lubridate::ymd_hm(date)) %>%
  mutate(hour = date) %>%
  mutate(date = as.character(lubridate::date(date))) %>%
  mutate(Radar = "XPOL")

lubridate::date(files_sr$hour) <- lubridate::date(files_cth$hour) <-
  lubridate::date(files_xpol$hour) <- "2017-01-01"

files <- rbind(files_sr, files_cth, files_xpol)

plt <- ggplot(files) +
  geom_tile(aes(y = hour, x = date, fill = Radar),
            position = position_dodge(width = 0.5)) +
  scale_fill_manual(values = c("slateblue", "peru", "forestgreen")) +
  labs(title = "'level_0' Weather Radar Data Availability",
       x = "Case", y = "Hour UTC") +
  scale_y_datetime(labels = date_format("%H:%M")) +
  theme(plot.title = element_text(hjust = 0.5), legend.position = "bottom",
        axis.text.y = element_text(angle = 90, hjust = 0.5),
        plot.background = element_rect(fill = "transparent", color = "transparent"),
        legend.background = element_rect(fill = "transparent")
  ) +
  coord_flip()
ggsave("General_Processing/figures/data_availability.png", plot = plt,
       width = 8, height = 5.5, bg = "transparent")
