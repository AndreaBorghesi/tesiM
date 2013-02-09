# relation between Budget and Out
library(segmented)
data.unsorted <- read.csv("../sim/results/result_listG_60M.csv")
data <- data.unsorted[order(data.unsorted$Budget),]

#trying to predict Out based on Budget
#aggdata has the average out per budget
aggdata <- tapply(data$Out,data$Budget,mean)
aggdata <- as.data.frame(aggdata)  
head(aggdata)
aggdata$Budget <- seq(from=0, to=(length(aggdata[,1]))-1, 1)
colnames(aggdata) <- c("Out", "Budget") 
head(aggdata)

#create the quadratic variable
budgetC2 <- data$Budget*data$Budget

#create the cubic variable
budgetC3 <- data$Budget*data$Budget*data$Budget

#creating models for the regression
#linear model
linearModel <- lm(data$Out ~ data$Budget)

#quadratic model
quadraticModel <- lm(data$Out ~ data$Budget+budgetC2)
#cubic model
#cubicModel <- lm(data$Out ~ data$Budget+budgetC2+budgetC3)
#higher degree poly
#highPolyModel <- lm(data$Out ~ poly(data$Budget, 8, raw=TRUE))

#models for aggregated data
linearModelAgg <- lm(aggdata$Out ~ aggdata$Budget)
quadraticModelAgg <- lm(aggdata$Out ~ poly(aggdata$Budget, 2, raw=TRUE))
cubicModelAgg <- lm(aggdata$Out ~ poly(aggdata$Budget, 3, raw=TRUE))
highPolyModelAgg <- lm(aggdata$Out ~ poly(aggdata$Budget, 10, raw=TRUE))

#loess model ( local regression )
loessModelAgg <- loess(aggdata$Out ~ aggdata$Budget,span=0.65)
my.count <- seq(from=0, to=(length(aggdata[,1]))-1, by=1)

#piecewise regression model
attach(aggdata)
linearModelAggP <- glm(Out ~ Budget)
#Fondo Asta
#seg <- segmented(linearModelAggP,seg.Z=~ Budget,psi=c(33))
#Conto Interessi
#seg <- segmented(linearModelAggP,seg.Z=~ Budget,psi=c(3))
#Fondo Rotazione
#seg <- segmented(linearModelAggP,seg.Z=~ Budget,psi=c(30))
#Fondo Garanzia
seg <- segmented(linearModelAggP,seg.Z=~ Budget,psi=c(12,30))


pred <- predict(loessModelAgg,my.count,se=TRUE)
predHP <- predict(highPolyModelAgg,se=TRUE)

 

#compare models
summary(linearModelAgg)
summary(quadraticModelAgg)
summary(cubicModelAgg)
summary(highPolyModelAgg)
summary(loessModelAgg)
anova(linearModelAgg,quadraticModelAgg,cubicModelAgg,highPolyModelAgg)

#	pdf(file="/media/sda4/tesi/immagini/grafici/ecms13/GuaranteeFundModels_with_piecewise.pdf")
#	par(mar=c(4.2, 4.0, 0.2, 0.2))	
	
#graphs
##par(mfrow=c(2,1),pch=1)
#plot(data$Out ~ data$Budget,type="n",lwd=3,ylab="Installed Power (kW)", xlab="Budget PV (Milions of Euros )",cex.lab=1.3,xlim=c(0,40))
#points(data$Out ~ data$Budget,col="blue4",pch=1)

plot(aggdata$Out ~ aggdata$Budget,type="p",lwd=3,ylab="Installed Power (kW)", xlab="Budget PV (Milions of Euros )",cex.lab=1.3,xlim=c(0,40)) 
grid(lwd=2)

#points(data$Budget, predict(linearModel), type="l", col="red", lwd=2)
#points(data$Budget, predict(quadraticModel), type="l", col="blue", lwd=2)
#points(data$Budget, predict(cubicModel), type="l", col="green", lwd=2)
#points(data$Budget, predict(highPolyModel), type="l", col="yellow", lwd=2)

#apply best regression: quadratic model for Asta and Rotazione,loess for Garanzia,polynomial higher degree for Conto Interessi
points(aggdata$Budget, predict(linearModelAgg),type="l", col="black", lwd=2,lty=3)
points(aggdata$Budget, predict(quadraticModelAgg),type="l", col="black", lwd=2,lty=2)
#points(aggdata$Budget, predict(cubicModelAgg), type="l", col="yellow", lwd=2)
points(aggdata$Budget, predict(highPolyModelAgg),type="l", col="black", lwd=2,lty=4)
points(aggdata$Budget, predict(seg), type="l", col="black", lwd=2,lty=6)
lines(aggdata$Budget,pred$fit, col="black", lwd=2,lty=1)
legend("bottomright", inset=.05, title="Regression Model", c("Linear Model","Quadratic Model","10th degree polynomial model","LOESS model","Piecewise Linear model"), lty=c(3,2,4,1,6),lwd=c(1.5,1.5,1.5,1.5,1.5,1.5), cex=1)

#lines(aggdata$Budget,pred$fit-1.96*pred$se.fit, lty="dashed", col="blue", lwd=1)
#lines(aggdata$Budget,pred$fit+1.96*pred$se.fit, lty="dashed", col="blue", lwd=1)

#lines(aggdata$Budget,predHP$fit-1.96*pred$se.fit, lty="dashed", col="yellow", lwd=1)
#lines(aggdata$Budget,predHP$fit+1.96*pred$se.fit, lty="dashed", col="yellow", lwd=1)



#	dev.off()
#	par(mar=c(5, 4, 4, 2) + 0.1)
