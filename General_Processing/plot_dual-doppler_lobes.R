#-------------------------------------------------------------------------------
# DUAL-DOPPLER LOBES
# Based on "dual-doppler-v2.R" by Rachel Albrecht
#-------------------------------------------------------------------------------

# Loading necessary packages ---------------------------------------------------
require(maptools)
require(maps)
# require(mapdata)  # worldHires database
# require(mapproj)  # mapproject function
require(geosphere)
require(tidyverse)
# require(ggrepel)
# require(sp)
# require(rgdal)
require(sf)


# Defining necessary functions -------------------------------------------------
dfElipse <- function(x, y, r) {
  angles <- seq(0, 2 * pi, length.out = 360)
  return(df(x = r * cos(angles) + x, y = r * sin(angles) + y))
}

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
  Lat1Rad <- LatDec * (pi/180)
  # Longitude of the center of the circle in radians
  Lon1Rad <- LonDec * (pi/180)
  # Angles in radians
  AngRad <- AngDeg * (pi/180)
  # Latitude of each point of the circle rearding to angle in radians
  Lat2Rad <-asin(sin(Lat1Rad) * cos(Km/ER) +
                   cos(Lat1Rad) * sin(Km/ER) * cos(AngRad))
  # Longitude of each point of the circle rearding to angle in radians
  Lon2Rad <- Lon1Rad + atan2(sin(AngRad) * sin(Km/ER) * cos(Lat1Rad),
                             cos(Km/ER) - sin(Lat1Rad) * sin(Lat2Rad))
  # Latitude of each point of the circle rearding to angle in radians
  Lat2Deg <- Lat2Rad * (180/pi)
  # Longitude of each point of the circle rearding to angle in degrees
  # - Conversion of radians to degrees deg = rad*(180/pi)
  Lon2Deg <- Lon2Rad * (180/pi)
  return(data.frame(lon = Lon2Deg, lat = Lat2Deg))
}

# Testing
# map("worldHires", region="belgium")  # Draw a map of Belgium
# bruxelles <- mapproject(4.330, 50.830)  # Coordinates of Bruxelles
# points(bruxelles, pch=20, col='blue', cex=2)  # Draw a blue dot for Bruxelles
# plotCircle(4.330, 50.830, 50)  # Plot a dashed circle of 50 km arround Bruxelles
# plotElipse(4.330, 50.830, 0.5)  # Tries to plot a plain circle of 50 km arround Bruxelles, but drawn an ellipse

DualDopplerLobes <- function(radar1, radar2, deg, bearing1, bearing2){
  middle <- midPoint(radar1, radar2)
  deg <- deg*pi/180
  d <- distm(radar1, radar2, fun = distHaversine)/2
  r <- d/sin(deg)
  x <- sqrt(r^2 - d^2)
  p1 <- destPoint(middle, bearing1, x)
  p2 <- destPoint(middle, bearing2, x)
  out <- NULL
  out$x1 <- radar1[1]; out$y1 <- radar1[2]
  out$x2 <- radar2[1]; out$y2 <- radar2[2]
  out$d <- d; out$r<- r
  out$mid.x <- middle[1]; out$mid.y <- middle[2]
  out$p1.x <- p1[1]; out$p1.y <- p1[2]
  out$p2.x <- p2[1]; out$p2.y <- p2[2]
  return(out)
}

# Running for SOS-CHUVA settings -----------------------------------------------

# - Reading city boundaries shapefile ------------------------------------------

# st_layers("Data/GENERAL/shapefiles/statesl_2007.shp")
sao_paulo <- st_read("Data/GENERAL/shapefiles/sao_paulo.shp",
                     stringsAsFactors = F)
cities <- sao_paulo[
  sao_paulo$NOMEMUNICP %in% c(
    "AMERICANA", "ARTUR NOGUEIRA", "CAMPINAS", "ENGENHEIRO COELHO", "HOLAMBRA", 
    "HORTOLÂNDIA", "ITATIBA", "JAGUARIUNA", "MONTE MOR", "MORUNGABA", 
    "NOVA ODESSA", "PAULINIA", "PEDREIRA", "SANTA BARBARA D'OESTE", 
    "SANTO ANTONIO DE POSSE", "SUMARE", "VALINHOS", "VINHEDO"
  ),
  ]
cities_highlight <- sao_paulo[
  sao_paulo$NOMEMUNICP %in% c("COSMOPOLIS", "INDAIATUBA"),
  ]

states <- st_read("Data/GENERAL/shapefiles/estadosl_2007.shp",
                  stringsAsFactors = F)
