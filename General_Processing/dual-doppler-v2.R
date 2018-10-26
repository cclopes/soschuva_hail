setwd("~/camila")
source("~/R-inicia/inicia.r")

#---------------------------------------------------------------------------------
#---------------------------------------------------------------------------------
#-- Reading city boundaries shape file
library(maptools)
CITIES<-readShapeLines("/Users/rachel/shapefiles/cidades_SP/sao_paulo.shp")
STATES<-readShapeLines("/Users/rachel/shapefiles/estadosl_2007.shp")
#yy<-readShapeLines("/Users/rachel/shapefiles/municip07.shp")
#getinfo.shape("/Users/rachel/shapefiles/municip07.shp")
#STATES@data for info
#coordinates(STATE@lines[[26]])[[1]] -> to access coordinates of slot 26, in this case STATE OF SAO PAULO
#coordinates(CITIES@lines[[578]])[[1]] -> to access coordinates of slot 578, in this case CITY OF SAO PAULO
bla<-coordinates(CITIES@lines[[578]])[[1]]
SAO <- data.frame(x=bla[,1],y=bla[,2])
bla<-coordinates(CITIES@lines[[240]])[[1]]
GUA<- data.frame(x=bla[,1],y=bla[,2])
bla<-coordinates(CITIES@lines[[147]])[[1]]
CMP<- data.frame(x=bla[,1],y=bla[,2])
bla<-coordinates(CITIES@lines[[251]])[[1]]
IND<- data.frame(x=bla[,1],y=bla[,2])
#---------------------------------------------------------------------------------
#---------------------------------------------------------------------------------
library(maps)
library(mapdata)#For the worldHires database
library(mapproj)#For the mapproject function
plotElipse <- function(x, y, r) {#Gary's function ;-)
  angles <- seq(0,2*pi,length.out=360)
  lines(r*cos(angles)+x,r*sin(angles)+y)
}
plotCircle <- function(LonDec, LatDec, Km, lty=2, col=NA, border=1, lwd=1) {#Corrected function
  #LatDec = latitude in decimal degrees of the center of the circle
  #LonDec = longitude in decimal degrees
  #Km = radius of the circle in kilometers
  ER <- 6371 #Mean Earth radius in kilometers. Change this to 3959 and you will have your function working in miles.
  AngDeg <- seq(1:360) #angles in degrees 
  Lat1Rad <- LatDec*(pi/180)#Latitude of the center of the circle in radians
  Lon1Rad <- LonDec*(pi/180)#Longitude of the center of the circle in radians
  AngRad <- AngDeg*(pi/180)#angles in radians
  Lat2Rad <-asin(sin(Lat1Rad)*cos(Km/ER)+cos(Lat1Rad)*sin(Km/ER)*cos(AngRad)) #Latitude of each point of the circle rearding to angle in radians
  Lon2Rad <- Lon1Rad+atan2(sin(AngRad)*sin(Km/ER)*cos(Lat1Rad),cos(Km/ER)-sin(Lat1Rad)*sin(Lat2Rad))#Longitude of each point of the circle rearding to angle in radians
  Lat2Deg <- Lat2Rad*(180/pi)#Latitude of each point of the circle rearding to angle in degrees (conversion of radians to degrees deg = rad*(180/pi) )
  Lon2Deg <- Lon2Rad*(180/pi)#Longitude of each point of the circle rearding to angle in degrees (conversion of radians to degrees deg = rad*(180/pi) )
  polygon(Lon2Deg,Lat2Deg,lty=lty,col=col, border=border, lwd=lwd)
}
#map("worldHires", region="belgium")#draw a map of Belgium (yes i am Belgian ;-)
#bruxelles <- mapproject(4.330,50.830)#coordinates of Bruxelles
#points(bruxelles,pch=20,col='blue',cex=2)#draw a blue dot for Bruxelles
#plotCircle(4.330,50.830,50)#Plot a dashed circle of 50 km arround Bruxelles 
#plotElipse(4.330,50.830,0.5)#Tries to plot a plain circle of 50 km arround Bruxelles, but drawn an ellipse


require(geosphere)

