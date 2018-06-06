library("tidyverse"); library("lubridate"); library("reshape2"); library("fields"); library("scales")

theme_update(plot.title = element_text(hjust = 0.5), legend.position = "bottom") #-- Centralizando os títulos dos gráficos

#-- CASO DE CAMPINAS
arquivo <- "RAIOS/STARNET-Reprocessed/2016-06-05.dat"
grid <- list("lat" = c(-23.2, -22.6), "lon" = c(-47.6, -46.5)) #-- Limites da área de cobertura do caso
horarios <- c("02", "03", "04") #-- Selecionando período do caso

starnet <- read.table(arquivo, header = F) %>% select(1:9)
colnames(starnet) <- c("ano","mes","dia","hor","min","seg","sss","lat","lon")
starnet <- starnet %>% 
  unite(ano, mes, dia, hor, min, seg, col = "data", sep = "_") %>%
  select(data, lat, lon) %>%
  mutate(data = as.POSIXct(strptime(data, format = "%Y_%m_%d_%H_%M", "GMT"))) %>%
  filter(lat >= grid$lat[1] & lat <= grid$lat[2] & lon >= grid$lon[1] & lon <= grid$lon[2]) %>%
  filter(format(data, "%H") %in% horarios) %>%
  mutate(periodo = ceiling_date(data, "10 minutes", change_on_boundary = T)) %>%
  select(data) %>% 
  add_column("rede" = "STARNET")

arquivo <- "RAIOS/flash_CEMADEN_2016-06-05.txt"
grid <- list("lat" = c(-23.2, -22.6), "lon" = c(-47.6, -46.5)) #-- Limites da área de cobertura do caso
horarios <- c("02", "03", "04") #-- Selecionando período do caso

#-- Lendo/modificando o arquivo
brasildat <- read_table(arquivo) %>%
  separate("id  tipo", c("id", "tipo")) %>%
  unite(ano, mes, dia, hor, min, col = "data", sep = "_") %>%
  select(tipo, data, lat, lon, "pc(A)", "alt_ic(m)") %>%
  mutate(data = as.POSIXct(strptime(data, format = "%Y_%m_%d_%H_%M", "GMT"))) %>%
  filter(lat >= grid$lat[1] & lat <= grid$lat[2] & lon >= grid$lon[1] & lon <= grid$lon[2]) %>%
  filter(format(data, "%H") %in% horarios) %>%
  mutate(periodo = ceiling_date(data, "10 minutes", change_on_boundary = T)) %>%
  select(data) %>% 
  add_column("rede" = "BrasilDAT")

toplot <- rbind(starnet, brasildat)

#-- Plotando e salvando as imagens
plt <- ggplot(toplot) +
  scale_x_datetime(limits = c(as.POSIXct("2016-06-05 02:00:00", "GMT"), as.POSIXct("2016-06-05 05:00:00", "GMT")), labels = date_format("%Y-%m-%d\n%H:%M", "GMT")) +
  geom_freqpoly(binwidth = 60*5, aes(x = data, ..count.., color = rede)) +
  scale_color_manual(name = "Medido por", values = c("darkorange", "blue")) +
  labs(x = "Data (UTC)", y = "Raios a cada 5 min", title = "Strokes BrasilDAT e Sferics STARNET - Caso de Campinas")
ggsave("Figs/hist_campinas.png", plot = plt, width = 6, height = 4, units = "in")

#-----------------------------------------------------------------------------------------
#-- CASO DE JARINU
arquivo1 <- "RAIOS/STARNET-Reprocessed/2016-06-05.dat"
arquivo2 <- "RAIOS/STARNET-Reprocessed/2016-06-06.dat"
grid <- list("lat" = c(-23.4, -22.7), "lon" = c(-46.9, -46.1)) #-- Limites da área de cobertura do caso
horarios <- c("23", "00", "01") #-- Selecionando período do caso

temp1 <- read.table(arquivo1, header = F); temp1 <- temp1[temp1$V4 > 21,]
temp2 <- read.table(arquivo2, header = F); temp2 <- temp2[temp2$V4 < 21,]
starnet <- rbind(temp1, temp2) %>% select(1:9)
colnames(starnet) <- c("ano","mes","dia","hor","min","seg","sss","lat","lon")
starnet <- starnet %>% 
  unite(ano, mes, dia, hor, min, seg, col = "data", sep = "_") %>%
  select(data, lat, lon) %>%
  mutate(data = as.POSIXct(strptime(data, format = "%Y_%m_%d_%H_%M", "GMT"))) %>%
  filter(lat >= grid$lat[1] & lat <= grid$lat[2] & lon >= grid$lon[1] & lon <= grid$lon[2]) %>%
  filter(format(data, "%H") %in% horarios) %>%
  mutate(periodo = ceiling_date(data, "10 minutes", change_on_boundary = T)) %>%
  select(data) %>% 
  add_column("rede" = "STARNET")

arquivo1 <- "RAIOS/flash_CEMADEN_2016-06-05.txt"
arquivo2 <- "RAIOS/flash_CEMADEN_2016-06-06.txt"
grid <- list("lat" = c(-23.4, -22.7), "lon" = c(-46.9, -46.1)) #-- Limites da área de cobertura do caso
horarios <- c("23", "00", "01") #-- Selecionando período do caso

