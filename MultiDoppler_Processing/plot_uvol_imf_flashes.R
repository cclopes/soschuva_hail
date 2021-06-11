library(readr)
library(magrittr)
library(dplyr)
library(lubridate)
library(ggplot2)
load("General_Processing/lifecycle_data.RData")

# Opening uvol/im file and adding imf
uvol_imf <- read_csv("MultiDoppler_Processing/multidop_out/updraft_vol_im_all_cases.csv", 
                  col_types = cols(X1 = col_skip(), 
                                   time = col_datetime(format = "%Y-%m-%d %H:%M:%S"))) %>% 
  mutate(time = strftime(time, format = "%H%M", tz = "UTC"),
         level = factor(level, levels = c("Above -40°C", "0°C > T > -40°C", "Below 0°C"))) %>% 
  group_by(case, vel, level) %>% 
  mutate(time_label = c("Before Hailfall", "During Hailfall"))

# Opening grid used for uvol/im
grid_lims <- read_csv("MultiDoppler_Processing/multidop_out/grid_uvol_im_all_cases.csv", 
                      col_types = cols(date = col_datetime(format = "%Y-%m-%d %H:%M:%S")))

# Opening Deierling data files
deier_upvol_flashes <- read_delim("Data/GENERAL/deierling_figs/data_deierling_2008_upvol_meanflashes.csv", 
                                  ";", escape_double = F, col_names = c("uvol", "mean_flashes"), 
                                  locale = locale(decimal_mark = ",", grouping_mark = "."), trim_ws = T)
# deier_ppt_flashes <- read_delim("Data/GENERAL/deierling_figs/data_deierling_2006_pptice_meanflashes.csv", 
#                                   ";", escape_double = F, col_names = c("ppt_ice", "mean_flashes"), 
#                                   locale = locale(decimal_mark = ",", grouping_mark = "."), trim_ws = T)
# deier_nonppt_flashes <- read_delim("Data/GENERAL/deierling_figs/data_deierling_2006_nonpptice_meanflashes.csv", 
#                                   ";", escape_double = F, col_names = c("nonppt_ice", "mean_flashes"), 
#                                   locale = locale(decimal_mark = ",", grouping_mark = "."), trim_ws = T)

# Selecting flashes based on grid
uvol_imf[which(uvol_imf$time == "1820"), c("mean_flashes", "max_flashes")] <- flashes_brasildat_df %>%
  filter((date > (grid_lims$date[1] - 600) & date <= grid_lims$date[1]) &
           (lon >= grid_lims$min_lon[1] & lon <= grid_lims$max_lon[1]) &
           (lat >= grid_lims$max_lon[1] & lat <= grid_lims$max_lat[1])) %>% 
  mutate(interval = floor_date(date, unit = "minute")) %>% 
  group_by(interval) %>%
  summarise(sum_min = n()) %>%
  summarise(mean_flashes = mean(sum_min), max_flashes = max(sum_min)) %>% 
  select(mean_flashes, max_flashes) %>% 
  as.list()
uvol_imf[which(uvol_imf$time == "1830"), c("mean_flashes", "max_flashes")] <- flashes_brasildat_df %>%
  filter((date > (grid_lims$date[2] - 600) & date <= grid_lims$date[2]) &
           (lon >= grid_lims$min_lon[2] & lon <= grid_lims$max_lon[2]) &
           (lat >= grid_lims$max_lon[2] & lat <= grid_lims$max_lat[2])) %>% 
  mutate(interval = floor_date(date, unit = "minute")) %>% 
  group_by(interval) %>%
  summarise(sum_min = n()) %>%
  summarise(mean_flashes = mean(sum_min), max_flashes = max(sum_min)) %>% 
  select(mean_flashes, max_flashes) %>% 
  as.list()
uvol_imf[which(uvol_imf$time == "1950"), c("mean_flashes", "max_flashes")] <- flashes_brasildat_df %>%
  filter((date > (grid_lims$date[3] - 600) & date <= grid_lims$date[3]) &
           (lon >= grid_lims$min_lon[3] & lon <= grid_lims$max_lon[3]) &
           (lat >= grid_lims$max_lon[3] & lat <= grid_lims$max_lat[3])) %>% 
  mutate(interval = floor_date(date, unit = "minute")) %>% 
  group_by(interval) %>%
  summarise(sum_min = n()) %>%
  summarise(mean_flashes = mean(sum_min), max_flashes = max(sum_min)) %>% 
  select(mean_flashes, max_flashes) %>% 
  as.list()