#-- radars coordinates
sr<-data.frame(x=-(47+(5+52/60)/60), y=-(23+(35+56/60)/60))
ct<-data.frame(x=-(45+(58+20/60)/60), y=-(23+(36+0/60)/60))
xp<-data.frame(x=-47.05641, y=-22.81405)

DualDopplerLobes<-function(radar1,radar2,deg,bearing1,bearing2)
{ 
  meio<-midPoint(radar1,radar2)
  deg<-deg*pi/180
  d<-distm(radar1, radar2, fun = distHaversine)/2
  r<-d/sin(deg)
  x<-sqrt(r^2 - d^2)
  p1<-destPoint(meio,bearing1,x)
  p2<-destPoint(meio,bearing2,x)
  out<-NULL
  out$x1=radar1[1]; out$y1=radar1[2];
  out$x2=radar2[1]; out$y2=radar2[2];
  out$d=d; out$r=r;
  out$mid.x=meio[1]; out$mid.y=meio[2];
  out$p1.x=p1[1];    out$p1.y=p1[2];
  out$p2.x=p2[1];    out$p2.y=p2[2]
  return(out)
}

XLIM<-c(-49,-45); YLIM<-c(-25,-22)

#-- 30 degree view
dd.sr.ct<-DualDopplerLobes(sr,ct,30,0,180)
dd.sr.xp<-DualDopplerLobes(sr,xp,30,90,270)

graphics.off()
png(filename = "duaDoppler-30deg.png",width = 550, height = 500)
par(mfrow=c(1,1),mar=c(4.5,4.8,3,1),oma=c(0,0,0,0))
plot(sr,pch=19,xlim=XLIM,ylim=YLIM, cex.axis=1.5,
    xlab=expression("longitude ("*degree*")"), ylab=expression("latitude ("*degree*")"), cex.lab=1.5, 
    main="Dual-Doppler lobes for pairs of Doppler radars\nwith 30 degree view angle difference", font.main=1, cex.main=1.5)
mapaas()
points(ct,pch=19)
plotCircle(dd.sr.ct$p1.x,dd.sr.ct$p1.y,dd.sr.ct$r*1e-3,border=4,lty=1,lwd=2)
plotCircle(dd.sr.ct$p2.x,dd.sr.ct$p2.y,dd.sr.ct$r*1e-3,border=4,lty=1,lwd=2)
points(xp,pch=19)
plotCircle(dd.sr.xp$p1.x,dd.sr.xp$p1.y,dd.sr.xp$r*1e-3,border=4,lty=2,lwd=2)
plotCircle(dd.sr.xp$p2.x,dd.sr.xp$p2.y,dd.sr.xp$r*1e-3,border=4,lty=2,lwd=2)
lines(CMP,col="gray66"); lines(SAO,col="gray66"); lines(IND,col="gray66")
text(sr,labels = "SR", font=2, pos=1)
text(ct,labels = "CT", font=2, pos=1)
text(xp,labels = "XP", font=2, pos=1)
legend(x=-49.2,y=-24.8,legend=c("São Roque and XPOL", "São Roque and FCTH"),lty = c(2,1), lwd=2, bg="white", col=4)
dev.off()

#-- 45 degree view
dd.sr.ct<-DualDopplerLobes(sr,ct,45,0,180)
dd.sr.xp<-DualDopplerLobes(sr,xp,45,90,270)

graphics.off()
png(filename = "duaDoppler-45deg.png",width = 550, height = 500)
par(mfrow=c(1,1),mar=c(4.5,4.8,3,1),oma=c(0,0,0,0))
plot(sr,pch=19,xlim=XLIM,ylim=YLIM, cex.axis=1.5,
     xlab=expression("longitude ("*degree*")"), ylab=expression("latitude ("*degree*")"), cex.lab=1.5, 
     main="Dual-Doppler lobes for pairs of Doppler radars\nwith 45 degree view angle difference", font.main=1, cex.main=1.5)
