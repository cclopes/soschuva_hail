#---------------------------------------------------------------------------------------------------------------------------------
#-- Reading ForTraCC trackings
#--- Files "data_fam[...].txt"
#--- Clusters "[...].dat"
#-- Selecting families correspondent to each case
#--- with hailpads ("registros_hailpads")
#-- Verifying the life cycle of selected families
#--- If one started with S/C, join it with previous families
#--- If one ended with S/M, join it with subsequent families
#---------------------------------------------------------------------------------------------------------------------------------

#-- Loading necessary scripts and packages
require(tidyverse); require(lubridate); require(fields); require(maptools); require(reshape2); require(magrittr)
source("General_Processing/functions.R")
#---------------------------------------------------------------------------------------------------------------------------------

#-- Radar Configuration

#---- 500 x 500 points
#---- 1 x 1 x 1 km
lins <- 500
cols <- 500

#--- Navigation
# lat_matrix <- file("Data/GENERAL/navigation/nav_rd.lat", "rb") %>% #-- FCTH
lat_matrix <- file("Data/GENERAL/navigation/nav_sr.lat", "rb") %>% #-- SR
  readBin(., numeric(), size=4, n=lins*cols) %>%
  matrix(., nrow = lins, ncol = cols)
# lon_matrix <- file("Data/GENERAL/navigation/nav_rd.lon", "rb") %>% #-- FCTH
lon_matrix <- file("Data/GENERAL/navigation/nav_sr.lon", "rb") %>% #-- SR
  readBin(., numeric(), size=4, n=lins*cols) %>%
  matrix(., nrow = lins, ncol = cols)
closeAllConnections()

lat_vector <- seq(min(lat_matrix), max(lat_matrix), length = cols)
lon_vector <- seq(min(lon_matrix), max(lon_matrix), length = lins)

#--- Plotting limits
lims_in_plot <- data.frame(lon = c(-48, -46), lat = c(-23.5, -22))
#---------------------------------------------------------------------------------------------------------------------------------

#-- Reading families, clusters and cappis filenames
filenames_fams <- dir(path = "ForTraCC_Processing/families", pattern = "*.txt", full.names = T)
filenames_clusters <- data.frame("path" = dir(path = "ForTraCC_Processing/clusters", 
                                              pattern = "*.dat", full.names = T)) %>%
  mutate(date = str_extract(path, "201\\d\\d\\d\\d\\d\\d\\d\\d\\d"))
filenames_cappis <- data.frame("path" = dir(path = "Data/RADAR/SR/level_2", pattern = "cappi_CZ_03000_201*",
                                            full.names = T)) %>%
  mutate(date = str_extract(path, "201\\d\\d\\d\\d\\d_\\d\\d\\d\\d") %>% gsub("\\_", "", .))

dates_clusters_cappis <- intersect(filenames_cappis$date, filenames_clusters$date)
filenames_clusters <- filenames_clusters %>% filter(date %in% dates_clusters_cappis) %>% pull(path) %>% as.character
filenames_cappis <- filenames_cappis %>% filter(date %in% dates_clusters_cappis) %>% pull(path) %>% as.character
#---------------------------------------------------------------------------------------------------------------------------------

#-- Reading and processing families data
data_fams <- filenames_fams %>% purrr::map(~read_table(.x, col_names = c("n", "year", "month", "day", "hour", "min",
                                        "lat", "lon", "size", "dsize", "pmed", "dpmed", "pmax", "dpmax", "pmax9",
                                        "dpmax9", "frac", "vel", "dir", "t_ini", "class", "sys", "sys_ant1", "sys_ant2",
                                        "sys_ant3", "sys_ant4", "sys_ant5", "sys_ant6", "sys_ant7", "sys_ant8", "sys_ant9",
                                        "sys_ant10"))) %>%
  purrr::map(~unite(.x, sys_ant1, sys_ant2, sys_ant3, sys_ant4, sys_ant5, sys_ant6, sys_ant7, sys_ant8, sys_ant9, sys_ant10,
             col = "sys_ant", sep = ",")) %>%
  purrr::map(~unite(.x, year, month, day, hour, min, col = "date", sep = "_")) %>%
  purrr::map(~mutate(.x, date = as.POSIXct(strptime(date, format = "%Y_%m_%d_%H_%M", "GMT")))) %>%
  purrr::map(~mutate(.x, date = floor_date(date, unit = "10 minutes")))
