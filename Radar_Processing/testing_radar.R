#------------------------------------------------------
#-- Script to test latlon matrices and cappi plots
#------------------------------------------------------

library(fields)

aux1 <- as.matrix(read.table("/home/camila/Downloads/rad.lat"))
aux2 <- as.matrix(read.table("/home/camila/Downloads/rad.lon"))
lat <- seq(min(aux1), max(aux1), length = 250)
lon <- seq(min(aux2), max(aux2), length = 250)

zz <- file("/media/camila/CCL_HD/SOS-CHUVA/Severe_Outbreak/RADAR/cappi/campinas/cappi_CZ_03000_20160605_0000.dat", "rb")
rad <- readBin(zz, numeric(), size=4, n=250*250)
rad <- matrix(rad, nrow=250, ncol=250)
rad[rad > 100] <- NA
rad <- rad[, 250:1]

close(zz)

image.plot(z = rad, zlim = c(10,70))
