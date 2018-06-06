#--------------------------------------------------------------------------
#-- Lendo, processando e plotando os dados da brasildat
#--------------------------------------------------------------------------

#-- Pacotes necessários
library("tidyverse"); library("lubridate"); library("reshape2"); library("fields"); library("scales"); library(cowplot)
source("shapes.R") #-- Abrindo shapefiles

theme_update(plot.title = element_text(hjust = 0.5)) #-- Centralizando os títulos dos gráficos

#-- Lendo/processando/plotando os dados
hailpads <- read_csv("dados_entrada/posicao_hailpads")

#--- 2017-03-14
files <- read_csv("dados_entrada/cth_level0_20170314", col_names = FALSE)
track <- read_csv("dados_entrada/rastreamento_20170314") %>% 
  mutate(data = substr(files$X1[n], 51, 64)) %>% 
  mutate(data = as.POSIXct(strptime(data, format = "%Y%m%d%H%M%S", "GMT"))) %>% 
  mutate(periodo = ceiling_date(data, "5 minutes")) %>% 
  select(-c(n, data))

temp <- read_csv("../Dados/RAIOS/BrasilDAT/2017/03/LDTL21040020170314235900.dat") 
colnames(temp) <- c("data", "lat", "lon", "z", "peak_curr", "class", "axis_bigger", "axis_smaller", "angle", "nsp")
brasildat <- temp %>% select(data, lat, lon, class, peak_curr) %>% 
  mutate(class = ifelse(class == 0, "CG", "IC")) %>% 
  filter(class == "CG") %>% mutate(class = ifelse(peak_curr > 0, "CG +", "CG -")) %>% 
  filter(data >= (track$periodo[1] - 5*60) & data <= (track$periodo[length(track$periodo)] + 5*60)) %>% 
  mutate(periodo = ceiling_date(data, "5 minutes", change_on_boundary = F)) %>% 
  full_join(., track, by = "periodo") %>% 
  filter(lat >= lat_inf & lat <= lat_sup & lon >= lon_esq & lon <= lon_dir)

totais <- select(brasildat, lat, lon, data, class)
qte_total_e <- c(paste("Total CG + =", length(totais$class[totais$class == "CG +"])), 
                 paste("Total CG - =", length(totais$class[totais$class == "CG -"])))
rcount <- select(brasildat, data, class)

grid <- data.frame("lon" = c(-47.5, -46.75), "lat" = c(-23.4, -22.5))
hailpad <- hailpads %>% mutate(caso = as.POSIXct(strptime(caso, format = "%Y-%m-%d-%H-%M", "GMT"))) %>%
  filter(day(caso) == "14")

plte <- ggplot(data = brasildat) +
  scale_x_continuous(limits = grid$lon) + scale_y_continuous(limits = grid$lat)+
  geom_point(aes(x = lon, y = lat, color = data, shape = class), size = 2) +
  geom_path(data = fortify(CITIES), aes(long, lat, group = group), inherit.aes = F, colour = "gray30") +
  geom_point(data = hailpad, aes(x = lon, y = lat), pch = 0, size = 2) +
  geom_label(aes(x = ((grid$lon[1] + grid$lon[2])/2 - 0.2), y = grid$lat[2], label = qte_total_e[2])) +
  geom_label(aes(x = ((grid$lon[1] + grid$lon[2])/2 + 0.2), y = grid$lat[2], label = qte_total_e[1])) +
  scale_shape_manual(name = "Type", values = c(6,2)) +
  scale_color_distiller(name = "Hour (UTC)", palette = "Dark2", trans = time_trans()) +
  labs(x = "Longitude", y = "Latitude") +
  guides(shape = guide_legend(order = 1), color = guide_colorbar(order = 2))
pltf <- ggplot(rcount) +
  scale_x_datetime(limits = c(min(track$periodo), max(track$periodo)), labels = date_format("%Y-%m-%d\n%H:%M", "GMT"),
                   breaks = scales::pretty_breaks(n = 4)) +
  geom_histogram(binwidth = 60, aes(x = data, ..count.., fill = class)) +
  geom_vline(xintercept = hailpad$caso, col = "gray31") +
  scale_fill_manual(name = "Type", values = c("violetred1", "darkmagenta")) +
  labs(x = "Date (UTC)", y = "Strokes/min") +
  theme(axis.text.x = element_text(size = 10))