st_crs(states) <- 4326

# - Radar coordinates
sr <- data.frame(x = -(47 + (5+52/60)/60), y = -(23 + (35+56/60)/60))
fcth <- data.frame(x = -(45 + (58+20/60)/60), y = -(23 + (36+0/60)/60))
xpol <- data.frame(x = -47.05641, y = -22.81405)
# radars_dist <- data.frame(
#   combination = c("SR/FCTH", "SR/XPOL", "FCTH/XPOL"),
#   distance = c(distm(sr, fcth, fun = distHaversine) * 1e-3,
#                distm(sr, xpol, fun = distHaversine) * 1e-3,
#                distm(fcth, xpol, fun = distHaversine) * 1e-3),
#   midlon = c(midPoint(sr, fcth)[1], midPoint(sr, xpol)[1], midPoint(fcth, xpol)[1]),
#   midlat = c(midPoint(sr, fcth)[2], midPoint(sr, xpol)[2], midPoint(fcth, xpol)[2])
# ) %>% 
#   mutate(distance = sprintf("%3.0f km", distance))
radars_dist <- data.frame(
  combination = c("SR/FCTH", "SR/FCTH/XPOL", "SR/FCTH/XPOL", "SR/FCTH/XPOL"),
  distance = c(distm(sr, fcth, fun = distHaversine) * 1e-3,
               distm(sr, fcth, fun = distHaversine) * 1e-3,
               distm(sr, xpol, fun = distHaversine) * 1e-3,
               distm(fcth, xpol, fun = distHaversine) * 1e-3),
  midlon = c(midPoint(sr, fcth)[1], midPoint(sr, fcth)[1], midPoint(sr, xpol)[1], midPoint(fcth, xpol)[1]),
  midlat = c(midPoint(sr, fcth)[2], midPoint(sr, fcth)[2], midPoint(sr, xpol)[2], midPoint(fcth, xpol)[2])
) %>% 
  mutate(distance = sprintf("%3.0f km", distance))
# radars <- bind_rows(
#   list(
#     SR = bind_rows(sr, sr, sr) %>% mutate(combination = c("SR/FCTH", "SR/XPOL", "SR/FCTH/XPOL")), 
#     FCTH = bind_rows(fcth, fcth, fcth) %>% mutate(combination = c("SR/FCTH", "FCTH/XPOL", "SR/FCTH/XPOL")),
#     XPOL = bind_rows(xpol, xpol, xpol) %>% mutate(combination = c("SR/XPOL", "FCTH/XPOL", "SR/FCTH/XPOL"))
#     ),
#   .id = "radar")
radars <- bind_rows(
  list(
    SR = bind_rows(sr, sr) %>% mutate(combination = c("SR/FCTH", "SR/FCTH/XPOL")), 
    FCTH = bind_rows(fcth, fcth) %>% mutate(combination = c("SR/FCTH", "SR/FCTH/XPOL")),
    XPOL = bind_rows(xpol) %>% mutate(combination = c("SR/FCTH/XPOL"))
  ),
  .id = "radar")

xlim <- c(-48.75, -44.75); ylim <- c(-24.5, -22)

# - 30 degrees view
dd30 <- list(sr_fcth = DualDopplerLobes(sr, fcth, 30, 0, 180),
             sr_xpol = DualDopplerLobes(sr, xpol, 30, 93, 273),
             fcth_xpol = DualDopplerLobes(fcth, xpol, 30, 38.5, 218.5))
# - 45 degrees view
dd45 <- list(sr_fcth = DualDopplerLobes(sr, fcth, 45, 0, 180),
             sr_xpol = DualDopplerLobes(sr, xpol, 45, 93, 273),
             fcth_xpol = DualDopplerLobes(fcth, xpol, 45, 38.5, 218.5))

# - Dual-Doppler
circles_duald <- list(
  map(dd30, ~dfCircle(.x$p1.x, .x$p1.y, .x$r*1e-3) %>% mutate(group = "a", angle = "30")),
  map(dd30, ~dfCircle(.x$p2.x, .x$p2.y, .x$r*1e-3) %>% mutate(group = "b", angle = "30")),
  map(dd45, ~dfCircle(.x$p1.x, .x$p1.y, .x$r*1e-3) %>% mutate(group = "c", angle = "45")),
  map(dd45, ~dfCircle(.x$p2.x, .x$p2.y, .x$r*1e-3) %>% mutate(group = "d", angle = "45"))
  ) %>%
  flatten_dfr(.id = "combination") %>%
  mutate(combination = toupper(combination) %>% str_replace("_", "/")) %>% 
  filter(combination == "SR/FCTH")

