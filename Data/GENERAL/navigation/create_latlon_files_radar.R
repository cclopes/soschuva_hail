#-- Cria arquivos de navegação para o ForTraCC-Radar

#-------------------------------------------------------------
#-- DADOS DE ENTRADA

#--- Onde irá gerar os arquivos
setwd("Data/GENERAL/navigation/")

#--- Coordenadas do radar
lat_central <- -23.602 #-- FCTH: -23.60000
lon_central <- -47.0943 #-- FCTH: -45.97222
#--- Resolução dos dados de CAPPI
res <- 1 # [km]
nx <- 500
ny <- 500

#-- ARQUIVOS DE SAÍDA
arq_lat <- "nav_sr.lat"
arq_lon <- "nav_sr.lon"
arq_bin <- "cos_sr.bin"
#-------------------------------------------------------------

#-------------------------------------------------------------
#-- CONSTANTES
deg_to_rad <- pi/180
rad_to_deg <- 180/pi
dist_to_rad <- 1/6378400 # [m]
#-------------------------------------------------------------

#-------------------------------------------------------------
#-- GERANDO MATRIZES
x_axis <- c(seq(-250,-1, length.out = nx/2)*1e3, seq(1,250, length.out = nx/2)*1e3)
y_axis <- c(seq(-250,-1, length.out = ny/2)*1e3, seq(1,250, length.out = ny/2)*1e3)

X <- Y <- matrix(nrow = nx, ncol = ny)
lat <- lon <- matrix(nrow = nx, ncol = ny)
#-------------------------------------------------------------

#-------------------------------------------------------------
#-- CALCULANDO
for(i in 1:nx){
  for(j in 1:ny){

    X[i,j] <- x_axis[i]
    Y[i,j] <- y_axis[j]
    x0 <- X[i,j]
    y0 <- Y[i,j]
    x <- x0*dist_to_rad
    y <- y0*dist_to_rad

    c <- sqrt(x^2 + y^2)

    a1 <- cos(c) * sin(lat_central*deg_to_rad)
    b1 <- y * sin(c) * cos(lat_central*deg_to_rad)/c
    lat2 <- asin(a1 + b1) * rad_to_deg

    if(lat2 != 90 & lat2 != -90){
      a1 <- x * sin(c)
      b1 <- c * cos(lat_central*deg_to_rad) * cos(c) - y * sin(lat_central*deg_to_rad) * sin(c)
      lon2 <- (lon_central*deg_to_rad + atan(a1/b1)) * rad_to_deg
    } else if(lat2 == 90){
      lon2 <- (lon_central*deg_to_rad + atan(-x/y)) * rad_to_deg
    } else if(lat2 == -90){
      lon2 <- (lon_central*deg_to_rad + atan(x/y)) * rad_to_deg
    }

    lat[i,j] <- lat2
    lon[i,j] <- lon2
  }
}

lat <- t(lat)
lon <- t(lon)
mask <- matrix(as.integer(1), nrow = nx, ncol = ny)
#-------------------------------------------------------------

#-------------------------------------------------------------
#-- ESCREVENDO

con_lat <- file(arq_lat, "wb")
con_lon <- file(arq_lon, "wb")
con_bin <- file(arq_bin, "wb")

for(i in 1:nx){
  for(j in 1:ny){
    writeBin(object = lat[i,j], con = con_lat, size = 4)
    writeBin(object = lon[i,j], con = con_lon, size = 4)
    writeBin(object = mask[i,j], con = con_bin, size = 2)
  }
}

close(con_lat); close(con_lon); close(con_bin)