mapaas()
points(ct,pch=19)
plotCircle(dd.sr.ct$p1.x,dd.sr.ct$p1.y,dd.sr.ct$r*1e-3,border=2,lty=1,lwd=2)
plotCircle(dd.sr.ct$p2.x,dd.sr.ct$p2.y,dd.sr.ct$r*1e-3,border=2,lty=1,lwd=2)
points(xp,pch=19)
plotCircle(dd.sr.xp$p1.x,dd.sr.xp$p1.y,dd.sr.xp$r*1e-3,border=2,lty=2,lwd=2)
plotCircle(dd.sr.xp$p2.x,dd.sr.xp$p2.y,dd.sr.xp$r*1e-3,border=2,lty=2,lwd=2)
lines(CMP,col="gray66"); lines(SAO,col="gray66"); lines(IND,col="gray66")
text(sr,labels = "SR", font=2, pos=1)
text(ct,labels = "CT", font=2, pos=1)
text(xp,labels = "XP", font=2, pos=1)
legend(x=-49.2,y=-24.8,legend=c("São Roque and XPOL", "São Roque and FCTH"),lty = c(2,1), lwd=2, bg="white", col=2)
dev.off()

#-- 30 and 45 degree views together

graphics.off()
png(filename = "duaDoppler-all.png",width = 550, height = 500)
par(mfrow=c(1,1),mar=c(4.5,4.8,3,1),oma=c(0,0,0,0))
dd.sr.ct<-DualDopplerLobes(sr,ct,30,0,180)
dd.sr.xp<-DualDopplerLobes(sr,xp,30,90,270)
plot(sr,pch=19,xlim=XLIM,ylim=YLIM, cex.axis=1.5,
     xlab=expression("longitude ("*degree*")"), ylab=expression("latitude ("*degree*")"), cex.lab=1.5, 
     main="Dual-Doppler lobes for pairs of Doppler radars", font.main=1, cex.main=1.5)
mapaas()
points(ct,pch=19)
plotCircle(dd.sr.ct$p1.x,dd.sr.ct$p1.y,dd.sr.ct$r*1e-3,border=4,lty=1,lwd=2)
plotCircle(dd.sr.ct$p2.x,dd.sr.ct$p2.y,dd.sr.ct$r*1e-3,border=4,lty=1,lwd=2)
points(xp,pch=19)
plotCircle(dd.sr.xp$p1.x,dd.sr.xp$p1.y,dd.sr.xp$r*1e-3,border=4,lty=2,lwd=2)
plotCircle(dd.sr.xp$p2.x,dd.sr.xp$p2.y,dd.sr.xp$r*1e-3,border=4,lty=2,lwd=2)

dd.sr.ct<-DualDopplerLobes(sr,ct,45,0,180)
dd.sr.xp<-DualDopplerLobes(sr,xp,45,90,270)
plotCircle(dd.sr.ct$p1.x,dd.sr.ct$p1.y,dd.sr.ct$r*1e-3,border=2,lty=1,lwd=2)
plotCircle(dd.sr.ct$p2.x,dd.sr.ct$p2.y,dd.sr.ct$r*1e-3,border=2,lty=1,lwd=2)
plotCircle(dd.sr.xp$p1.x,dd.sr.xp$p1.y,dd.sr.xp$r*1e-3,border=2,lty=2,lwd=2)
plotCircle(dd.sr.xp$p2.x,dd.sr.xp$p2.y,dd.sr.xp$r*1e-3,border=2,lty=2,lwd=2)

lines(CMP,col="gray66"); lines(SAO,col="gray66"); lines(IND,col="gray66")
text(sr,labels = "SR", font=2, pos=1)
text(ct,labels = "CT", font=2, pos=1)
text(xp,labels = "XP", font=2, pos=1)
legend(x=-49.15,y=-24.5,legend=c("SR and XP (30deg)", "SR and CT  (30deg)", "SR and XP (45deg)", "SR and CT  (45deg)"),lty = c(2,1,2,1), lwd=2, bg="white", col=c(4,4,2,2))
dev.off()


#-- 30 e 45 degree views together by pair of radars

dist.sr.ct<-distm(sr, ct, fun = distHaversine)*1e-3
dist.sr.xp<-distm(sr, xp, fun = distHaversine)*1e-3
dist.ct.xp<-distm(ct, xp, fun = distHaversine)*1e-3

