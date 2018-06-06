#--------------------------------------------------------------------------
#-- Lendo, processando e plotando os dados da STARNET
#--------------------------------------------------------------------------

#-- Pacotes necessários
library("tidyverse"); library("lubridate"); library("reshape2"); library("fields"); library("scales"); library(cowplot)
source("shapes.R") #-- Abrindo shapefiles

theme_update(plot.title = element_text(hjust = 0.5)) #-- Centralizando os títulos dos gráficos

#-- Lendo/processando/plotando os dados
hailpads <- read_csv("dados_entrada/posicao_hailpads")

#--- 2016-12-25
# files <- read_csv("dados_entrada/cth_level0_20161225", col_names = FALSE)
# track <- read_csv("dados_entrada/rastreamento_20161225") %>% 
#   mutate(data = substr(files$X1[n], 51, 64)) %>% 
#   mutate(data = as.POSIXct(strptime(data, format = "%Y%m%d%H%M%S", "GMT"))) %>% 
#   mutate(periodo = ceiling_date(data, "5 minutes")) %>% 
#   select(-c(n, data))
# 
# temp <- read.table("../Dados/RAIOS/STARNET/2016-12/2016-12-25.dat", header = F) %>% select(1:9)
# colnames(temp) <- c("ano","mes","dia","hor","min","seg","sss","lat","lon")
# starnet <- temp %>% 
#   unite(ano, mes, dia, hor, min, seg, col = "data", sep = "_") %>%
#   select(data, lat, lon) %>%
#   mutate(data = as.POSIXct(strptime(data, format = "%Y_%m_%d_%H_%M_%S", "GMT"))) %>%
#   filter(data >= (track$periodo[1] - 5*60) & data <= (track$periodo[length(track$periodo)] + 5*60)) %>% 
#   mutate(periodo = ceiling_date(data, "5 minutes", change_on_boundary = F)) %>% 
#   full_join(., track, by = "periodo") %>% 
#   filter(lat >= lat_inf & lat <= lat_sup & lon >= lon_esq & lon <= lon_dir)
# 
# totais <- select(starnet, lat, lon, data)
# qte_total_a <- paste("Total =", length(totais$data))
# rcount <- select(starnet, data)
# 
# grid <- data.frame("lon" = c(-47.5, -46.75), "lat" = c(-23.4, -22.5))
# hailpad <- hailpads %>% filter(caso == "2016-12-25") %>% select(lat, lon)
# 
# plta <- ggplot(data = starnet) +
#   scale_x_continuous(limits = grid$lon) + scale_y_continuous(limits = grid$lat)+
#   geom_point(aes(x = lon, y = lat, color = data), shape = 4, size = 3) +
#   geom_path(data = fortify(CITIES), aes(long, lat, group = group), inherit.aes = F, colour = "gray30") +
#   geom_point(data = hailpad, aes(x = lon, y = lat), pch = 0, size = 2) +
#   geom_label(aes(x = ((grid$lon[1] + grid$lon[2])/2), y = grid$lat[2], label = qte_total_a)) +
#   scale_color_distiller(name = "Hour (UTC)", palette = "Dark2", trans = time_trans()) +
#   labs(x = "Longitude", y = "Latitude")
# pltb <- ggplot(rcount) +
#   scale_x_datetime(limits = c(min(track$periodo), max(track$periodo)), labels = date_format("%Y-%m-%d\n%H:%M", "GMT"),
#                    breaks = scales::pretty_breaks(n = 4)) +
#   geom_histogram(binwidth = 60, aes(x = data, ..count..), fill = "blue") +
#   labs(x = "Date (UTC)", y = "Sferics/min") +
#   theme(axis.text.x = element_text(size = 10))
# #-------------------------------------------------------------------------------------------------------------------
# #--- 2017-01-31
# files <- read_csv("dados_entrada/cth_level0_20170131", col_names = FALSE)
# track <- read_csv("dados_entrada/rastreamento_20170131") %>% 
#   mutate(data = substr(files$X1[n], 51, 64)) %>% 
#   mutate(data = as.POSIXct(strptime(data, format = "%Y%m%d%H%M%S", "GMT"))) %>% 
#   mutate(periodo = ceiling_date(data, "5 minutes")) %>% 
#   select(-c(n, data))
# 
# temp <- read.table("../Dados/RAIOS/STARNET/2017-01/2017-01-31.dat", header = F) %>% select(1:9)
# colnames(temp) <- c("ano","mes","dia","hor","min","seg","sss","lat","lon")
# starnet <- temp %>% 
#   unite(ano, mes, dia, hor, min, seg, col = "data", sep = "_") %>%
#   select(data, lat, lon) %>%
#   mutate(data = as.POSIXct(strptime(data, format = "%Y_%m_%d_%H_%M_%S", "GMT"))) %>%
#   filter(data >= (track$periodo[1] - 5*60) & data <= (track$periodo[length(track$periodo)] + 5*60)) %>% 
#   mutate(periodo = ceiling_date(data, "5 minutes", change_on_boundary = F)) %>% 
#   full_join(., track, by = "periodo") %>% 
#   filter(lat >= lat_inf & lat <= lat_sup & lon >= lon_esq & lon <= lon_dir)
# 
# totais <- select(starnet, lat, lon, data)
# qte_total_c <- paste("Total =", length(totais$data))
# rcount <- select(starnet, data)
# 
# grid <- data.frame("lon" = c(-47.5, -46.75), "lat" = c(-23.4, -22.5))
# hailpad <- hailpads %>% filter(caso == "2017-01-31") %>% select(lat, lon)
# 
# plt <- ggplot(data = starnet) +
#   scale_x_continuous(limits = grid$lon) + scale_y_continuous(limits = grid$lat)+
#   geom_point(aes(x = lon, y = lat, color = data), shape = 4, size = 3) +
#   geom_path(data = fortify(CITIES), aes(long, lat, group = group), inherit.aes = F, colour = "gray30") +
#   geom_point(data = hailpad, aes(x = lon, y = lat), pch = 0, size = 2) +
#   geom_label(aes(x = ((grid$lon[1] + grid$lon[2])/2), y = grid$lat[2], label = qte_total_c)) +
#   scale_color_distiller(name = "Hour (UTC)", palette = "Dark2", trans = time_trans()) +
#   labs(x = "Longitude", y = "Latitude")
# pltc <- plot_grid(plt, NULL, ncol = 2, rel_widths = c(0.72, 0.28))
# pltd <- ggplot(rcount) +
#   scale_x_datetime(limits = c(min(track$periodo), max(track$periodo)), labels = date_format("%Y-%m-%d\n%H:%M", "GMT"),
#                    breaks = scales::pretty_breaks(n = 4)) +
#   geom_histogram(binwidth = 60, aes(x = data, ..count..), fill = "blue") +
#   labs(x = "Date (UTC)", y = "Sferics/min") +
#   theme(axis.text.x = element_text(size = 10))
#-------------------------------------------------------------------------------------------------------------------
#--- 2017-03-14
files <- read_csv("dados_entrada/cth_level0_20170314", col_names = FALSE)
track <- read_csv("dados_entrada/rastreamento_20170314") %>% 
  mutate(data = substr(files$X1[n], 51, 64)) %>% 
  mutate(data = as.POSIXct(strptime(data, format = "%Y%m%d%H%M%S", "GMT"))) %>% 
  mutate(periodo = ceiling_date(data, "5 minutes")) %>% 
  select(-c(n, data))