uvol_imf[which(uvol_imf$time == "2000"), c("mean_flashes", "max_flashes")] <- flashes_brasildat_df %>%
  filter((date > (grid_lims$date[4] - 600) & date <= grid_lims$date[4]) &
           (lon >= grid_lims$min_lon[4] & lon <= grid_lims$max_lon[4]) &
           (lat >= grid_lims$max_lon[4] & lat <= grid_lims$max_lat[4])) %>% 
  mutate(interval = floor_date(date, unit = "minute")) %>% 
  group_by(interval) %>%
  summarise(sum_min = n()) %>%
  summarise(mean_flashes = mean(sum_min), max_flashes = max(sum_min)) %>% 
  select(mean_flashes, max_flashes) %>% 
  as.list()
uvol_imf[which(uvol_imf$time == "2140"), c("mean_flashes", "max_flashes")] <- flashes_brasildat_df %>%
  filter((date > (grid_lims$date[5] - 600) & date <= grid_lims$date[5]) &
           (lon >= grid_lims$min_lon[5] & lon <= grid_lims$max_lon[5]) &
           (lat >= grid_lims$max_lon[5] & lat <= grid_lims$max_lat[5])) %>% 
  mutate(interval = floor_date(date, unit = "minute")) %>% 
  group_by(interval) %>%
  summarise(sum_min = n()) %>%
  summarise(mean_flashes = mean(sum_min), max_flashes = max(sum_min)) %>% 
  select(mean_flashes, max_flashes) %>% 
  as.list()
uvol_imf[which(uvol_imf$time == "2150"), c("mean_flashes", "max_flashes")] <- flashes_brasildat_df %>%
  filter((date > (grid_lims$date[6] - 600) & date <= grid_lims$date[6]) &
           (lon >= grid_lims$min_lon[6] & lon <= grid_lims$max_lon[6]) &
           (lat >= grid_lims$max_lon[6] & lat <= grid_lims$max_lat[6])) %>% 
  mutate(interval = floor_date(date, unit = "minute")) %>% 
  group_by(interval) %>%
  summarise(sum_min = n()) %>%
  summarise(mean_flashes = mean(sum_min), max_flashes = max(sum_min)) %>% 
  select(mean_flashes, max_flashes) %>% 
  as.list()

# Changing NAs to 0
# uvol_imf <- mutate(uvol_imf, mean_flashes = ifelse(is.na(mean_flashes), 0, mean_flashes),
#                    max_flashes = ifelse(max_flashes == -Inf, 0, max_flashes))

# Plotting
theme_set(theme_bw())
theme_update(plot.title = element_text(hjust = 0.5))

# Updraft vol only
# ggplot(uvol_imf) +
#   geom_col(aes(x = time, y = uvol/1e9, fill = vel), position = "dodge") +
#   # scale_y_log10(limits = c(2, 1e15)) +
#   labs(x = "Time (UTC)", y = "Updraft Volume (km³)", fill = "") +
#   facet_grid(level ~ case, scales = "free_x")

# Updraft vol vs flashes
# MEAN FLASH RATE
ggplot(data = uvol_imf %>% filter(vel == "Above 0 m/s")) +
  geom_point(aes(x = uvol, y = mean_flashes, color = case, fill = case, alpha = time_label, shape = level), 
             size = 3) +
  labs(x = expression("Updraft Volume > 0 m"~s^-1 *" ("~m^3 *")"), 
       y = expression("Mean Flash Rate (Flashes"~min^-1 *")")) +
  scale_x_log10(limits = c(1e9, 1e13)) +
  scale_y_log10(limits = c(1e-1, 1e3)) +
  scale_shape_manual(values = c(24, 22, 25), name = "") +
  scale_alpha_discrete(range = c(0.3, 1), name = "", ) +
  scale_color_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  scale_fill_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  guides(color = guide_legend(keyheight=0.9, order = 1, default.unit = "cm"), 
         shape = guide_legend(order = 2), 
         alpha = guide_legend(order = 3), 
         fill = F) +
  theme(legend.background = element_rect(fill = NA), legend.spacing = unit(-0.5, "cm"))
ggsave("MultiDoppler_Processing/figures/uvol_imf_studies/uvol_meanflashes_0ms.png", width = 6, height = 3.5, dpi=300)

