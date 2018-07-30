#--------------------------------------------------------------------------
#-- Lendo e plotando dados de rastreamento de PPIs
#--------------------------------------------------------------------------

#-- Carregando pacotes necessários
require(readr); require(tidyverse); require(reshape2)
source("General_Processing/functions.R")

#-- Lendo e processando os dados
hailpads <- read_csv("data_files/posicao_hailpads")

files <- read_csv("data_files/cth_level0_20161225", col_names = FALSE)
tracks <- read_csv("data_files/rastreamento_20161225") %>% 
  mutate(data = substr(files$X1[n], 51, 64)) %>% 
  mutate(data = as.POSIXct(strptime(data, format = "%Y%m%d%H%M%S", "GMT"))) %>% 
  separate(data, into = c("caso", "hora"), sep = " ") %>% 
  rownames_to_column() %>% 
  mutate(lat = (lat_sup + lat_inf)/2, lon = (lon_esq + lon_dir)/2) %>% 
  mutate(size= ((lat_sup - lat_inf) + (lon_dir - lon_esq))/2) %>% 
  select(caso, rowname, hora, lat, lon, size)

files <- read_csv("data_files/cth_level0_20170131", col_names = FALSE)
track_temp <- read_csv("data_files/rastreamento_20170131") %>% 
  mutate(data = substr(files$X1[n], 51, 64)) %>% 
  mutate(data = as.POSIXct(strptime(data, format = "%Y%m%d%H%M%S", "GMT"))) %>% 
  separate(data, into = c("caso", "hora"), sep = " ") %>% 
  rownames_to_column() %>% 
  mutate(lat = (lat_sup + lat_inf)/2, lon = (lon_esq + lon_dir)/2) %>% 
  mutate(size= ((lat_sup - lat_inf) + (lon_dir - lon_esq))/2) %>% 
  select(caso, rowname, hora, lat, lon, size)

tracks <- rbind(tracks, track_temp)

files <- read_csv("data_files/cth_level0_20170314", col_names = FALSE)
track_temp <- read_csv("data_files/rastreamento_20170314") %>% 
  mutate(data = substr(files$X1[n], 51, 64)) %>% 
  mutate(data = as.POSIXct(strptime(data, format = "%Y%m%d%H%M%S", "GMT"))) %>% 
  separate(data, into = c("caso", "hora"), sep = " ") %>% 
  rownames_to_column() %>% 
  mutate(lat = (lat_sup + lat_inf)/2, lon = (lon_esq + lon_dir)/2) %>% 
  mutate(size= ((lat_sup - lat_inf) + (lon_dir - lon_esq))/2) %>% 
  select(caso, rowname, hora, lat, lon, size)

tracks <- rbind(tracks, track_temp)

files <- read_csv("data_files/cth_level0_20171115", col_names = FALSE)
track_temp <- read_csv("data_files/rastreamento_20171115") %>% 
  mutate(data = substr(files$X1[n], 51, 64)) %>% 
  mutate(data = as.POSIXct(strptime(data, format = "%Y%m%d%H%M%S", "GMT"))) %>% 
  separate(data, into = c("caso", "hora"), sep = " ") %>% 
  rownames_to_column() %>% 
  mutate(lat = (lat_sup + lat_inf)/2, lon = (lon_esq + lon_dir)/2) %>% 
  mutate(size= ((lat_sup - lat_inf) + (lon_dir - lon_esq))/2) %>% 
  select(caso, rowname, hora, lat, lon, size)

tracks <- rbind(tracks, track_temp)

files <- read_csv("data_files/cth_level0_20171116", col_names = FALSE)
track_temp <- read_csv("data_files/rastreamento_20171116") %>% 
  mutate(data = substr(files$X1[n], 51, 64)) %>% 
  mutate(data = as.POSIXct(strptime(data, format = "%Y%m%d%H%M%S", "GMT"))) %>% 
  separate(data, into = c("caso", "hora"), sep = " ") %>% 
  rownames_to_column() %>% 
  mutate(lat = (lat_sup + lat_inf)/2, lon = (lon_esq + lon_dir)/2) %>% 
  mutate(size= ((lat_sup - lat_inf) + (lon_dir - lon_esq))/2) %>% 
  select(caso, rowname, hora, lat, lon, size)

tracks <- rbind(tracks, track_temp)

rm(files, track_temp)

#-- Plotando
theme_update(plot.title = element_text(hjust = 0.5))
grid <- data.frame("lon" = c(-47.5, -46.75), "lat" = c(-23.4, -22.5))

#--- GRÁFICO 1: TRAJETÓRIA COM TAMANHO E LABELS DE TEMPO
ggplot() +
  scale_x_continuous(limits = grid$lon) + scale_y_continuous(limits = grid$lat)+
  geom_path(data = tracks, aes(x = lon, y = lat, color = caso), size = 1) +
  geom_point(data = tracks, aes(x = lon, y = lat, color = caso, size = size), pch = 16, alpha = 0.25) +
  geom_text(data = tracks, aes(x = lon, y = lat, label = ifelse(rowname == 1, "O", NA), color = caso), size = 5, show.legend = F) +
  geom_point(data = hailpads, aes(x = lon, y = lat), pch = 0, size = 4) +
  geom_path(data = fortify(cities), aes(long, lat, group = group), inherit.aes = F, colour = "gray30") +
  scale_color_brewer(name = "Case", palette = "Set1") +
  scale_size_continuous(name = "Size (°)", range = c(0.5,10)) +
  labs(x = "Longitude (°)", y = "Latitude (°)") +
  ggtitle("Systems Trajectories")
ggsave("figures/trajetorias.png", width = 6, height = 5)