temp <- read.table("../Dados/RAIOS/STARNET/2017-03/2017-03-14.dat", header = F) %>% select(1:9)
colnames(temp) <- c("ano","mes","dia","hor","min","seg","sss","lat","lon")
starnet <- temp %>% 
  unite(ano, mes, dia, hor, min, seg, col = "data", sep = "_") %>%
  select(data, lat, lon) %>%
  mutate(data = as.POSIXct(strptime(data, format = "%Y_%m_%d_%H_%M_%S", "GMT"))) %>%
  filter(data >= (track$periodo[1] - 5*60) & data <= (track$periodo[length(track$periodo)] + 5*60)) %>% 
  mutate(periodo = ceiling_date(data, "5 minutes", change_on_boundary = F)) %>% 
  full_join(., track, by = "periodo") %>% 
  filter(lat >= lat_inf & lat <= lat_sup & lon >= lon_esq & lon <= lon_dir)

totais <- select(starnet, lat, lon, data)
qte_total_e <- paste("Total =", length(totais$data))
rcount <- select(starnet, data)

grid <- data.frame("lon" = c(-47.5, -46.75), "lat" = c(-23.4, -22.5))
hailpad <- hailpads %>% mutate(caso = as.POSIXct(strptime(caso, format = "%Y-%m-%d-%H-%M", "GMT"))) %>%
  filter(day(caso) == "14")

