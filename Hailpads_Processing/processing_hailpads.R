#-------------------------------------------------------------------------------
#-- Reading, processing and generating plots of the hailpad network measurements
#-------------------------------------------------------------------------------

# Loading necessary packages ---------------------------------------------------
require(readr)
require(tidyverse)
require(reshape2)

# Reading and pre-processing data ----------------------------------------------
hailpads <- read.csv2(file = "Data/HAILPADS/Medidas_Hailpads.csv", dec = ",") %>%
  .[colSums(!is.na(.)) > 0] %>%
  melt(.) %>%
  separate(variable, into = c("plate", "measured_by", "#"), sep = "_") %>%
  mutate(plate = toupper(plate), measured_by = str_to_upper(measured_by)) %>%
  na.omit() %>%
  mutate(value = ifelse(measured_by == "IAG", (value + 3.7207) / 1.0349, value)) %>%
  mutate(plate_full = plate) %>% 
  mutate(plate_full = ifelse(plate == "C001", paste("2017-03-14", plate, sep = "\n"), plate_full)) %>%
  mutate(plate_full = ifelse(plate == "C002", paste("2016-12-25", plate, sep = "\n"), plate_full)) %>%
  mutate(plate_full = ifelse(plate == "C003", paste("2017-01-31", plate, sep = "\n"), plate_full)) %>%
  mutate(plate_full = ifelse(plate == "C004", paste("2017-01-31", plate, sep = "\n"), plate_full)) %>%
  mutate(plate_full = ifelse(plate == "R002", paste("2017-03-14", plate, sep = "\n"), plate_full)) %>%
  mutate(plate_full = ifelse(plate == "R004", paste("2017-11-15", plate, sep = "\n"), plate_full)) %>%
  mutate(plate_full = ifelse(plate == "R038", paste("2017-11-16", plate, sep = "\n"), plate_full)) %>%
  mutate(case = paste("Case", str_extract(plate_full, "\\d\\d\\d\\d-\\d\\d-\\d\\d"), sep = "\n")) %>% 
  unite(measured_by, "#", col = "measured_by", sep = " ") # %>%
  # filter(plate == "2017-03-14\nC001" | plate == "2017-03-14\nR002" | 
  #        plate == "2017-11-15\nR004") #-- For less cases

# - Mean diameters [mm] by 1 mm bins and amount of points [1/m²] ---------------
hailpads_diams <- hailpads %>%
  mutate(bin = value - value %% 1) %>%
  group_by(plate_full, measured_by, bin) %>%
  summarise(diam_bin = mean(value), sd_bin = sd(value), qte = n()) %>%
  ungroup() %>%
  group_by(plate_full, bin) %>%
  summarise(diam_plate = mean(diam_bin), sd_plate = sqrt(sum(sd_bin^2, na.rm = T)),
            n = mean(qte) / (0.399 * 0.298)) %>%
  ungroup()

# - Typical (median) and maximum diameters of each plate -----------------------
tmp <- hailpads %>%
  group_by(measured_by, plate_full) %>%
  mutate(typical = median(value), maximum = max(value)) %>%
  ungroup() %>%
  group_by(plate_full) %>%
  summarise(diam_typical = mean(typical), sd_typical = sd(typical),
            diam_max = mean(maximum), sd_max = sd(maximum))

# - Kinetic energy [J/m²] of each plate ----------------------------------------
tmp2 <- hailpads_diams %>%
  group_by(plate_full) %>%
  mutate(
    encin = 4.58e-6 * sum(n * diam_plate^4),
    sd_encin = sqrt(sum(4.58e-6 * n * 4 * diam_plate^3 * sd_plate, na.rm = T))
  ) %>%
  ungroup() %>%
  distinct(encin, sd_encin)

hailpads_perplate <- bind_cols(tmp, tmp2)
rm(tmp, tmp2)

# Plotting data ----------------------------------------------------------------

# - Defining centered titles and theme -----------------------------------------
theme_set(theme_bw())
theme_update(plot.title = element_text(hjust = 0.5))

# - Plot 1: Boxplots of all plates and measurements ----------------------------
plt <- ggplot(data = hailpads, aes(x = plate, y = value, color = measured_by)) +
  geom_violin(position = position_dodge(width = 1), fill = NA, size = 0.3) +
  geom_boxplot(width = 0.25, position = position_dodge(width = 1),
               size = 0.3, outlier.size = 0.5) +
  labs(x = "Hailpad", y = "Diameter [mm]") +
  scale_color_brewer(name = "Measured by", palette = "Set1") +
  scale_fill_brewer(name = NA, palette = "Set1") +
  theme(
    legend.position = "bottom",
    plot.background = element_rect(fill = "transparent"),
    legend.background = element_rect(fill = "transparent")
  ) +
  facet_grid(. ~ case, scales = "free_x", space = "free")
