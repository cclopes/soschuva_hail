#-------------------------------------------------------------------------------
#-- Reading, processing and generating plots of the hailpad network measurements
#-------------------------------------------------------------------------------

# Loading necessary packages ---------------------------------------------------
require(readr)
require(tidyverse)
require(reshape2)

# Defining language of the plots -----------------------------------------------
pt_br <- F

# Defining if plots will be from all cases or only two -------------------------
less_cases <- T

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
  unite(measured_by, "#", col = "measured_by", sep = " ")
if(pt_br){
  hailpads <- mutate(hailpads, 
                     case = paste("Caso de", str_extract(plate_full, "\\d\\d\\d\\d-\\d\\d-\\d\\d"), sep = "\n"))
} else{
  hailpads <- mutate(hailpads,
                     case = paste("Case", str_extract(plate_full, "\\d\\d\\d\\d-\\d\\d-\\d\\d"), sep = "\n"))
}
if(less_cases){
  hailpads <- filter(hailpads, 
                     plate_full == "2017-03-14\nC001" | 
                       plate_full == "2017-03-14\nR002" | 
                       plate_full == "2017-11-15\nR004") %>% 
    mutate(case = ifelse(case == "Case\n2017-03-14", "Case 1\n2017-03-14", "Case 2\n2017-11-15"))
}

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
  summarise(TORRO = mean(typical), TORRO_sd = sd(typical),
            ANELFA = mean(maximum), ANELFA_sd = sd(maximum))

# - Kinetic energy [J/m²] of each plate ----------------------------------------
tmp2 <- hailpads_diams %>%
  group_by(plate_full) %>%
  mutate(
    encin = 4.58e-6 * sum(n * diam_plate^4),
    encin_sd = sqrt(sum(4.58e-6 * n * 4 * diam_plate^3 * sd_plate, na.rm = T))
  ) %>%
  ungroup() %>%
  distinct(encin, encin_sd)

hailpads_perplate <- bind_cols(tmp, tmp2) %>% 
  gather(scale, diams, -plate_full, -TORRO_sd, -ANELFA_sd, -encin, -encin_sd) %>% 
  mutate(sd = ifelse(scale == "TORRO", TORRO_sd, ANELFA_sd)) %>% 
  select(-c(TORRO_sd, ANELFA_sd))
rm(tmp, tmp2)

# Plotting data ----------------------------------------------------------------

# - Defining centered titles and theme -----------------------------------------
theme_set(theme_bw())
theme_update(plot.title = element_text(hjust = 0.5))

# - Plot 1: Boxplots of all plates and measurements ----------------------------
if(less_cases){
  hailpads$plate[hailpads$plate == "C001"] <- "Cosmópolis\n1827 UTC"
  hailpads$plate[hailpads$plate == "R002"] <- "Indaiatuba\n1957 UTC"
  hailpads$plate[hailpads$plate == "R004"] <- "Indaiatuba\n2150 UTC"
}
plt <- ggplot(data = hailpads, aes(x = plate, y = value, color = measured_by)) +
  geom_violin(position = position_dodge(width = 1), fill = NA, size = 0.3) +
  geom_boxplot(width = 0.25, position = position_dodge(width = 1),
               size = 0.3, outlier.size = 0.5) +
  scale_fill_brewer(name = NA, palette = "Set1") +
  theme(
    legend.position = "bottom",
    plot.background = element_rect(fill = "transparent", color = "transparent"),
    legend.background = element_rect(fill = "transparent")
  ) +
  facet_grid(. ~ case, scales = "free_x", space = "free")
if(pt_br){
  plt <- plt +
    labs(x = "Hailpad", y = "Diâmetro (mm)") +
    scale_color_brewer(name = "Medido por", palette = "Set1")
  fig_name <- "Hailpads_Processing/figures/measures_distribution_ptbr.png"
} else{
  plt <- plt +
    labs(x = "Hailpad", y = "Diameter (mm)") +
    scale_color_brewer(name = "Measured by", palette = "Set1")
  fig_name <- "Hailpads_Processing/figures/measures_distribution.png"
}
if(less_cases){
  # -- Saving
  ggsave("Hailpads_Processing/figures/measures_distribution_less.png",
         width = 4.5, height = 4, bg = "transparent")
} else{
  # -- Changing facets widths
  g <- ggplotGrob(plt)
  g$widths[[5]] <- unit(1.2, "null")
  g$widths[[7]] <- unit(3.2, "null")
  g$widths[[9]] <- unit(1.7, "null")
  g$widths[[11]] <- unit(0.9, "null")
  g$widths[[13]] <- unit(1, "null")
  grid::grid.draw(g)
  # -- Saving
  ggsave(fig_name, g, width = 7.5, height = 3.5,  bg = "transparent")
}

# - Plot 2: Diameter vs Kinetic Energy (ANELFA and TORRO) ----------------------
hv_lines <- tibble(scale = c("TORRO", "ANELFA", "TORRO", "ANELFA", "TORRO", "ANELFA"),
                   h = c(20, 30, 100, 100, NA, NA), 
                   v = c(5, 10, 10, 20, NA, NA),
                   l = c("H0", "A0", "H1", "A1", "H2", "A2"),
                   lx = c(4.5, 9, 7.5, 15, 10.5, 22),
                   ly = c(10, 15, 60, 65, 125, 125))

plt <- ggplot(data = hailpads_perplate, aes(x = diams, y = encin, color = plate_full)) +
  geom_point() +
  geom_errorbar(aes(ymin = encin - encin_sd, ymax = encin + encin_sd),
                size = 0.5, width = 0.2) +
  geom_errorbarh(aes(xmin = diams - sd, xmax = diams + sd),
                 size = 0.5, height = 4) +
  geom_hline(aes(yintercept = h), hv_lines, color = "darkgray") +
  geom_vline(aes(xintercept = v), hv_lines, color = "darkgray") +
  geom_text(aes(label = l, x = lx, y = ly), hv_lines, inherit.aes = F) +
  theme(
    legend.position = "bottom",
    plot.background = element_rect(fill = "transparent", color = "transparent"),
    legend.background = element_rect(fill = "transparent")
  ) +
  guides(color = guide_legend(title.position = "top", title.hjust = 0.5, nrow = 1, byrow = T)) +
  facet_grid(. ~ scale, scales = "free_x")
if(pt_br){
  plt +
    labs(x = "Diâmetro (mm)", y = expression("Energia Cinética (J"*m^-2*")"), color = "Hailpad")
  ggsave("Hailpads_Processing/figures/data_anelfa_torro_ptbr.png", 
         width = 7.5, height = 3.5, bg = "transparent")
} else{
  plt +
    labs(x = "Diameter (mm)", y = expression("Kinetic Energy (J"*m^-2*")"), color = "Hailpad")
  ggsave("Hailpads_Processing/figures/data_anelfa_torro.png",
         width = 7.5, height = 3.5, bg = "transparent")
}