#-------------------------------------------------------------------------------------------------------------------
#--- 2017-11-15
files <- read_csv("dados_entrada/cth_level0_20171115", col_names = FALSE)
track <- read_csv("dados_entrada/rastreamento_20171115") %>% 
  mutate(data = substr(files$X1[n], 51, 64)) %>% 
  mutate(data = as.POSIXct(strptime(data, format = "%Y%m%d%H%M%S", "GMT"))) %>% 
  mutate(periodo = ceiling_date(data, "5 minutes")) %>% 
  select(-c(n, data))

temp <- read_csv("../Dados/RAIOS/BrasilDAT/2017/11/LDTL21040020171115235900.dat") 
colnames(temp) <- c("data", "lat", "lon", "z", "peak_curr", "class", "axis_bigger", "axis_smaller", "angle", "nsp")
brasildat <- temp %>% select(data, lat, lon, class, peak_curr) %>% 
  mutate(class = ifelse(class == 0, "CG", "IC")) %>% 
  filter(class == "CG") %>% mutate(class = ifelse(peak_curr > 0, "CG +", "CG -")) %>% 
  filter(data >= (track$periodo[1] - 5*60) & data <= (track$periodo[length(track$periodo)] + 5*60)) %>% 
  mutate(periodo = ceiling_date(data, "5 minutes", change_on_boundary = F)) %>% 
  full_join(., track, by = "periodo") %>% 
  filter(lat >= lat_inf & lat <= lat_sup & lon >= lon_esq & lon <= lon_dir)

totais <- select(brasildat, lat, lon, data, class)
qte_total_g <- c(paste("Total CG + =", length(totais$class[totais$class == "CG +"])), 
                 paste("Total CG - =", length(totais$class[totais$class == "CG -"])))
rcount <- select(brasildat, data, class)

grid <- data.frame("lon" = c(-47.5, -46.75), "lat" = c(-23.4, -22.5))
hailpad <- hailpads %>% mutate(caso = as.POSIXct(strptime(caso, format = "%Y-%m-%d-%H-%M", "GMT"))) %>%
  filter(day(caso) == "15")

pltg <- ggplot(data = brasildat) +
  scale_x_continuous(limits = grid$lon) + scale_y_continuous(limits = grid$lat)+
  geom_point(aes(x = lon, y = lat, color = data, shape = class), size = 2) +
  geom_path(data = fortify(CITIES), aes(long, lat, group = group), inherit.aes = F, colour = "gray30") +
  geom_point(data = hailpad, aes(x = lon, y = lat), pch = 0, size = 2) +
  geom_label(aes(x = ((grid$lon[1] + grid$lon[2])/2 - 0.2), y = grid$lat[2], label = qte_total_g[2])) +
  geom_label(aes(x = ((grid$lon[1] + grid$lon[2])/2 + 0.2), y = grid$lat[2], label = qte_total_g[1])) +
  scale_shape_manual(name = "Type", values = c(6,2)) +
  scale_color_distiller(name = "Hour (UTC)", palette = "Dark2", trans = time_trans()) +
  labs(x = "Longitude", y = "Latitude") +
  guides(shape = guide_legend(order = 1), color = guide_colorbar(order = 2))
plth <- ggplot(rcount) +
  scale_x_datetime(limits = c(min(track$periodo), max(track$periodo)), labels = date_format("%Y-%m-%d\n%H:%M", "GMT"),
                   breaks = scales::pretty_breaks(n = 4)) +
  geom_histogram(binwidth = 60, aes(x = data, ..count.., fill = class)) +
  geom_vline(xintercept = hailpad$caso, col = "gray31") +
  scale_fill_manual(name = "Type", values = c("violetred1", "darkmagenta")) +
  labs(x = "Date (UTC)", y = "Strokes/min") +
  theme(axis.text.x = element_text(size = 10))
#------------------------------------------------------------------------------
plt <- plot_grid(plte, pltf, labels = c("a", "b"), ncol = 2, rel_widths = c(0.47, 0.53))
title <- ggdraw() + draw_label("CG Strokes BrasilDAT", size = 18, fontface = "bold")
plg <- plot_grid(title, plt, ncol = 1, rel_heights = c(0.15,1))
save_plot("brasildat_cg.png", plot = plg, ncol = 2, base_width = 5, base_height = 3)
