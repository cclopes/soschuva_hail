#-------------------------------------------------------------------------------
#-- Reading CAPPIS of the hailpad cases and plotting
#-------------------------------------------------------------------------------

#-- Carregando pacotes e scripts necessários
require(fields)
require(tidyverse)
require(animation)
require(reshape2)
source("General_Processing/functions.R")

#-- Parâmetros de entrada
#---- 500 x 500 pontos
#---- 1 x 1 x 1 km
lins <- 500
cols <- 500
lims <- data.frame(lon = c(-48.5, -43.5), lat = c(-25.5, -21))

#-- Gerando variáveis de navegação a partir dos binários
lat <- file("navigation/nav_rd.lat", "rb") %>% #-- FCTH
# lat <- file("navigation/nav_sr.lat", "rb") %>% #-- SR
  readBin(., numeric(), size = 4, n = lins * cols) %>%
  matrix(., nrow = lins, ncol = cols)
lon <- file("navigation/nav_rd.lon", "rb") %>% #-- FCTH
  # lon <- file("navigation/nav_sr.lon", "rb") %>% #-- SR
  readBin(., numeric(), size = 4, n = lins * cols) %>%
  matrix(., nrow = lins, ncol = cols)
closeAllConnections()

lat_vetor <- seq(min(lat, na.rm = T), max(lat, na.rm = T), length = lins)
lon_vetor <- seq(min(lon, na.rm = T), max(lon, na.rm = T), length = lins)

#-- Criando variável com nomes das listas de arquivos
listas_arqs <- paste("data_files/cth_level2_0", seq(2, 7), "000", sep = "") #-- FCTH
# listas_arqs <- paste("data_files/sr_level2_0", seq(2,5), "000", sep = "")  #-- SR

for (c in listas_arqs) {
  nomes_arqs <- read.table(c) %>%
    unlist() %>%
    as.vector()

  pmap(
    list(
      #-- Lendo os dados que vão ser plotados
      map(nomes_arqs, ~ le_cappi(.x, lins, cols)), 
      #-- Vetores de latitude e longitude
      lat_vetor, lon_vetor, 
      #-- Data que aparecerá no título e nome do arquivo
      str_extract(nomes_arqs, "201\\d\\d\\d\\d\\d_\\d\\d\\d\\d"), 
      #-- Altura que aparecerá no título e nome do arquivo
      str_extract(c, "[0-1][1-9]"), 
      #-- Nome do radar
      str_extract(nomes_arqs, "(?<!RADAR)\\w{2,3}(?=/level)")
    ), 
    #-- Plotando e salvando as imagens em .png
    ~ plota_cappi(..1, ..2, ..3, ..4)
  ) 
}

#-- Plotando (gif com todas as imagens)
# saveGIF(loop.animar(nomes_arqs_caso1),
#         movie.name = "figures/cappis/case1_6km_20161225.gif", 
#         interval = 0.5, ani.width = 550, ani.height = 500)