#-- Lendo/modificando o arquivo
temp1 <- read_table(arquivo1) %>% separate("id  tipo", c("id", "tipo"))
temp1 <- temp1[temp1$hor > 21,]
temp2 <- read.table(arquivo2, skip = 1)
temp2 <- temp2[temp2[,6] < 21,]
colnames(temp2) <- colnames(temp1)
brasildat <- rbind(temp1, temp2) %>%
  unite(ano, mes, dia, hor, min, col = "data", sep = "_") %>%
  select(tipo, data, lat, lon, "pc(A)", "alt_ic(m)") %>%
  mutate(data = as.POSIXct(strptime(data, format = "%Y_%m_%d_%H_%M", "GMT"))) %>%
  filter(lat >= grid$lat[1] & lat <= grid$lat[2] & lon >= grid$lon[1] & lon <= grid$lon[2]) %>%
  filter(format(data, "%H") %in% horarios) %>%
  mutate(periodo = ceiling_date(data, "10 minutes", change_on_boundary = T)) %>%
  select(data) %>% 
  add_column("rede" = "BrasilDAT")

toplot <- rbind(starnet, brasildat)

#-- Plotando e salvando as imagens
plt <- ggplot(toplot) +
  scale_x_datetime(limits = c(as.POSIXct("2016-06-05 23:00:00", "GMT"), as.POSIXct("2016-06-06 02:00:00", "GMT")), labels = date_format("%Y-%m-%d\n%H:%M", "GMT")) +
  geom_freqpoly(binwidth = 60*5, aes(x = data, ..count.., color = rede)) +
  scale_color_manual(name = "Medido por", values = c("darkorange", "blue")) +
  labs(x = "Data (UTC)", y = "Raios a cada 5 min", title = "Strokes BrasilDAT e Sferics STARNET - Caso de Jarinu")
ggsave("Figs/hist_jarinu.png", plot = plt, width = 6, height = 4, units = "in")

#------------------------------------------------------------------------------------------
#-- CASO DE SÃO ROQUE
arquivo <- "RAIOS/STARNET-Reprocessed/2016-06-06.dat"
grid <- list("lat" = c(-24, -23.2), "lon" = c(-47.75, -46.7)) #-- Limites da área de cobertura do caso
horarios <- c("17", "18", "19") #-- Selecionando período do caso

starnet <- read.table(arquivo, header = F) %>% select(1:9)
colnames(starnet) <- c("ano","mes","dia","hor","min","seg","sss","lat","lon")
starnet <- starnet %>% 
  unite(ano, mes, dia, hor, min, seg, col = "data", sep = "_") %>%
  select(data, lat, lon) %>%
  mutate(data = as.POSIXct(strptime(data, format = "%Y_%m_%d_%H_%M", "GMT"))) %>%
  filter(lat >= grid$lat[1] & lat <= grid$lat[2] & lon >= grid$lon[1] & lon <= grid$lon[2]) %>%
  filter(format(data, "%H") %in% horarios) %>%
  mutate(periodo = ceiling_date(data, "10 minutes", change_on_boundary = T)) %>%
  select(data) %>% 
  add_column("rede" = "STARNET")

arquivo <- "RAIOS/flash_CEMADEN_2016-06-06.txt"
grid <- list("lat" = c(-24, -23.2), "lon" = c(-47.75, -46.7)) #-- Limites da área de cobertura do caso
horarios <- c("17", "18", "19") #-- Selecionando período do caso

#-- Lendo/modificando o arquivo
brasildat <- read_table(arquivo) %>%
  separate("id  tipo", c("id", "tipo")) %>%
  unite(ano, mes, dia, hor, min, col = "data", sep = "_") %>%
  select(tipo, data, lat, lon, "pc(A)", "alt_ic(m)") %>%
  mutate(data = as.POSIXct(strptime(data, format = "%Y_%m_%d_%H_%M", "GMT"))) %>%
  filter(lat >= grid$lat[1] & lat <= grid$lat[2] & lon >= grid$lon[1] & lon <= grid$lon[2]) %>%
  filter(format(data, "%H") %in% horarios) %>%
  mutate(periodo = ceiling_date(data, "10 minutes", change_on_boundary = T)) %>%
  select(data) %>% 
  add_column("rede" = "BrasilDAT")

toplot <- rbind(starnet, brasildat)

#-- Plotando e salvando as imagens
plt <- ggplot(toplot) +
  scale_x_datetime(limits = c(as.POSIXct("2016-06-06 17:00:00", "GMT"), as.POSIXct("2016-06-06 20:00:00", "GMT")), labels = date_format("%Y-%m-%d\n%H:%M", "GMT")) +
  geom_freqpoly(binwidth = 60*5, aes(x = data, ..count.., color = rede)) +
  scale_color_manual(name = "Medido por", values = c("darkorange", "blue")) +
  labs(x = "Data (UTC)", y = "Raios a cada 5 min", title = "Strokes BrasilDAT e Sferics STARNET - Caso de São Roque")
ggsave("Figs/hist_saoroque.png", plot = plt, width = 6, height = 4, units = "in")
