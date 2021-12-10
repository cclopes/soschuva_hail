#-------------------------------------------------------------------------------
# LOADING AND PLOTTING TOPOGRAPHIC MAP
#-------------------------------------------------------------------------------

# Loading required packages ----------------------------------------------------

require(elevatr)
require(tidyverse)
require(tabularaster)
require(sf)
require(colorspace)
require(ggspatial)
require(ggnewscale)


# Function definition ----------------------------------------------------------

# Create circle df of a given radius Km
dfCircle <- function(LonDec, LatDec, Km) {

  # - LatDec = latitude in decimal degrees of the center of the circle
  # - LonDec = longitude in decimal degrees
  # - Km = radius of the circle in kilometers

  # Mean Earth radius in kilometers
  # - Change this to 3959 and you will have your function working in miles
  ER <- 6371
  # Angles in degrees
  AngDeg <- seq(1:360)
  # Latitude of the center of the circle in radians
  Lat1Rad <- LatDec * (pi / 180)
  # Longitude of the center of the circle in radians
  Lon1Rad <- LonDec * (pi / 180)
  # Angles in radians
  AngRad <- AngDeg * (pi / 180)
  # Latitude of each point of the circle regarding to angle in radians
  Lat2Rad <- asin(sin(Lat1Rad) * cos(Km / ER) +
    cos(Lat1Rad) * sin(Km / ER) * cos(AngRad))
  # Longitude of each point of the circle regarding to angle in radians
  Lon2Rad <- Lon1Rad + atan2(
    sin(AngRad) * sin(Km / ER) * cos(Lat1Rad),
    cos(Km / ER) - sin(Lat1Rad) * sin(Lat2Rad)
  )
  # Latitude of each point of the circle regarding to angle in radians
  Lat2Deg <- Lat2Rad * (180 / pi)
  # Longitude of each point of the circle regarding to angle in degrees
  # - Conversion of radians to degrees deg = rad*(180/pi)
  Lon2Deg <- Lon2Rad * (180 / pi)
  
  return(data.frame(lon = Lon2Deg, lat = Lat2Deg))
}


# Getting data -----------------------------------------------------------------

# Elevations
# Data frame with coordinates
coords <- data.frame(
  lon = seq(-50, -40, 0.1),
  lat = seq(-28, -18, 0.1)
)
# Projection
prj_dd <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
# Downloading data
elevs <- get_elev_raster(coords, prj = prj_dd, z = 5)
# Converting to tibble
elevs_df <- tabularaster::as_tibble(elevs, cell = F, xy = T) %>%
  drop_na() %>%
  filter(x >= -50 & x <= -40, y >= -28 & y <= -18) %>%
  mutate(cellvalue = ifelse(cellvalue < 0, NA, cellvalue))
rm(elevs)

# Radars, hailpads position
radars <- st_read("Data/GENERAL/radars_pos.kml", stringsAsFactors = F)
radars <- cbind(radars$Name, st_coordinates(radars)[, -3]) %>%
  data.frame() %>%
  mutate(X = as.numeric(as.character(X)), Y = as.numeric(as.character(Y)))
radars_circles <- rbind(
  radars %>%
    filter(V1 != "XPOL") %>%
    group_by(V1) %>% nest() %>%
    mutate(
      circle_250 = map(data, ~ dfCircle(.x$X, .x$Y, 250)),
      circle_100 = map(data, ~ dfCircle(.x$X, .x$Y, 100)),
      circle_80 = map(data, ~ dfCircle(factor(.x$X), factor(.x$Y), 80)),
      circle_60 = map(data, ~ dfCircle(factor(.x$X), factor(.x$Y), 60))
    ) %>%
    unnest(
      cols = c(data, circle_250, circle_100, circle_80, circle_60),
      names_sep = "_"
    ) %>%
    ungroup(),
  radars %>%
    filter(V1 == "XPOL") %>%
    group_by(V1) %>% nest() %>%
    mutate(
      circle_250 = map(data, ~ dfCircle(factor(.x$X), factor(.x$Y), 250)),
      circle_100 = map(data, ~ dfCircle(factor(.x$X), factor(.x$Y), 100)),
      circle_80 = map(data, ~ dfCircle(.x$X, .x$Y, 80)),
      circle_60 = map(data, ~ dfCircle(.x$X, .x$Y, 60))
    ) %>%
    unnest(
      cols = c(data, circle_250, circle_100, circle_80, circle_60),
      names_sep = "_"
    ) %>%
    ungroup()
) %>%
  rename(radar = V1, lon = data_X, lat = data_Y)
hailpads <- st_read("Data/GENERAL/hailpads_pos.kml", stringsAsFactors = F)
hailpads <- cbind(hailpads$Name, st_coordinates(hailpads)[, -3]) %>%
  data.frame() %>%
  mutate(
    X = as.numeric(as.character(X)), Y = as.numeric(as.character(Y)),
    collected = "Installed"
  ) %>%
  rename(location = V1, lon = X, lat = Y)
hailpads$collected[c(12, 16)] <- "Sellected"

# Shapefiles
sao_paulo <- st_read("Data/GENERAL/shapefiles/sao_paulo.shp",
  stringsAsFactors = F
)
cities <- sao_paulo %>%
  filter(NOMEMUNICP %in% c(
    "AMERICANA",
    "ARTUR NOGUEIRA",
    "ENGENHEIRO COELHO",
    "HOLAMBRA",
    "HORTOLÂNDIA",
    "ITATIBA",
    "JAGUARIUNA",
    "MONTE MOR",
    "MORUNGABA",
    "NOVA ODESSA",
    "PAULINIA",
    "PEDREIRA",
    "SANTA BARBARA D'OESTE",
    "SANTO ANTONIO DE POSSE",
    "SUMARE",
    "VALINHOS",
    "VINHEDO"
  ))