# - Tripple Doppler
# -- Doing in two parts: within (in) the lobe, outside (out) the lobe

# -- Combo 1 (FCTH/XPOL)
circles_trippled_in <- bind_rows(
  dfCircle(dd30$fcth_xpol$p2.x, dd30$fcth_xpol$p2.y, dd30$fcth_xpol$r*1e-3) %>% mutate(group = "a1", angle = "30"),
  dfCircle(dd45$fcth_xpol$p2.x, dd45$fcth_xpol$p2.y, dd45$fcth_xpol$r*1e-3) %>% mutate(group = "a2", angle = "45"),
) %>%
  # Excluding points outside lobes (manual)
  mutate(lon_p1 = lon >= radars[radars$radar == "XPOL",]$x[1],
         lat_p1 = lat >= radars[radars$radar == "XPOL",]$y[1],
         lon_p2 = lon >= radars[radars$radar == "FCTH",]$x[1],
         lat_p2 = lat >= radars[radars$radar == "FCTH",]$y[1]) %>% 
  filter(lon_p1 & lat_p2)

circles_trippled_out <- bind_rows(
  dfCircle(dd30$fcth_xpol$p1.x, dd30$fcth_xpol$p1.y, dd30$fcth_xpol$r*1e-3) %>% mutate(group = "b1", angle = "30"),
  dfCircle(dd45$fcth_xpol$p1.x, dd45$fcth_xpol$p1.y, dd45$fcth_xpol$r*1e-3) %>% mutate(group = "b2", angle = "45"),
) %>%
  # Excluding points outside lobes (manual)
  mutate(lon_p = between(lon, radars[radars$radar == "XPOL",]$x[1], radars[radars$radar == "FCTH",]$x[1]),
         lat_p = between(lat, radars[radars$radar == "FCTH",]$y[1], radars[radars$radar == "XPOL",]$y[1]),
         lon_p2 = lon < radars[radars$radar == "FCTH",]$x[1],
         lat_p2 = lat <= radars[radars$radar == "FCTH",]$y[1]) %>% 
  filter(!(lat_p & lon_p)) %>% filter(!(lat_p2 & lon_p2))

circles_trippled_1 <- bind_rows(circles_trippled_in, circles_trippled_out)

# --- Testing
# ggplot(circles_trippled_1) +
#   geom_point(aes(x = lon, y = lat)) +
#   coord_cartesian(xlim = c(-47.5, -43.5), ylim = c(-24.5, -21))

# -- Combo 2 (SR/XPOL)
circles_trippled_in <- bind_rows(
  dfCircle(dd30$sr_xpol$p1.x, dd30$sr_xpol$p1.y, dd30$sr_xpol$r*1e-3) %>% mutate(group = "c1", angle = "30"),
  dfCircle(dd45$sr_xpol$p1.x, dd45$sr_xpol$p1.y, dd45$sr_xpol$r*1e-3) %>% mutate(group = "c2", angle = "45"),
) %>%
  # Excluding points outside lobes (manual)
  mutate(lon_p1 = lon <= radars[radars$radar == "XPOL",]$x[1],
         lat_p1 = lat <= radars[radars$radar == "XPOL",]$y[1],
         lon_p2 = lon <= radars[radars$radar == "SR",]$x[1],
         lat_p2 = lat <= radars[radars$radar == "SR",]$y[1]) %>% 
  filter(lon_p1 & lat_p1) %>% filter(lon_p1 & !lat_p2)

circles_trippled_out <- bind_rows(
  dfCircle(dd30$sr_xpol$p2.x, dd30$sr_xpol$p2.y, dd30$sr_xpol$r*1e-3) %>% mutate(group = "d1", angle = "30"),
  dfCircle(dd45$sr_xpol$p2.x, dd45$sr_xpol$p2.y, dd45$sr_xpol$r*1e-3) %>% mutate(group = "d2", angle = "45"),
) %>%
  # Excluding points outside lobes (manual)
  mutate(lon_p1 = lon <= radars[radars$radar == "XPOL",]$x[1],
         lat_p2 = lat >= radars[radars$radar == "SR",]$y[1],
         lon_p2 = lon >= radars[radars$radar == "SR",]$x[1]) %>% 
  filter(lon_p1) %>% filter(!(lon_p2 & lat_p2))

circles_trippled_2 <- bind_rows(circles_trippled_in, circles_trippled_out)

# --- Testing
# ggplot(circles_trippled_out) +
#   geom_point(aes(x = lon, y = lat)) +
#   coord_cartesian(xlim = c(-49, -45), ylim = c(-24.5, -22))