rm(filenames_fams)
#---------------------------------------------------------------------------------------------------------------------------------

#-- Reading and processing clusters data

#--- If this doesn't work, you don't have enough memory (I think)...
# data_clusters <- filenames_clusters %>% purrr::map(~file(.x, "rb")) %>%
#   purrr::map(~readBin(.x, integer(), size = 2, n = lins*cols)) %>%
#   purrr::map(~matrix(.x, nrow = lins, ncol = cols)) %>%
#   purrr::map(~ifelse(.x <= 0, NA, .x))
# closeAllConnections()
# # data_clusters <- purrr::map(data_clusters, ~.x[, cols:1])
# rm(filenames_clusters)

#--- ... so use this instead.
data_clusters <- list()
  for(i in 1:length(filenames_clusters)){
  data_clusters[[i]] <- file(filenames_clusters[i], "rb") %>%
    readBin(., integer(), size = 2, n = lins*cols) %>%
    matrix(., nrow = lins, ncol = cols)
  closeAllConnections()
  data_clusters[[i]][data_clusters[[i]] <= 0] <- NA
  # data_clusters[[i]] <- t(data_clusters[[i]][, cols:1])
}
# rm(filenames_clusters)
#---------------------------------------------------------------------------------------------------------------------------------

#-- Reading and processing cappis data
data_cappis <- filenames_cappis %>% purrr::map(~le_cappi(.x, lins, cols))
rm(filenames_cappis)
#---------------------------------------------------------------------------------------------------------------------------------

#-- Reading and processing hailpads registry data
data_hailpads <- read.table("Data/GENERAL/hailpads_registry", header = T) %>%
  mutate(date_arqs = str_replace_all(data, "-", "")) %>%
  mutate(date = as.POSIXct(strptime(data, format = "%Y-%m-%d-%H-%M", "GMT")))
#---------------------------------------------------------------------------------------------------------------------------------

#-- Selecting families correspondent to the hailpads registry

#--- Step 1: Find systems in the clusters where each hailpad is located
selected_clusters <- which(dates_clusters_cappis %in% data_hailpads$date_arqs, arr.ind = T) %>% data_clusters[.]
selected_lat <- purrr::map(as.list(data_hailpads$lat), ~which(lat_vector < (.x+0.025) & lat_vector > (.x-0.025))) #-- Not on the point!
selected_lon <- purrr::map(as.list(data_hailpads$lon), ~which(lon_vector < (.x+0.025) & lon_vector > (.x-0.025))) #-- Not on the point!

#--- Step 2: Extract these systems
selected_sys <- list()
for(i in 1:length(selected_clusters)){
  selected_sys[[i]] <- selected_clusters[[i]][selected_lon[[i]],]
  selected_sys[[i]] <- selected_sys[[i]][,selected_lat[[i]]]
}
selected_sys <- purrr::map(selected_sys, ~.x[which(!is.na(.x))]) %>% map_chr(unique) #- This may have problems if there is more
                                                                              #- than one family on the range defined above

#--- Step 3: Find families correspondent to these systems
selected_fams <- data_fams %>% map2(., data_hailpads$date, ~filter(.x, date == .y)) %>%
  map2(., selected_sys, ~filter(.x, sys == .y)) %>% purrr::map(~select(.x, n)) %>% unlist %>% as.character()

#--- Extracting whole life cycles of the families
selected_fams <- data_fams %>% map2(., selected_fams, ~filter(.x, n %in% .y))
#---------------------------------------------------------------------------------------------------------------------------------

#-- Verifying the life cycles of the selected families and applying corrections if necessary

problem_fams_start <- selected_fams %>% purrr::map(~group_by(.x, n)) %>% purrr::map(~slice(.x, 1)) %>%
  map_df(~filter(.x, class %in% c("S", "C"))) %>% ungroup() #%>% select(date, lat, lon, class)