# -- Changing facets widths
g <- ggplotGrob(plt)
g$widths[[5]] <- unit(1.2, "null")
g$widths[[7]] <- unit(3.2, "null")
g$widths[[9]] <- unit(1.7, "null")
g$widths[[11]] <- unit(0.9, "null")
g$widths[[13]] <- unit(1, "null")
grid.draw(g)
# -- Saving
ggsave("Hailpads_Processing/figures/measures_distribution.png", g,
       width = 7.5, height = 3.5,  bg = "transparent")
# ggsave("Hailpads_Processing/figures/measures_distribution_less.png",
#        width = 4.5, height = 4, bg = "transparent") #-- For less cases

# - Plot 2: Diameter vs Kinetic Energy (TORRO) ---------------------------------
ggplot(data = hailpads_perplate, aes(x = diam_typical, y = encin)) +
  coord_cartesian(x = c(4, 11)) + # scale_y_log10() +
  geom_hline(yintercept = c(20, 100), color = "darkgray") +
  geom_vline(xintercept = c(5, 10), color = "darkgray") +
  annotate("text", label = c("H0", "H1", "H2"), x = c(4, 7.5, 11), y = c(10, 60, 125)) +
  geom_point(aes(color = plate_full)) +
  geom_errorbar(aes(ymin = encin - sd_encin, ymax = encin + sd_encin, color = plate_full), 
                size = 0.5, width = 0.1) +
  geom_errorbarh(aes(xmin = diam_typical - sd_typical, xmax = diam_typical + sd_typical, 
                     color = plate_full), size = 0.5, height = 5) +
  labs(title = "Hailstorm Intensity - TORRO Scale", x = "Typical Diameter [mm]",
       y = "Kinetic Energy [J/m²]", color = "Hailpad") +
  guides(color = guide_legend(nrow = 2, byrow = T)) + #-- Without this for less cases
  theme(
    legend.position = "bottom",
    plot.background = element_rect(fill = "transparent"),
    legend.background = element_rect(fill = "transparent")
  ) +
  labs(title = "Hailstorm Intensity - TORRO Scale", x = "Typical Diameter [mm]", 
       y = "Kinetic Energy [J/m²]", color = "Hailpad")
ggsave("Hailpads_Processing/figures/data_torro.png", width = 5, height = 4,  
       bg = "transparent")
# ggsave("Hailpads_Processing/figures/data_torro_less.png", 
#        width = 4.5, height = 4, bg = "transparent") #-- For less cases

# - Plot 3: Diameter vs Kinetic Energy (ANELFA) --------------------------------
ggplot(data = hailpads_perplate, aes(x = diam_max, y = encin)) +
  coord_cartesian(xlim = c(9, 23)) + # scale_y_log10() +
  geom_hline(yintercept = c(30, 100), color = "darkgray") +
  geom_vline(xintercept = c(10, 20), color = "darkgray") +
  annotate("text", label = c("A0", "A1", "A2"), x = c(9, 15, 22), y = c(15, 65, 125)) +
  geom_point(aes(color = plate_full)) +
  geom_errorbar(aes(ymin = encin - sd_encin, ymax = encin + sd_encin, color = plate_full), 
                size = 0.5, width = 0.2) +
  geom_errorbarh(aes(xmin = diam_max - sd_max, xmax = diam_max + sd_max, color = plate_full),
                 size = 0.5, height = 4) +
  guides(color = guide_legend(nrow = 2, byrow = T)) + #-- Without this for less cases
  theme(
    legend.position = "bottom",
    plot.background = element_rect(fill = "transparent"),
    legend.background = element_rect(fill = "transparent")
  ) +
  labs(title = "Hailstorm Intensity - ANELFA Scale", x = "Maximum Diameter [mm]", 
       y = "Kinetic Energy [J/m²]", color = "Hailpad")
ggsave("Hailpads_Processing/figures/data_anelfa.png", width = 5, height = 4,  
       bg = "transparent")
# ggsave("Hailpads_Processing/figures/data_anelfa_less.png", 
#        width = 4.5, height = 4, bg = "transparent") #-- For less cases
