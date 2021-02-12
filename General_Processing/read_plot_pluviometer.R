#-------------------------------------------------------------------------------
#-- Reading, plotting CEMADEN pluviometer data
#-------------------------------------------------------------------------------

# Loading necessary packages
require(tidyverse)
require(sf)
require(lubridate)
require(ggalt)
require(colorspace)

# Loading tracking vars and selecting only hailpad data
load("General_Processing/lifecycle_data.RData")
rm(list = setdiff(ls(), "data_hailpads"))
data_hailpads$case <- c(
  "Case 1 2017-03-14\n1800 to 2100 UTC",
  "Case 1 2017-03-14\n1800 to 2100 UTC",
  "Case 2 2017-11-15\n2100 to 2300 UTC"
)

# Defining Metropolitan Region of Campinas
mrc <- c(
  "AMERICANA", "ARTUR NOGUEIRA", "CAMPINAS", "ENGENHEIRO COELHO", "HOLAMBRA",
  "HORTOLÂNDIA", "ITATIBA", "JAGUARIUNA", "JAGUARIÚNA", "MONTE MOR", "MORUNGABA",
  "NOVA ODESSA", "PAULINIA", "PAULÍNIA", "PEDREIRA", "SANTA BARBARA D'OESTE",
  "SANTA BÁRBARA D'OESTE", "SANTO ANTONIO DE POSSE", "SANTO ANTÔNIO DE POSSE",
  "SUMARE", "SUMARÉ", "VALINHOS", "VINHEDO", "COSMOPOLIS", "COSMÓPOLIS", "INDAIATUBA"
)

# Reading files
pluvi <- bind_rows(
  read_delim("Data/PLUVIOMETER/cemaden_sp_2017_03.csv",
    ";",
    escape_double = FALSE, locale = locale(decimal_mark = ","),
    trim_ws = TRUE
  ),
  read_delim("Data/PLUVIOMETER/cemaden_sp_2017_11.csv",
    ";",
    escape_double = FALSE, locale = locale(decimal_mark = ","),
    trim_ws = TRUE
  )
) %>%
  mutate(datahora = ymd_hms(datahora)) %>%
  filter(
    date(datahora) %in% date(c("2017-03-14", "2017-11-15")),
    municipio %in% mrc
  )

pluvi_cases <- bind_rows(
  pluvi %>%
    filter(datahora >= ymd_hms("2017-03-14 18:00:00 UTC") &
      datahora <= ymd_hms("2017-03-14 21:00:00 UTC")) %>%
    group_by(municipio) %>%
    summarise(
      total_ppt = sum(valorMedida, na.rm = T),
      case = "Case 1 2017-03-14\n1800 to 2100 UTC",
      latitude = latitude, longitude = longitude
    ),
  pluvi %>%
    filter(datahora >= ymd_hms("2017-11-15 21:00:00 UTC") &
      datahora <= ymd_hms("2017-11-15 23:00:00 UTC")) %>%
    group_by(municipio) %>%
    summarise(
      total_ppt = sum(valorMedida, na.rm = T),
      case = "Case 2 2017-11-15\n2100 to 2300 UTC",
      latitude = latitude, longitude = longitude
    )
)

# Reading shapefiles
sao_paulo <- st_read("Data/GENERAL/shapefiles/sao_paulo.shp", stringsAsFactors = F)
cities <- sao_paulo[sao_paulo$NOMEMUNICP %in% mrc, ]
cities_highlight <- sao_paulo[sao_paulo$NOMEMUNICP %in% c("COSMOPOLIS", "INDAIATUBA"), ]

# Plotting
lims_in_plot <- data.frame("lon" = c(-47.6, -46.6), "lat" = c(-23.3, -22.4))
theme_set(theme_bw())

ggplot() +
  scale_x_continuous(limits = lims_in_plot$lon) +
  scale_y_continuous(limits = lims_in_plot$lat) +
  geom_sf(data = cities, fill = NA, size = 0.25) +
  geom_sf(data = cities_highlight, fill = NA, size = 0.75, colour = "gray20") +
  geom_point(data = data_hailpads, aes(x = lon, y = lat), pch = 17, size = 3) +
  geom_point(
    data = pluvi_cases,
    aes(x = latitude, y = longitude, fill = total_ppt),
    color = "black", size = 5, shape = 21
  ) +
  labs(
    x = expression("Longitude (" * degree * ")"),
    y = expression("Latitude (" * degree * ")"),
    fill = "Total Precipitation (mm)"
  ) +
  scale_fill_binned_sequential(palette = "Blue-Yellow", breaks = seq(0, 200, 25)) +
  guides(fill = guide_colorbar(title.position = "top", title.hjust = 0.5, barwidth = 15)) +
  theme(
    plot.background = element_rect(fill = "transparent", color = "transparent"),
    legend.background = element_rect(fill = "transparent", color = "transparent"),
    legend.position = "bottom"
  ) +
  facet_grid(. ~ case)
ggsave("General_Processing/figures/ppt_cemaden_cases.png", width = 7.5, height = 5.5, bg = "transparent")
