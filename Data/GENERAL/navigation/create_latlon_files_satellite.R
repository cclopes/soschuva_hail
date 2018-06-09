#-- Cria arquivos de navegacao para o ForTraCC-Satelite

#-------------------------------------------------------------
#-- DADOS DE ENTRADA

#--- Onde irá gerar os arquivos
setwd("ForTraCC_Processing/navigation")

#--- Coordenadas do satelite
lat_above <- 12.52
lon_left <- -100
#--- Resolucao dos dados IR
res <- 0.04
nx <- 1714
ny <- 3876

#-- ARQUIVOS DE SAIDA
arq_lat <- "goes13.lat"
arq_lon <- "goes13.lon"
arq_bin <- "cos_g13.bin"

#-------------------------------------------------------------

#-------------------------------------------------------------
#-- CONSTANTES

#--- Selecionando apenas AMS?
lim_lat_above <- 1; lim_lat_below <- 1464
lim_lon_left <- 226; lim_lon_right <- 1851

#-------------------------------------------------------------

#-------------------------------------------------------------
#-- GERANDO MATRIZES
lat <- lon <- mask <- matrix(nrow = nx, ncol = ny)
#-------------------------------------------------------------

#-------------------------------------------------------------
#-- CALCULANDO
for(i in 1:nx){
  for(j in 1:ny){
    lat[i,j] <- (lat_above - (i-1)*res)*100
    lon[i,j] <- (lon_left  + (j-1)*res)*100
    # if(j < lim_lon_left | j > lim_lon_right){mask[i,j] <- 0}
    # else if(i < lim_lat_above | i > lim_lat_below){mask[i,j] <- 0}
    # else{mask[i,j] <- 1}
    mask[i,j] <- 1
  }
}

lat <- apply(lat, c(1,2), as.integer) #; lat <- lat[nx:1,]
lon <- apply(lon, c(1,2), as.integer)
mask <- apply(mask, c(1,2), as.integer)

#-------------------------------------------------------------

#-------------------------------------------------------------
#-- ESCREVENDO

con_lat <- file(arq_lat, "wb")
con_lon <- file(arq_lon, "wb")z
con_bin <- file(arq_bin, "wb")

for(i in 1:nx){
  for(j in 1:ny){
    writeBin(object = lat[i,j], con = con_lat, size = 2)
    writeBin(object = lon[i,j], con = con_lon, size = 2)
    writeBin(object = mask[i,j], con = con_bin, size = 2)
  }
}

close(con_lat); close(con_lon); close(con_bin)