# -- Combo 3 (SR/FCTH)
circles_trippled_in <- bind_rows(
  dfCircle(dd30$sr_fcth$p1.x, dd30$sr_fcth$p1.y, dd30$sr_fcth$r*1e-3) %>% mutate(group = "e1", angle = "30"),
  dfCircle(dd45$sr_fcth$p1.x, dd45$sr_fcth$p1.y, dd45$sr_fcth$r*1e-3) %>% mutate(group = "e2", angle = "45"),
) %>%
  # Excluding points outside lobes (manual)
  mutate(lon_p1 = lon >= radars[radars$radar == "SR",]$x[1],
         lat_p1 = lat <= radars[radars$radar == "SR",]$y[1],
         lon_p2 = lon <= radars[radars$radar == "FCTH",]$x[1],
         lat_p2 = lat <= radars[radars$radar == "FCTH",]$y[1]) %>% 
  filter(lon_p1 & lon_p2 & lat_p1)

circles_trippled_out <- bind_rows(
  dfCircle(dd30$sr_fcth$p2.x, dd30$sr_fcth$p2.y, dd30$sr_fcth$r*1e-3) %>% mutate(group = "f1", angle = "30"),
  dfCircle(dd45$sr_fcth$p2.x, dd45$sr_fcth$p2.y, dd45$sr_fcth$r*1e-3) %>% mutate(group = "f2", angle = "45")
) %>%
  # Excluding points outside lobes (manual)
  mutate(lon_p = between(lon, radars[radars$radar == "SR",]$x[1], radars[radars$radar == "FCTH",]$x[1]),
         lat_p = between(lat, radars[radars$radar == "FCTH",]$y[1], radars[radars$radar == "SR",]$y[1]),
         lat_p2 = lat <= radars[radars$radar == "FCTH",]$y[1]) %>% 
  filter(lat_p2)

circles_trippled_3 <- bind_rows(circles_trippled_in, circles_trippled_out)

# --- Testing
# ggplot(circles_trippled) +
#   geom_point(aes(x = lon, y = lat)) +
#   coord_cartesian(xlim = c(-48, -45), ylim = c(-25.5, -21))

# -- Joining them
circles_trippled <- bind_rows(circles_trippled_1, circles_trippled_2, circles_trippled_3) %>% 
  mutate(combination = "SR/FCTH/XPOL") %>% 
  select(-c(lon_p, lat_p, lon_p1, lat_p1, lon_p2, lat_p2)) 

# - Joining dual and tripple doppler
circles <- bind_rows(circles_duald, circles_trippled) %>% 
  mutate(combination = factor(combination, levels = c("SR/FCTH","SR/FCTH/XPOL")))

# - Plotting
theme_set(theme_bw())

ggplot() +
  geom_sf(data = states, fill = NA, size = 0.25) +
  geom_sf(data = cities, fill = NA, size = 0.25) +
  geom_sf(data = cities_highlight, fill = NA, size = 0.5, colour = "gray20") +
  geom_point(data = circles, 
             aes(x = lon, y = lat, color = angle, group = group), size = 0.5) +
  geom_path(data = rbind(radars, radars[1:2,]), aes(x, y), linetype = "dashed") +
  geom_point(data = radars, aes(x, y, shape = radar), fill = "white", size = 2) +
  geom_label(data = radars_dist, aes(midlon, midlat, label = distance),
             size = 2, alpha = 0.7) +
  coord_sf(xlim = xlim, ylim = ylim, expand = F) +
  scale_color_manual(name = expression("Beam Crossing Angle ("*degree*")"),
                     values = c("red", "blue")) +
  # scale_color_manual(name = expression("Ângulo de Cruzamento do Feixe ("*degree*")"),
  #                    values = c("red", "blue")) +  # pt-br
  scale_shape_manual(name = "Radar", values = c(21, 22, 24)) +
  theme(axis.title = element_blank(),
        legend.position = "bottom", legend.title.align = 0.5, 
        plot.background = element_rect(fill = "transparent", 
                                       color = "transparent"),
        legend.background = element_rect(fill = "transparent")) +
  guides(color = guide_legend(override.aes = list(size = 3))) +
  facet_wrap(~ combination)
ggsave("General_Processing/figures/dual_doppler_lobes.png", 
       width = 7.1, height = 3.5, bg = "transparent")
# ggsave("General_Processing/figures/dual_doppler_lobes_ptbr.png", width = 3.2,
#        height = 6.5, bg = "transparent")  # pt-br