plte <- ggplot(data = starnet) +
  scale_x_continuous(limits = grid$lon) + scale_y_continuous(limits = grid$lat)+
  geom_point(aes(x = lon, y = lat, color = data), shape = 4, size = 3) +
  geom_path(data = fortify(CITIES), aes(long, lat, group = group), inherit.aes = F, colour = "gray30") +
  geom_point(data = hailpad, aes(x = lon, y = lat), pch = 0, size = 2) +
  geom_label(aes(x = ((grid$lon[1] + grid$lon[2])/2), y = grid$lat[2], label = qte_total_e)) +
  scale_color_distiller(name = "Hour (UTC)", palette = "Dark2", trans = time_trans()) +
  labs(x = "Longitude", y = "Latitude")
pltf <- ggplot(rcount) +
  scale_x_datetime(limits = c(min(track$periodo), max(track$periodo)), labels = date_format("%Y-%m-%d\n%H:%M", "GMT"),
                   breaks = scales::pretty_breaks(n = 4)) +
  geom_histogram(binwidth = 60, aes(x = data, ..count..), fill = "blue") +
  geom_vline(xintercept = hailpad$caso, col = "gray31") +
  labs(x = "Date (UTC)", y = "Sferics/min") +
  theme(axis.text.x = element_text(size = 10))
#-------------------------------------------------------------------------------------------------------------------
#--- 2017-11-15
files <- read_csv("dados_entrada/cth_level0_20171115", col_names = FALSE)
track <- read_csv("dados_entrada/rastreamento_20171115") %>% 
  mutate(data = substr(files$X1[n], 51, 64)) %>% 
  mutate(data = as.POSIXct(strptime(data, format = "%Y%m%d%H%M%S", "GMT"))) %>% 
  mutate(periodo = ceiling_date(data, "5 minutes")) %>% 
  select(-c(n, data))

temp <- read.table("../Dados/RAIOS/STARNET/2017-11/2017-11-15.dat", header = F) %>% select(1:9)
colnames(temp) <- c("ano","mes","dia","hor","min","seg","sss","lat","lon")
starnet <- temp %>% 
  unite(ano, mes, dia, hor, min, seg, col = "data", sep = "_") %>%
  select(data, lat, lon) %>%
  mutate(data = as.POSIXct(strptime(data, format = "%Y_%m_%d_%H_%M_%S", "GMT"))) %>%
  filter(data >= (track$periodo[1] - 5*60) & data <= (track$periodo[length(track$periodo)] + 5*60)) %>% 
  mutate(periodo = ceiling_date(data, "5 minutes", change_on_boundary = F)) %>% 
  full_join(., track, by = "periodo") %>% 
  filter(lat >= lat_inf & lat <= lat_sup & lon >= lon_esq & lon <= lon_dir)

totais <- select(starnet, lat, lon, data)
qte_total_g <- paste("Total =", length(totais$data))
rcount <- select(starnet, data)

grid <- data.frame("lon" = c(-47.5, -46.75), "lat" = c(-23.4, -22.5))
hailpad <- hailpads %>% mutate(caso = as.POSIXct(strptime(caso, format = "%Y-%m-%d-%H-%M", "GMT"))) %>%
  filter(day(caso) == "15")

pltg <- ggplot(data = starnet) +
  scale_x_continuous(limits = grid$lon) + scale_y_continuous(limits = grid$lat)+
  geom_point(aes(x = lon, y = lat, color = data), shape = 4, size = 3) +
  geom_path(data = fortify(CITIES), aes(long, lat, group = group), inherit.aes = F, colour = "gray30") +
  geom_point(data = hailpad, aes(x = lon, y = lat), pch = 0, size = 2) +
  geom_label(aes(x = ((grid$lon[1] + grid$lon[2])/2), y = grid$lat[2], label = qte_total_g)) +
  scale_color_distiller(name = "Hour (UTC)", palette = "Dark2", trans = time_trans()) +
  labs(x = "Longitude", y = "Latitude")
