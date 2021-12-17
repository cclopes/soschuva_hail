# ------------------------------------------------------------------------------
# READING PRE-PROCESSED CLUSTERS AND EXTRACTING "BOX LIMITS" AROUND THEM
# This will be used on FCTH data
# ------------------------------------------------------------------------------

# Loading required packages ----------------------------------------------------

library(tidyverse)
library(reshape2)

# Defining functions -----------------------------------------------------------

# Data processing
get_data <- function(
  selected_fam_i, selected_clusters_i, selected_cappis_i) {
  
  # Selecting data based on data of a timestamp and plotting
  
  # Formatting date str
  selected_date <- selected_fam_i$date
  
  # Respective system
  selected_sys <- selected_fam_i$sys
  
  # Respective cluster
  test <- matrix(unlist(selected_clusters_i), ncol = 500, byrow = T)
  row.names(test) <- sort(lat_vector, decreasing = F)
  colnames(test) <- lon_vector
  clusters <- melt(test, value.name = "nsystem", varnames = c("lat", "lon")) %>%
    na.omit() %>%
    filter(nsystem == selected_sys) %>% 
    mutate(date = selected_date) %>% 
    select(lat, lon, date) %>% 
    summarise(
      date = unique(date),
      min_lon = min(lon), 
      max_lon = max(lon), 
      min_lat = min(lat), 
      max_lat = max(lat)
    )
  
  return(clusters)
}


# Loading ForTraCC pre-processing ----------------------------------------------

load("ForTraCC_Processing/fortracc_data.RData")

# Converting to datetime format
dates_clusters_cappis <- as.POSIXct(strptime(dates_clusters_cappis, "%Y%m%d%H%M", "GMT"))


# Case 2017-03-14 --------------------------------------------------------------

selected_fam <- selected_fams_df %>% filter(as.Date(date) == "2017-03-14")
selected_clusters <- data_clusters[which(dates_clusters_cappis %in% selected_fam$date,
                                         arr.ind = T
)]
selected_cappis <- data_cappis[which(dates_clusters_cappis %in% selected_fam$date,
                                     arr.ind = T
)]

# Getting data for each timestamp

clusters_box <- get_data(
  selected_fam[1,], 
  selected_clusters[1], 
  selected_cappis[1]
)

for(i in seq(2, length(selected_clusters))) {
  clusters_box <- bind_rows(
    clusters_box,
    get_data(selected_fam[i,], selected_clusters[i], selected_cappis[i]),
  )
}

# Saving to a file
write_csv(clusters_box, "Radar_Processing/data_files/clusters_20170314.csv")

# Case 2017-11-15 --------------------------------------------------------------

selected_fam <- selected_fams_df %>% filter(as.Date(date) == "2017-11-15")
selected_clusters <- data_clusters[which(dates_clusters_cappis %in% selected_fam$date,
                                         arr.ind = T
)]
selected_cappis <- data_cappis[which(dates_clusters_cappis %in% selected_fam$date,
                                     arr.ind = T
)]

# Getting data for each timestamp

clusters_box <- get_data(
  selected_fam[1,], 
  selected_clusters[1], 
  selected_cappis[1]
)

for(i in seq(2, length(selected_clusters))) {
  clusters_box <- bind_rows(
    clusters_box,
    get_data(selected_fam[i,], selected_clusters[i], selected_cappis[i]),
  )
}

# Saving to a file
write_csv(clusters_box, "Radar_Processing/data_files/clusters_20171115.csv")