ggplot(uvol_imf %>% filter(vel == "Above 5 m/s")) +
  geom_point(data = deier_upvol_flashes, aes(x = uvol, y = mean_flashes), shape = 18, color = "gray", size = 2) +
  geom_point(aes(x = uvol, y = mean_flashes, color = case, fill = case, alpha = time_label, shape = level), 
             size = 3) +
  geom_label(aes(x = 1e12, y = 1e3), label = "◆  Deierling and Petersen (2008)", size = 3) +
  labs(x = expression("Updraft Volume > 5 m"~s^-1 *" ("~m^3 *")"), 
       y = expression("Mean Flash Rate (Flashes"~min^-1 *")")) +
  scale_x_log10(limits = c(1e9, 1e13)) +
  scale_y_log10(limits = c(1e-1, 1e3)) +
  scale_shape_manual(values = c(24, 22, 25, 18), name = "") +
  scale_alpha_discrete(range = c(0.3, 1), name = "", ) +
  scale_color_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  scale_fill_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  guides(color = guide_legend(keyheight=0.9, order = 1, default.unit = "cm"), 
         shape = guide_legend(order = 2), 
         alpha = guide_legend(order = 3), 
         fill = F) +
  theme(legend.background = element_rect(fill = NA), legend.spacing = unit(-0.5, "cm"))
ggsave("MultiDoppler_Processing/figures/uvol_imf_studies/uvol_meanflashes_5ms.png", width = 6, height = 3.5, dpi=300)

ggplot(uvol_imf %>% filter(vel == "Above 10 m/s")) +
  geom_point(aes(x = uvol, y = mean_flashes, color = case, fill = case, alpha = time_label, shape = level), size = 3) +
  labs(x = expression("Updraft Volume > 10 m"~s^-1 *" ("~m^3 *")"), 
       y = expression("Mean Flash Rate (Flashes"~min^-1 *")")) +
  scale_x_log10(limits = c(1e9, 1e13)) +
  scale_y_log10(limits = c(1e-1, 1e3)) +
  scale_shape_manual(values = c(24, 22, 25), name = "") +
  scale_alpha_discrete(range = c(0.3, 1), name = "", ) +
  scale_color_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  scale_fill_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  guides(color = guide_legend(keyheight=0.9, order = 1, default.unit = "cm"), 
         shape = guide_legend(order = 2), 
         alpha = guide_legend(order = 3), 
         fill = F) +
  theme(legend.background = element_rect(fill = NA), legend.spacing = unit(-0.5, "cm"))
ggsave("MultiDoppler_Processing/figures/uvol_imf_studies/uvol_meanflashes_10ms.png", width = 6, height = 3.5, dpi=300)

# MAX FLASH RATE
ggplot(uvol_imf %>% filter(vel == "Above 0 m/s")) +
  geom_point(aes(x = uvol, y = max_flashes, color = case, fill = case, alpha = time_label, shape = level), size = 3) +
  labs(x = expression("Updraft Volume > 0 m"~s^-1 *" ("~m^3 *")"), 
       y = expression("Max Flash Rate (Flashes"~min^-1 *")")) +
  scale_x_log10(limits = c(1e9, 1e13)) +
  scale_y_log10(limits = c(1e-1, 1e3)) +
  scale_shape_manual(values = c(24, 22, 25), name = "") +
  scale_alpha_discrete(range = c(0.3, 1), name = "", ) +
  scale_color_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  scale_fill_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  guides(color = guide_legend(keyheight=0.9, order = 1, default.unit = "cm"), 
         shape = guide_legend(order = 2), 
         alpha = guide_legend(order = 3), 
         fill = F) +
  theme(legend.background = element_rect(fill = NA), legend.spacing = unit(-0.5, "cm"))
ggsave("MultiDoppler_Processing/figures/uvol_imf_studies/uvol_maxflashes_0ms.png", width = 6, height = 3.5, dpi=300)

ggplot(uvol_imf %>% filter(vel == "Above 5 m/s")) +
  geom_point(aes(x = uvol, y = max_flashes, color = case, fill = case, alpha = time_label, shape = level), size = 3) +
  labs(x = expression("Updraft Volume > 5 m"~s^-1 *" ("~m^3 *")"), 
       y = expression("Max Flash Rate (Flashes"~min^-1 *")")) +
  scale_x_log10(limits = c(1e9, 1e13)) +
  scale_y_log10(limits = c(1e-1, 1e3)) +
  scale_shape_manual(values = c(24, 22, 25), name = "") +
  scale_alpha_discrete(range = c(0.3, 1), name = "", ) +
  scale_color_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  scale_fill_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  guides(color = guide_legend(keyheight=0.9, order = 1, default.unit = "cm"), 
         shape = guide_legend(order = 2), 
         alpha = guide_legend(order = 3), 
         fill = F) +
  theme(legend.background = element_rect(fill = NA), legend.spacing = unit(-0.5, "cm"))
