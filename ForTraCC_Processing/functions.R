#------------------------------------------------------------------------------------------------
#-- Funções diversas
#------------------------------------------------------------------------------------------------

#-- Carregando pacotes necessários
require(maptools)

#-- FUNÇÕES
#-- Lê os dados de cappi e retorna matrizes corrigidas
le_cappi <- function(arquivo, linhas, colunas){
  cappi <- file(arquivo, "rb") %>% 
    readBin(., numeric(), size = 4, n = linhas*colunas) %>% 
    matrix(., nrow = linhas, ncol = colunas)
  closeAllConnections()
  cappi[cappi == -99 | cappi > 100] <- NA
  # cappi <- t(cappi[, colunas:1])
  return(cappi)
}

#-- Plota o cappi em um tempo
plota_cappi <- function(cappi, data, altura, radar){
  row.names(cappi) <- sort(lat_vetor, decreasing = T); colnames(cappi) <- lon_vetor
  cappi <- melt(cappi) %>% na.omit()
  
  plt <- ggplot(data = cappi, aes(x = Var2, y = Var1)) +
    scale_x_continuous(limits = lims$lon) + scale_y_continuous(limits = lims$lat) +
    geom_raster(aes(fill = value)) +
    geom_path(data = fortify(shape_states), aes(long, lat, group = group), inherit.aes = F, colour = "gray30") +
    geom_path(data = shape_SP, aes(long, lat), inherit.aes = F, colour = "gray30") +
    geom_path(data = shape_CMP, aes(long, lat), inherit.aes = F, colour = "gray30") +
    scale_fill_distiller(palette = "Spectral", limits = c(10,70)) +
    labs(title = paste(radar, " ", data, "Z  CAPPI ", altura, "km", sep = ""), x = "Longitude", y = "Latitude", fill = "Z (dBZ)") +
    theme(plot.title = element_text(hjust = 0.5))
  ggsave(plot = plt, filename = paste("figuras/cappis/", radar, "_", altura, "km_", data, ".png", sep = ""), width = 8)
}

#-- Faz o loop de imagens de todos os tempos
loop.animar <- function(arquivos) {
  lapply(1:length(arquivos), function(i) {
    plota_cappi(cappis_caso1[[i]], datas_caso1[i])
  })
}

#-- Abre e processa os shapefiles, mantendo os contornos de SP e CMP
cities <- readShapeLines("shapefiles/sao_paulo.shp") 
shape_SP <- coordinates(cities@lines[[578]])[[1]] %>% data.frame(long = .[,1], lat = .[,2])
shape_CMP <- coordinates(cities@lines[[147]])[[1]] %>% data.frame(long = .[,1], lat = .[,2])

shape_states <- readShapeLines("shapefiles/estadosl_2007.shp")
#rm(cities)