graphics.off()
png(filename = "duaDoppler-SR_CT.png",width = 550, height = 500)
par(mfrow=c(1,1),mar=c(4.5,4.8,3,1),oma=c(0,0,0,0))
plot(sr,pch=19,xlim=XLIM,ylim=YLIM, cex.axis=1.5,
     xlab=expression("longitude ("*degree*")"), ylab=expression("latitude ("*degree*")"), cex.lab=1.5, 
     main="Dual-Doppler lobes for SR and CT pair of radars", font.main=1, cex.main=1.5)
mapaas()
points(ct,pch=19)
dd.sr.ct<-DualDopplerLobes(sr,ct,30,0,180)
plotCircle(dd.sr.ct$p1.x,dd.sr.ct$p1.y,dd.sr.ct$r*1e-3,border=4,lty=1,lwd=2)
plotCircle(dd.sr.ct$p2.x,dd.sr.ct$p2.y,dd.sr.ct$r*1e-3,border=4,lty=1,lwd=2)
dd.sr.ct<-DualDopplerLobes(sr,ct,45,0,180)
plotCircle(dd.sr.ct$p1.x,dd.sr.ct$p1.y,dd.sr.ct$r*1e-3,border=2,lty=1,lwd=2)
plotCircle(dd.sr.ct$p2.x,dd.sr.ct$p2.y,dd.sr.ct$r*1e-3,border=2,lty=1,lwd=2)
lines(x=c(sr$x,ct$x), y=c(sr$y,ct$y), lty=3, lwd=2)
d<-midPoint(sr,ct)
text(x=d[1],y=d[2],labels = sprintf("%3.0fkm",dist.sr.ct), font=1, pos=1)
lines(CMP,col="gray66"); lines(SAO,col="gray66"); lines(IND,col="gray66")
text(sr,labels = "SR", font=2, pos=1)
text(ct,labels = "CT", font=2, pos=1)
legend(x=-49.2,y=-24.8,legend=c("30 degrees", "45 degrees"),lty = 1, lwd=2, bg="white", col=c(4,2))
dev.off()

graphics.off()
png(filename = "duaDoppler-SR_XP.png",width = 550, height = 500)
par(mfrow=c(1,1),mar=c(4.5,4.8,3,1),oma=c(0,0,0,0))
plot(sr,pch=19,xlim=XLIM,ylim=YLIM, cex.axis=1.5,
     xlab=expression("longitude ("*degree*")"), ylab=expression("latitude ("*degree*")"), cex.lab=1.5, 
     main="Dual-Doppler lobes for SR and XP pair of radars", font.main=1, cex.main=1.5)
mapaas()
points(ct,pch=19)
dd.sr.xp<-DualDopplerLobes(sr,xp,30,90,270)
plotCircle(dd.sr.xp$p1.x,dd.sr.xp$p1.y,dd.sr.xp$r*1e-3,border=4,lty=1,lwd=2)
plotCircle(dd.sr.xp$p2.x,dd.sr.xp$p2.y,dd.sr.xp$r*1e-3,border=4,lty=1,lwd=2)
dd.sr.xp<-DualDopplerLobes(sr,xp,45,90,270)
plotCircle(dd.sr.xp$p1.x,dd.sr.xp$p1.y,dd.sr.xp$r*1e-3,border=2,lty=1,lwd=2)
plotCircle(dd.sr.xp$p2.x,dd.sr.xp$p2.y,dd.sr.xp$r*1e-3,border=2,lty=1,lwd=2)
lines(x=c(sr$x,xp$x), y=c(sr$y,xp$y), lty=3, lwd=2)
d<-midPoint(sr,xp)
text(x=d[1],y=d[2],labels = sprintf("%3.0fkm",dist.sr.xp), font=1, pos=1, srt=90)
lines(CMP,col="gray66"); lines(SAO,col="gray66"); lines(IND,col="gray66")
text(sr,labels = "SR", font=2, pos=1)
text(xp,labels = "XP", font=2, pos=3)
legend(x=-49.2,y=-24.8,legend=c("30 degrees", "45 degrees"),lty = 1, lwd=2, bg="white", col=c(4,2))
dev.off()