ggsave("MultiDoppler_Processing/figures/uvol_imf_studies/uvol_maxflashes_5ms.png", width = 6, height = 3.5, dpi=300)

ggplot(uvol_imf %>% filter(vel == "Above 10 m/s")) +
  geom_point(aes(x = uvol, y = max_flashes, color = case, fill = case, alpha = time_label, shape = level), size = 3) +
  labs(x = expression("Updraft Volume > 10 m"~s^-1 *" ("~m^3 *")"), 
       y = expression("Max Flash Rate (Flashes"~min^-1 *")")) +
  scale_x_log10(limits = c(1e9, 1e13)) +
  scale_y_log10(limits = c(1e-1, 1e3)) +
  scale_shape_manual(values = c(24, 22, 25), name = "") +
  scale_alpha_discrete(range = c(0.3, 1), name = "", ) +
  scale_color_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  scale_fill_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  guides(color = guide_legend(keyheight=0.9, order = 1, default.unit = "cm"), 
         shape = guide_legend(order = 2), 
         alpha = guide_legend(order = 3), 
         fill = F) +
  theme(legend.background = element_rect(fill = NA), legend.spacing = unit(-0.5, "cm"))
ggsave("MultiDoppler_Processing/figures/uvol_imf_studies/uvol_maxflashes_10ms.png", width = 6, height = 3.5, dpi=300)

# Total mass vs flashes
# MEAN FLASH RATE
ggplot(uvol_imf %>% filter(vel == "Above 0 m/s")) +
  geom_point(aes(x = im, y = mean_flashes, color = case, fill = case, alpha = time_label, shape = level), size = 3) +
  labs(x = expression("Total Ice Mass (kg)"), 
       y = expression("Mean Flash Rate (Flashes"~min^-1 *")")) +
  scale_x_log10(limits = c(1e8, 1e16)) +
  scale_y_log10(limits = c(1e-1, 1e3)) +
  scale_shape_manual(values = c(24, 22, 25), name = "") +
  scale_alpha_discrete(range = c(0.3, 1), name = "", ) +
  scale_color_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  scale_fill_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  guides(color = guide_legend(keyheight=0.9, order = 1, default.unit = "cm"), 
         shape = guide_legend(order = 2), 
         alpha = guide_legend(order = 3), 
         fill = F) +
  theme(legend.background = element_rect(fill = NA), legend.spacing = unit(-0.5, "cm"))
ggsave("MultiDoppler_Processing/figures/uvol_imf_studies/mass_meanflashes_0ms.png", width = 6, height = 3.5, dpi=300)

# MAX FLASH RATE
ggplot(uvol_imf %>% filter(vel == "Above 0 m/s")) +
  geom_point(aes(x = im, y = max_flashes, color = case, fill = case, alpha = time_label, shape = level), size = 3) +
  labs(x = expression("Total Ice Mass (kg)"), 
       y = expression("Max Flash Rate (Flashes"~min^-1 *")")) +
  scale_x_log10(limits = c(1e8, 1e16)) +
  scale_y_log10(limits = c(1e-1, 1e3)) +
  scale_shape_manual(values = c(24, 22, 25), name = "") +
  scale_alpha_discrete(range = c(0.3, 1), name = "", ) +
  scale_color_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  scale_fill_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  guides(color = guide_legend(keyheight=0.9, order = 1, default.unit = "cm"), 
         shape = guide_legend(order = 2), 
         alpha = guide_legend(order = 3), 
         fill = F) +
  theme(legend.background = element_rect(fill = NA), legend.spacing = unit(-0.5, "cm"))
ggsave("MultiDoppler_Processing/figures/uvol_imf_studies/mass_maxflashes_0ms.png", width = 6, height = 3.5, dpi=300)

