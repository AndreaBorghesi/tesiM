#extracting a piecewise linear model from data
library(segmented)
data.unsorted <- read.csv("../sim/results/result_listG_60M.csv")
data <- data.unsorted[order(data.unsorted$Budget),]

#aggdata has the average out per budget
aggdata <- tapply(data$Out,data$Budget,mean)
aggdata <- as.data.frame(aggdata)  
head(aggdata)
aggdata$Budget <- seq(from=0, to=(length(aggdata[,1]))-1, 1)
colnames(aggdata) <- c("Out", "Budget") 
head(aggdata)
attach(aggdata)

linearModelAgg <- glm(Out ~ Budget)

#Fondo Asta
#seg <- segmented(linearModelAgg,seg.Z=~ Budget,psi=c(33))

#Conto Interessi
#seg <- segmented(linearModelAgg,seg.Z=~ Budget,psi=c(3))

#Fondo Rotazione
#seg <- segmented(linearModelAgg,seg.Z=~ Budget,psi=c(30))

#Fondo Garanzia
seg <- segmented(linearModelAgg,seg.Z=~ Budget,psi=c(12,30))

summary(seg)
slope(seg)


#pdf(file="/media/sda4/tesi/immagini/grafici/ecms13/GuaranteeFundPiecewiseLM.pdf")
#par(mar=c(4.2, 4.0, 0.2, 0.2))	

#Graph
plot(aggdata$Out ~ aggdata$Budget,type="p",lwd=3,ylab="Installed Power (kW)", xlab="Budget PV (Milions of Euros )",cex.lab=1.3,xlim=c(0,40)) 
grid(lwd=2)
points(aggdata$Budget, predict(seg), type="l", col="black", lwd=2)

#	dev.off()
#	par(mar=c(5, 4, 4, 2) + 0.1)
