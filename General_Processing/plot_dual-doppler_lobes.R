#-------------------------------------------------------------------------------
# DUAL-DOPPLER LOBES
# Based on "dual-doppler-v2.R" by Rachel Albrecht
#-------------------------------------------------------------------------------

# Loading necessary packages ---------------------------------------------------
require(maptools)
require(maps)
require(mapdata)  # worldHires database
require(mapproj)  # mapproject function
require(geosphere)
require(tidyverse)
require(ggrepel)

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
CITIES <- readShapeLines("Data/GENERAL/shapefiles/sao_paulo.shp")
STATES <- readShapeLines("Data/GENERAL/shapefiles/estadosl_2007.shp")
SAO <- coordinates(CITIES@lines[[578]])[[1]] %>%
  data.frame(x = .[, 1], y =.[, 2])
GUA <- coordinates(CITIES@lines[[578]])[[1]] %>%
  data.frame(x = .[, 1], y = .[, 2])
CMP <- coordinates(CITIES@lines[[147]])[[1]] %>%
  data.frame(x = .[, 1], y = .[, 2])
IND <- coordinates(CITIES@lines[[251]])[[1]] %>%
  data.frame(x = .[, 1], y = .[, 2])

# - Radar coordinates
sr <- data.frame(x = -(47 + (5+52/60)/60), y = -(23 + (35+56/60)/60))
fcth <- data.frame(x = -(45 + (58+20/60)/60), y = -(23 + (36+0/60)/60))
xpol <- data.frame(x = -47.05641, y = -22.81405)
radars_dist <- data.frame(
  combination = c("SR/FCTH", "SR/XPOL", "FCTH/XPOL"),
  distance = c(distm(sr, fcth, fun = distHaversine) * 1e-3,
               distm(sr, xpol, fun = distHaversine) * 1e-3,
               distm(fcth, xpol, fun = distHaversine) * 1e-3),
  midlon = c(midPoint(sr, fcth)[1], midPoint(sr, xpol)[1], midPoint(fcth, xpol)[1]),
  midlat = c(midPoint(sr, fcth)[2], midPoint(sr, xpol)[2], midPoint(fcth, xpol)[2])
) %>% 
  mutate(distance = sprintf("%3.0f km", distance))
radars <- bind_rows(
  list(
    SR = bind_rows(sr, sr) %>% mutate(combination = c("SR/FCTH", "SR/XPOL")), 
    FCTH = bind_rows(fcth, fcth) %>% mutate(combination = c("SR/FCTH", "FCTH/XPOL")),
    XPOL = bind_rows(xpol, xpol) %>% mutate(combination = c("SR/XPOL", "FCTH/XPOL"))
    ),
  .id = "radar")

xlim <- c(-49, -45); ylim <- c(-25, -22)

# - 30 degrees view
dd30 <- list(sr_fcth = DualDopplerLobes(sr, fcth, 30, 0, 180),
             sr_xpol = DualDopplerLobes(sr, xpol, 30, 93, 273),
             fcth_xpol = DualDopplerLobes(fcth, xpol, 30, 38.5, 218.5))
# - 45 degrees view
dd45 <- list(sr_fcth = DualDopplerLobes(sr, fcth, 45, 0, 180),
             sr_xpol = DualDopplerLobes(sr, xpol, 45, 93, 273),
             fcth_xpol = DualDopplerLobes(fcth, xpol, 45, 38.5, 218.5))

circles <- list(
  map(dd30, ~dfCircle(.x$p1.x, .x$p1.y, .x$r*1e-3) %>% mutate(group = "a", angle = "30")),
  map(dd30, ~dfCircle(.x$p2.x, .x$p2.y, .x$r*1e-3) %>% mutate(group = "b", angle = "30")),
  map(dd45, ~dfCircle(.x$p1.x, .x$p1.y, .x$r*1e-3) %>% mutate(group = "c", angle = "45")),
  map(dd45, ~dfCircle(.x$p2.x, .x$p2.y, .x$r*1e-3) %>% mutate(group = "d", angle = "45"))
  ) %>%
  flatten_dfr(.id = "combination") %>%
  mutate(combination = toupper(combination) %>% str_replace("_", "/"))

# - Plotting
ggplot() +
  coord_cartesian(xlim = xlim, ylim = ylim) +
  geom_path(data = fortify(STATES), aes(long, lat, group = group), inherit.aes = F, colour = "gray30", size = 0.3) +
  geom_path(data = SAO, aes(x, y), inherit.aes = F, colour = "gray30", size = 0.3) +
  geom_path(data = CMP, aes(x, y), inherit.aes = F, colour = "gray30", size = 0.3) +
  geom_path(data = IND, aes(x, y), inherit.aes = F, colour = "gray30", size = 0.3) +
  geom_point(data = radars, aes(x, y)) +
  geom_path(data = circles, aes(x = lon, y = lat, color = angle, group = group)) +
  scale_color_manual(name = expression("Beam Crossing Angle ("*degree*")"), values = c("red", "blue")) +
  geom_label_repel(data = radars, aes(x, y, label = radar), point.padding = 0.25, force = 100, size = 3, alpha = 0.7, min.segment.length = 0) +
  geom_line(data = radars, aes(x, y), linetype = "dashed") +
  geom_label_repel(data = radars_dist, aes(midlon, midlat, label = distance), point.padding = 0.1, size = 2, alpha = 0.7, min.segment.length = 0) +
  theme(legend.position = "bottom") +
  labs(x = expression("Longitude ("*degree*")"), y = expression("Latitude ("*degree*")")) +
  facet_grid(combination ~ .)
# ggsave("General_Processing/figures/dual_doppler_lobes.png", width = 3.1, height = 6)