problem_fams_end <- selected_fams %>% purrr::map(~group_by(.x, n)) %>% purrr::map(~slice(.x, n())) %>%
  map_df(~filter(.x, class %in% c("S", "M"))) %>% ungroup() #%>% select(date, lat, lon, class)

#--- Automatically (FAILED)
# fam_nm1 <- data_fams %>% map2(., problem_fams$date, ~filter(.x, date == (.y - 10*60))) %>%
  # map2(., problem_fams$class, ~filter(.x, class == .y)) %>%
  # map2(., problem_fams$size, ~mutate(.x, ds = .y - size)) %>%
  # map2_df(., problem_fams$lon, ~filter(.x, lon < (.y + 0.25) & lon > (.y - 0.25))) %>%
  # ungroup()

#--- Manually
#---- Solution: Find the other families and join WITHOUT the whole life cycle of them

#---- 30 dBZ
# fam_nm1 <- data_fams[[2]] %>% filter(n == 131) %>% filter(date < problem_fams$date)
# selected_fams[[2]] <- rbind(selected_fams[[1]], fam_nm1, selected_fams[[2]])
# fam_nm1 <- data_fams[[2]] %>% filter(n == 142) %>% filter(date == (problem_fams$date + 30*60))
# selected_fams[[2]] <- selected_fams[[1]] <- rbind(selected_fams[[2]], fam_nm1)
# fam_nm1 <- data_fams[[2]] %>% filter(n == 235) %>% filter(date > (problem_fams$date + 30*60))
# selected_fams[[2]] <- selected_fams[[1]] <- rbind(selected_fams[[2]], fam_nm1)

#---- 35dBZ
#----- Start
fam_nm1 <- data_fams[[3]] %>% filter(n == 46) %>% filter(date < problem_fams_start$date[1])
selected_fams[[3]] <- rbind(fam_nm1, selected_fams[[3]])

fam_nm1 <- data_fams[[5]] %>% filter(n == 69) %>% filter(date < (problem_fams_start$date[2]))
selected_fams[[5]] <- rbind(fam_nm1, selected_fams[[5]])

#----- End
fam_np1 <- data_fams[[1]] %>% filter(n == 138) %>% filter(date > (problem_fams_end$date[1]))
selected_fams[[1]] <- rbind(selected_fams[[1]], fam_np1)
fam_np1 <- data_fams[[1]] %>% filter(n == 169) %>% filter(date > (problem_fams_end$date[1] + 50*60))
selected_fams[[1]] <- rbind(selected_fams[[1]], fam_np1)
fam_np1 <- data_fams[[1]] %>% filter(n == 247) %>% filter(date > (problem_fams_end$date[1] + 120*60))
selected_fams[[1]] <- rbind(selected_fams[[1]], fam_np1)

fam_np1 <- data_fams[[4]] %>% filter(n == 279) %>% filter(date > (problem_fams_end$date[3]))
selected_fams[[4]] <- rbind(selected_fams[[4]], fam_np1)

fam_np1 <- selected_fams[[4]] %>% filter(date > (problem_fams_end$date[2]))
selected_fams[[3]] <- rbind(selected_fams[[3]], fam_np1)

fam_np1 <- data_fams[[5]] %>% filter(n == 89) %>% filter(date > (problem_fams_end$date[4]))
selected_fams[[5]] <- rbind(selected_fams[[5]], fam_np1)
#---------------------------------------------------------------------------------------------------------------------------------

#-- Joining cases in a single data frame
opt <- c("", "", "", " ", "", "")
selected_fams_df <- map2(selected_fams, opt, ~mutate(.x, case = paste("Case", lubridate::date(date), .y))) %>%
  map2(., data_hailpads$lon, ~mutate(.x, lon_hailpad = .y)) %>% map2(., data_hailpads$lat, ~mutate(.x, lat_hailpad = .y)) %>%
  map2(., data_hailpads$date, ~mutate(.x, date_hailpad = .y)) %>%
  map_df(rbind) %>% mutate(hour = date)
lubridate::date(selected_fams_df$hour) <- lubridate::date(selected_fams_df$date_hailpad) <- "2017-01-01"