cities_highlight <- sao_paulo %>%
  filter(NOMEMUNICP %in% c("CAMPINAS", "COSMOPOLIS", "INDAIATUBA"))
states <- st_read("Data/GENERAL/shapefiles/estadosl_2007.shp",
  stringsAsFactors = F
)
st_crs(states) <- 4326


# Plotting ---------------------------------------------------------------------

# Plot settings
theme_set(theme_bw())
theme_update(plot.title = element_text(hjust = 0.5))

# Radar ranges
ggplot() +
  # Elevation
  geom_tile(data = elevs_df, aes(x, y, fill = cellvalue)) +
  # Shapefiles
  geom_sf(data = states, fill = NA, size = 0.25) +
  geom_sf(data = cities, fill = NA, size = 0.25) +
  geom_sf(data = cities_highlight, fill = NA, size = 0.5, colour = "gray20") +
  # Radar ranges
  geom_path(
    data = radars_circles, size = 1,
    aes(circle_250_lon, circle_250_lat, color = radar, linetype = "250")
  ) +
  geom_path(
    data = radars_circles, size = 1,
    aes(circle_100_lon, circle_100_lat, color = radar, linetype = "100")
  ) +
  geom_path(
    data = radars_circles, size = 1,
    aes(circle_80_lon, circle_80_lat, color = radar, linetype = "80")
  ) +
  geom_path(
    data = radars_circles, size = 1,
    aes(circle_60_lon, circle_60_lat, color = radar, linetype = "60")
  ) +
  geom_point(
    data = radars_circles, aes(lon, lat, color = radar),
    shape = 17, size = 2
  ) +
  # Scale
  annotation_scale(location = "bl", width_hint = 0.4) +
  # Limits
  coord_sf(xlim = c(-50, -43), ylim = c(-26.3, -21), expand = F) +
  # Color scale of elevation
  scale_fill_continuous_sequential(
    name = "Elevation (m)",
    palette = "terrain2", rev = F,
    na.value = "mediumaquamarine"
  ) +
  # Color scale of radars
  scale_color_manual(
    name = "Radar",
    values = c("#e41a1c", "#3D3308", "#352C51")
  ) +
  # Labels of contours
  scale_linetype_manual(
    name = "Radius (km)",
    breaks = c("250", "100", "80", "60"),
    values = c(41, 11, "solid", 3111)
  ) +
  # Theme settings
  guides(
    fill = guide_legend(reverse = T, order = 1),
    color = guide_legend(order = 2),
    size = guide_legend(order = 3)
  ) +
  theme(
    axis.title = element_blank(),
    legend.spacing.y = unit(0.075, "cm"),
    panel.background = element_rect(fill = NA),
    panel.grid = element_line(
      linetype = "dotted", color = gray(0.5, alpha = 0.2)
    ),
    panel.ontop = TRUE,
    plot.background = element_rect(
      fill = "transparent",
      color = "transparent"
    ),
    legend.background = element_rect(fill = "transparent")
  )
# Saving
ggsave("General_Processing/figures/radar_coverages.png",
  width = 6, height = 4, dpi = 300, bg = "transparent"
)

# Hailpad positions
ggplot() +
  geom_tile(data = elevs_df, aes(x, y, fill = cellvalue)) +
  geom_sf(data = states, fill = NA, size = 0.25) +
  geom_sf(data = cities, fill = NA, size = 0.25) +
  geom_sf(data = cities_highlight, fill = NA, size = 0.5, colour = "gray20") +
  geom_point(
    data = radars_circles %>% filter(radar == "XPOL"),
    aes(lon, lat, color = radar),
    shape = 17, size = 2
  ) +
  geom_path(
    data = radars_circles %>% filter(radar == "XPOL"),
    aes(circle_80_lon, circle_80_lat, color = radar, size = "80")
  ) +
  scale_color_manual(
    name = "Radar",
    values = c("#352C51", "#352C51", "#352C51"),
    guide = guide_legend(order = 3)
  ) +
  new_scale_color() +
  geom_point(
    data = hailpads, aes(lon, lat, color = collected),
    shape = 4, size = 2, stroke = 1, inherit.aes = F
  ) +
  scale_color_manual(
    name = "Hailpads",
    values = c("#991861", "#2A071B"),
    guide = guide_legend(order = 2)
  ) +
  annotation_scale(location = "bl", width_hint = 0.4) +
  # annotation_north_arrow(location = "bl", which_north = "true",
  #                        pad_x = unit(0.2, "in"), pad_y = unit(0.2, "in"),
  #                        style = north_arrow_fancy_orienteering) +
  coord_sf(xlim = c(-48, -46.1), ylim = c(-23.6, -22), expand = F) +
  scale_fill_continuous_sequential(
    name = "Elevation (m)",
    palette = "terrain2", rev = F,
    na.value = "mediumaquamarine"
  ) +
  scale_size_manual(
    name = "Radius (km)",
    breaks = c("250", "100", "80", "60"),
    values = c(2, 1, 1.5, 0.5)
  ) +
  guides(
    fill = guide_legend(reverse = T, order = 1),
    size = guide_legend(order = 4)
  ) +
  theme(
    axis.title = element_blank(),
    legend.spacing.y = unit(0.075, "cm"),
    panel.background = element_rect(fill = NA),
    panel.grid = element_line(
      linetype = "dotted", color = gray(0.5, alpha = 0.2)
    ),
    panel.ontop = TRUE,
    plot.background = element_rect(
      fill = "transparent",
      color = "transparent"
    ),
    legend.background = element_rect(fill = "transparent")
  )
ggsave("General_Processing/figures/hailpad_network.png",
  width = 6, height = 4, dpi = 300, bg = "transparent"
)
