# ---------------------------------------------------------------------
# Calculate and plot radar strategies
# ---------------------------------------------------------------------

# Loading necessary scripts and packages
require(ggalt)
require(tidyverse)
require(grid)
require(reshape2)
require(directlabels)
require(scales)
require(colorspace)
require(patchwork)
source("General_Processing/color_palette.R")

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

# Plotting
theme_set(theme_bw())

plt_cth <- ggplot(cth_scan, aes(x = r)) +
  geom_vline(aes(y = h), xintercept = c(61.4, 221), linetype = 'dashed') +
  geom_ribbon(aes(ymax = h_up, ymin = h_down, fill = elev, color = elev),
              alpha = 0.6, size = 0.1) +
  geom_line(aes(y = h, color = elev), size = 1, linetype = "dotted") +
  labs(
    title = "FCTH", x = "Range (km)", y = "Height (km)",
    fill = expression("Elevation ("*degree*")"),
    color = expression("Elevation ("*degree*")")
  ) +
  # labs(
  #   title = "Estratégia de Varredura - FCTH", x = "Alcance (km)", y = "Altura (km)",
  #   fill = expression("Elevação ("*degree*")"),
  #   color = expression("Elevação ("*degree*")")
  # ) +  # pt-br
  scale_fill_manual(values = pal_scan(length(cth_elevs))) +
  scale_color_manual(values = pal_scan(length(cth_elevs))) +
  coord_cartesian(ylim = c(0, 20), xlim = c(0, 250)) +
  theme(
    plot.title = element_text(hjust = 0.5),
    plot.background = element_rect(fill = "transparent", color = "transparent"),
    legend.background = element_rect(fill = "transparent")
  )

plt_sr <- ggplot(sr_scan, aes(x = r)) +
  geom_vline(aes(y = h), xintercept = c(7.9, 168), linetype = 'dashed') +
  geom_ribbon(aes(ymax = h_up, ymin = h_down, fill = elev, color = elev),
              alpha = 0.6, size = 0.1) +
  geom_line(aes(y = h, color = elev), size = 1, linetype = "dotted") +
  labs(
    title = "São Roque", x = "Range (km)", y = "Height (km)",
    fill = expression("Elevation ("*degree*")"),
    color = expression("Elevation ("*degree*")")
  ) +
  # labs(
  #   title = "Estratégia de Varredura - São Roque", x = "Alcance (km)", y = "Altura (km)",
  #   fill = expression("Elevação ("*degree*")"),
  #   color = expression("Elevação ("*degree*")")
  # ) +  # pt-br
  scale_fill_manual(values = pal_scan(length(sr_elevs))) +
  scale_color_manual(values = pal_scan(length(sr_elevs))) +
  coord_cartesian(ylim = c(0, 20), xlim = c(0, 250)) +
  theme(
    plot.title = element_text(hjust = 0.5),
    plot.background = element_rect(fill = "transparent", color = "transparent"),
    legend.background = element_rect(fill = "transparent")
  ) +
  guides(fill = guide_legend(ncol = 2),
         color = guide_legend(ncol = 2))

plt_xpol <- ggplot(xpol_scan, aes(x = r)) +
  geom_vline(aes(y = h), xintercept = c(0, 80), linetype = 'dashed') +
  geom_ribbon(aes(ymax = h_up, ymin = h_down, fill = elev, color = elev),
              alpha = 0.6, size = 0.1) +
  geom_line(aes(y = h, color = elev), size = 1, linetype = "dotted") +
  labs(
    title = "XPOL", x = "Range (km)", y = "Height (km)",
    fill = expression("Elevation ("*degree*")"),
    color = expression("Elevation ("*degree*")")
  ) +
  # labs(
  #   title = "Estratégia de Varredura - XPOL", x = "Alcance (km)", y = "Altura (km)",
  #   fill = expression("Elevação ("*degree*")"),
  #   color = expression("Elevação ("*degree*")")
  # ) +  # pt-br
  scale_fill_manual(values = pal_scan(length(xpol_elevs))) +
  scale_color_manual(values = pal_scan(length(xpol_elevs))) +
  coord_cartesian(ylim = c(0, 20), xlim = c(0, 100)) +
  theme(
    plot.title = element_text(hjust = 0.5),
    plot.background = element_rect(fill = "transparent", color = "transparent"),
    legend.background = element_rect(fill = "transparent")
  ) +
  guides(fill = guide_legend(ncol = 2),
         color = guide_legend(ncol = 2))
# ggsave("General_Processing/figures/scan_strategy_xpol.png",
#        width = 6, height = 3, bg = "transparent")
# ggsave("General_Processing/figures/scan_strategy_xpol_ptbr.png",
#        width = 6, height = 3, bg = "transparent")

plt_cth + plt_sr + plt_xpol +
  plot_layout(ncol = 1) +
  plot_annotation(tag_levels = "a") &
  theme(plot.background = element_rect(fill = "transparent", 
                                       color = "transparent"),
        legend.background = element_rect(fill = "transparent"))
ggsave("General_Processing/figures/scan_strategy_full.png", 
       width = 6, height = 7.5, dpi = 300, bg = "transparent")