# Mass flux vs flashes
# MEAN FLASH RATE, MEAN IMF
ggplot(uvol_imf %>% filter(vel == "Above 0 m/s")) +
  geom_point(aes(x = mean_imf, y = mean_flashes, color = case, fill = case, alpha = time_label, shape = level), size = 3) +
  labs(x = expression("Mean Ice Mass Flux (kg"~m^-2~s^-1*")"),
       y = expression("Mean Flash Rate (Flashes"~min^-1 *")")) +
  scale_x_log10(limits = c(1e-2, 1e6)) +
  scale_y_log10(limits = c(1e-1, 1e3)) +
  scale_shape_manual(values = c(24, 22, 25), name = "") +
  scale_alpha_discrete(range = c(0.3, 1), name = "", ) +
  scale_color_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  scale_fill_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  guides(color = guide_legend(keyheight=0.9, order = 1, default.unit = "cm"), 
         shape = guide_legend(order = 2), 
         alpha = guide_legend(order = 3), 
         fill = F) +
  theme(legend.background = element_rect(fill = NA), legend.spacing = unit(-0.5, "cm"))
ggsave("MultiDoppler_Processing/figures/uvol_imf_studies/meanimf_meanflashes_0ms.png", width = 6, height = 3.5, dpi=300)

# MEAN FLASH RATE, MAX IMF
ggplot(uvol_imf %>% filter(vel == "Above 0 m/s")) +
  geom_point(aes(x = max_imf, y = mean_flashes, color = case, fill = case, alpha = time_label, shape = level), size = 3) +
  labs(x = expression("Max Ice Mass Flux (kg"~m^-2~s^-1*")"),
       y = expression("Mean Flash Rate (Flashes"~min^-1 *")")) +
  scale_x_log10(limits = c(1e-2, 1e6)) +
  scale_y_log10(limits = c(1e-1, 1e3)) +
  scale_shape_manual(values = c(24, 22, 25), name = "") +
  scale_alpha_discrete(range = c(0.3, 1), name = "", ) +
  scale_color_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  scale_fill_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  guides(color = guide_legend(keyheight=0.9, order = 1, default.unit = "cm"), 
         shape = guide_legend(order = 2), 
         alpha = guide_legend(order = 3), 
         fill = F) +
  theme(legend.background = element_rect(fill = NA), legend.spacing = unit(-0.5, "cm"))
ggsave("MultiDoppler_Processing/figures/uvol_imf_studies/maximf_meanflashes_0ms.png", width = 6, height = 3.5, dpi=300)


# MAX FLASH RATE, MEAN IMF
ggplot(uvol_imf %>% filter(vel == "Above 0 m/s")) +
  geom_point(aes(x = mean_imf, y = max_flashes, color = case, fill = case, alpha = time_label, shape = level), size = 3) +
  labs(x = expression("Mean Ice Mass Flux (kg"~m^-2~s^-1*")"),
       y = expression("Max Flash Rate (Flashes"~min^-1 *")")) +
  scale_x_log10(limits = c(1e-2, 1e6)) +
  scale_y_log10(limits = c(1e-1, 1e3)) +
  scale_shape_manual(values = c(24, 22, 25), name = "") +
  scale_alpha_discrete(range = c(0.3, 1), name = "", ) +
  scale_color_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  scale_fill_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  guides(color = guide_legend(keyheight=0.9, order = 1, default.unit = "cm"), 
         shape = guide_legend(order = 2), 
         alpha = guide_legend(order = 3), 
         fill = F) +
  theme(legend.background = element_rect(fill = NA), legend.spacing = unit(-0.5, "cm"))
ggsave("MultiDoppler_Processing/figures/uvol_imf_studies/meanimf_maxflashes_0ms.png", width = 6, height = 3.5, dpi=300)


# MAX FLASH RATE, MAX IMF
ggplot(uvol_imf %>% filter(vel == "Above 0 m/s")) +
  geom_point(aes(x = max_imf, y = max_flashes, color = case, fill = case, alpha = time_label, shape = level), size = 3) +
  labs(x = expression("Max Ice Mass Flux (kg"~m^-2~s^-1*")"),
       y = expression("Max Flash Rate (Flashes"~min^-1 *")")) +
  scale_x_log10(limits = c(1e-2, 1e6)) +
  scale_y_log10(limits = c(1e-1, 1e3)) +
  scale_shape_manual(values = c(24, 22, 25), name = "") +
  scale_alpha_discrete(range = c(0.3, 1), name = "", ) +
  scale_color_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  scale_fill_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  guides(color = guide_legend(keyheight=0.9, order = 1, default.unit = "cm"), 
         shape = guide_legend(order = 2), 
         alpha = guide_legend(order = 3), 
         fill = F) +
  theme(legend.background = element_rect(fill = NA), legend.spacing = unit(-0.5, "cm"))
ggsave("MultiDoppler_Processing/figures/uvol_imf_studies/maximf_maxflashes_0ms.png", width = 6, height = 3.5, dpi=300)
