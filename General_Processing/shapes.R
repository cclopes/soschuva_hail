#-- Lendo os "shapefiles" das fronteiras das cidades
library(maptools)
CITIES<-readShapeLines("shapefiles/sao_paulo.shp")
STATES<-readShapeLines("shapefiles/estadosl_2007.shp")
#yy<-readShapeLines("/data/BR-shapefiles/municip07.shp")
#getinfo.shape("/data/BR-shapefiles/municip07.shp")
#STATES@data for info
#coordinates(STATE@lines[[26]])[[1]] -> to access coordinates of slot 26, in this case STATE OF SAO PAULO
#coordinates(CITIES@lines[[578]])[[1]] -> to access coordinates of slot 578, in this case CITY OF SAO PAULO
temp <- coordinates(CITIES@lines[[578]])[[1]]; SP <- data.frame(x = temp[,1], y = temp[,2])
temp <- coordinates(CITIES@lines[[147]])[[1]]; CMP <- data.frame(x = temp[,1], y = temp[,2])
