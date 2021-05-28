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
         vel = factor(vel, levels = c("Above 0 m/s", "Above 5 m/s", "Above 10 m/s", "Above 15 m/s", "Above 20 m/s"))) %>% 
  group_by(case, vel, level) %>% 
  mutate(time_label = c("Before Hailfall", "During Hailfall"))

# Opening grid used for uvol/im
grid_lims <- read_csv("MultiDoppler_Processing/multidop_out/grid_uvol_im_all_cases.csv", 
                      col_types = cols(date = col_datetime(format = "%Y-%m-%d %H:%M:%S")))

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
uvol_imf <- mutate(uvol_imf, mean_flashes = ifelse(is.na(mean_flashes), 0, mean_flashes),
                   max_flashes = ifelse(max_flashes == -Inf, 0, max_flashes))

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
ggplot(uvol_imf %>% filter(vel == "Above 0 m/s")) +
  geom_point(aes(x = uvol, y = max_flashes, color = case, fill = case, alpha = time_label, shape = level), size = 3) +
  labs(x = expression("Updraft Volume > 0 m"~s^-1 *" ("~km^3 *")"), 
       y = expression("Max Flash Rate (Flashes"~min^-1 *")")) +
  scale_shape_manual(values = c(24, 25), name = "") +
  scale_alpha_discrete(range = c(0.3, 1), name = "", ) +
  scale_color_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  scale_fill_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  guides(color = guide_legend(keyheight=0.9, order = 1, default.unit = "cm"), shape = guide_legend(order = 2), alpha = guide_legend(order = 3), fill = F)
ggsave("MultiDoppler_Processing/figures/uvol_imf_studies/uvol_maxflashes_0ms.png", width = 6, height = 3.5, dpi=300)

ggplot(uvol_imf %>% filter(vel == "Above 5 m/s")) +
  geom_point(aes(x = uvol, y = max_flashes, color = case, fill = case, alpha = time_label, shape = level), size = 3) +
  labs(x = expression("Updraft Volume > 5 m"~s^-1 *" ("~km^3 *")"), 
       y = expression("Max Flash Rate (Flashes"~min^-1 *")")) +
  scale_shape_manual(values = c(24, 25), name = "") +
  scale_alpha_discrete(range = c(0.3, 1), name = "", ) +
  scale_color_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  scale_fill_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  guides(color = guide_legend(keyheight=0.9, order = 1, default.unit = "cm"), shape = guide_legend(order = 2), alpha = guide_legend(order = 3), fill = F)
ggsave("MultiDoppler_Processing/figures/uvol_imf_studies/uvol_maxflashes_5ms.png", width = 6, height = 3.5, dpi=300)

ggplot(uvol_imf %>% filter(vel == "Above 10 m/s")) +
  geom_point(aes(x = uvol, y = max_flashes, color = case, fill = case, alpha = time_label, shape = level), size = 3) +
  labs(x = expression("Updraft Volume > 10 m"~s^-1 *" ("~km^3 *")"), 
       y = expression("Max Flash Rate (Flashes"~min^-1 *")")) +
  scale_shape_manual(values = c(24, 25), name = "") +
  scale_alpha_discrete(range = c(0.3, 1), name = "", ) +
  scale_color_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  scale_fill_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  guides(color = guide_legend(keyheight=0.9, order = 1, default.unit = "cm"), shape = guide_legend(order = 2), alpha = guide_legend(order = 3), fill = F)
ggsave("MultiDoppler_Processing/figures/uvol_imf_studies/uvol_maxflashes_10ms.png", width = 6, height = 3.5, dpi=300)

# Total mass vs flashes
ggplot(uvol_imf %>% filter(vel == "Above 0 m/s")) +
  geom_point(aes(x = im, y = max_flashes, color = case, fill = case, alpha = time_label, shape = level), size = 3) +
  labs(x = expression("Total Ice Mass (kg)"), 
       y = expression("Max Flash Rate (Flashes"~min^-1 *")")) +
  scale_shape_manual(values = c(24, 25), name = "") +
  scale_alpha_discrete(range = c(0.3, 1), name = "", ) +
  scale_color_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  scale_fill_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  guides(color = guide_legend(keyheight=0.9, order = 1, default.unit = "cm"), shape = guide_legend(order = 2), alpha = guide_legend(order = 3), fill = F)
ggsave("MultiDoppler_Processing/figures/uvol_imf_studies/mass_maxflashes_0ms.png", width = 6, height = 3.5, dpi=300)

# Mass flux vs flashes
ggplot(uvol_imf %>% filter(vel == "Above 0 m/s")) +
  geom_point(aes(x = max_imf, y = max_flashes, color = case, fill = case, alpha = time_label, shape = level), size = 3) +
  labs(x = expression("Max Ice Mass Flux (kg"~m^-2 *"s)"),
       y = expression("Max Flash Rate (Flashes"~min^-1 *")")) +
  scale_shape_manual(values = c(24, 25), name = "") +
  scale_alpha_discrete(range = c(0.3, 1), name = "", ) +
  scale_color_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  scale_fill_manual(values = c("darkred", "darkblue", "darkgreen"), name = "") +
  guides(color = guide_legend(keyheight=0.9, order = 1, default.unit = "cm"), shape = guide_legend(order = 2), alpha = guide_legend(order = 3), fill = F)
ggsave("MultiDoppler_Processing/figures/uvol_imf_studies/maximf_maxflashes_0ms.png", width = 6, height = 3.5, dpi=300)