plth <- ggplot(rcount) +
  scale_x_datetime(limits = c(min(track$periodo), max(track$periodo)), labels = date_format("%Y-%m-%d\n%H:%M", "GMT"),
                   breaks = scales::pretty_breaks(n = 4)) +
  geom_histogram(binwidth = 60, aes(x = data, ..count..), fill = "blue") +
  geom_vline(xintercept = hailpad$caso, col = "gray31") +
  labs(x = "Date (UTC)", y = "Sferics/min") +
  theme(axis.text.x = element_text(size = 10))
#-------------------------------------------------------------------------------------------------------------------
#--- 2017-11-16
# files <- read_csv("dados_entrada/cth_level0_20171116", col_names = FALSE)
# track <- read_csv("dados_entrada/rastreamento_20171116") %>% 
#   mutate(data = substr(files$X1[n], 51, 64)) %>% 
#   mutate(data = as.POSIXct(strptime(data, format = "%Y%m%d%H%M%S", "GMT"))) %>% 
#   mutate(periodo = ceiling_date(data, "5 minutes")) %>% 
#   select(-c(n, data))
# 
# temp <- read.table("../Dados/RAIOS/STARNET/2017-11/2017-11-16.dat", header = F) %>% select(1:9)
# colnames(temp) <- c("ano","mes","dia","hor","min","seg","sss","lat","lon")
# starnet <- temp %>% 
#   unite(ano, mes, dia, hor, min, seg, col = "data", sep = "_") %>%
#   select(data, lat, lon) %>%
#   mutate(data = as.POSIXct(strptime(data, format = "%Y_%m_%d_%H_%M_%S", "GMT"))) %>%
#   filter(data >= (track$periodo[1] - 5*60) & data <= (track$periodo[length(track$periodo)] + 5*60)) %>% 
#   mutate(periodo = ceiling_date(data, "5 minutes", change_on_boundary = F)) %>% 
#   full_join(., track, by = "periodo") %>% 
#   filter(lat >= lat_inf & lat <= lat_sup & lon >= lon_esq & lon <= lon_dir)
# 
# totais <- select(starnet, lat, lon, data)
# qte_total_i <- paste("Total =", length(totais$data))
# rcount <- select(starnet, data)
# 
# grid <- data.frame("lon" = c(-47.5, -46.75), "lat" = c(-23.4, -22.5))
# hailpad <- hailpads %>% filter(caso == "2017-11-16") %>% select(lat, lon)
# 
# plti <- ggplot(data = starnet) +
#   scale_x_continuous(limits = grid$lon) + scale_y_continuous(limits = grid$lat)+
#   geom_point(aes(x = lon, y = lat, color = data), shape = 4, size = 3) +
#   geom_path(data = fortify(CITIES), aes(long, lat, group = group), inherit.aes = F, colour = "gray30") +
#   geom_point(data = hailpad, aes(x = lon, y = lat), pch = 0, size = 2) +
#   geom_label(aes(x = ((grid$lon[1] + grid$lon[2])/2), y = grid$lat[2], label = qte_total_i)) +
#   scale_color_distiller(name = "Hour (UTC)", palette = "Dark2", trans = time_trans()) +
#   labs(x = "Longitude", y = "Latitude")
# pltj <- ggplot(rcount) +
#   scale_x_datetime(limits = c(min(track$periodo), max(track$periodo)), labels = date_format("%Y-%m-%d\n%H:%M", "GMT"),
#                    breaks = scales::pretty_breaks(n = 4)) +
#   geom_histogram(binwidth = 60, aes(x = data, ..count..), fill = "blue") +
#   labs(x = "Date (UTC)", y = "Sferics/min") +
#   theme(axis.text.x = element_text(size = 10))
#------------------------------------------------------------------------------
plt <- plot_grid(plte, pltf, NULL, pltg, plth, NULL, labels = c("a", "b", "", "c", "d", ""), ncol = 3, rel_widths = c(0.49, 0.53, 0.025))
title <- ggdraw() + draw_label("Sferics STARNET", size = 18, fontface = "bold")
plg <- plot_grid(title, plt, ncol = 1, rel_heights = c(0.055,1))
save_plot("starnet_all.png", plot = plg, ncol = 2, base_width = 5, base_height = 6)
