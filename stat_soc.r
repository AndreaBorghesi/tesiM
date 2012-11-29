# relation between Sensibilità and Out
data.unsorted <- read.csv("result_list.csv")
data <- data.unsorted[order(data.unsorted$Sens),]
aggdata <- tapply(data$Out,data$Sens,mean)
aggdata <- as.data.frame(aggdata) 
head(aggdata)
aggdata$Sens <- seq(from=0, to=20, 0.5)
colnames(aggdata) <- c("Out", "Sens") 
head(aggdata)

#creating models for the regression
linearModel <- lm(data$Out ~ data$Sens)
quadraticModel <- lm(data$Out ~ poly(data$Sens, 2, raw=TRUE))
cubicModel <- lm(data$Out ~ poly(data$Sens, 3, raw=TRUE))
highPolyModel <- lm(data$Out ~ poly(data$Sens, 8, raw=TRUE))

#models for aggregated data
linearModelAgg <- lm(aggdata$Out ~ aggdata$Sens)
quadraticModelAgg <- lm(aggdata$Out ~ poly(aggdata$Sens, 2, raw=TRUE))
cubicModelAgg <- lm(aggdata$Out ~ poly(aggdata$Sens, 3, raw=TRUE))
highPolyModelAgg <- lm(aggdata$Out ~ poly(aggdata$Sens, 8, raw=TRUE))
loessModelAgg <- loess(aggdata$Out ~ aggdata$Sens,span=0.6)
my.count <- seq(from=0, to=20, by=0.5)
pred <- predict(loessModelAgg,my.count,se=TRUE)

summary(linearModel)
summary(quadraticModel)
summary(cubicModel)
summary(highPolyModel)
anova(linearModel,quadraticModel,cubicModel,highPolyModel)

summary(linearModelAgg)
summary(quadraticModelAgg)
summary(cubicModelAgg)
summary(highPolyModelAgg)
summary(loessModelAgg)
anova(linearModelAgg,quadraticModelAgg,cubicModelAgg,highPolyModelAgg)

# Start PDF device driver to save output to figure.pdf
#	pdf(file="/media/sda4/tesi/immagini/grafici/graphSimR_R_socS.pdf")
#	par(mar=c(4.2, 4.0, 0.2, 0.2))

#graphs
#whole dataset
#plot(data$Out ~data$Sens,type="n",lwd=3,ylab="Produzione Energetica ( kW )", xlab="Sensibilità",cex.lab=0.9)
#grid(lwd=2)
#points(data$Out ~ data$Sens,col="black",pch=1)
#points(data$Sens, predict(linearModel), type="l", col="red", lwd=2)
#points(data$Sens, predict(quadraticModel), type="l", col="blue", lwd=2)
#points(data$Sens, predict(cubicModel), type="l", col="green", lwd=2)
#points(data$Sens, predict(highPolyModel), type="l", col="yellow", lwd=2)

#aggregated data
plot(aggdata$Out ~ aggdata$Sens,type="p",lwd=3,ylab="Produzione Energetica ( kW )", xlab="Sensibilità",xlim=c(0,20),cex.lab=0.9) 
grid(lwd=2)
#points(aggdata$Sens, predict(linearModelAgg), type="l", col="red", lwd=2)
#points(aggdata$Sens, predict(quadraticModelAgg), type="l", col="blue", lwd=2)
#points(aggdata$Sens, predict(cubicModelAgg), type="l", col="green", lwd=2)
#points(aggdata$Sens, predict(highPolyModelAgg), type="l", col="yellow", lwd=2)
lines(aggdata$Sens,pred$fit, lty="solid", col="darkred", lwd=2)

# Turn off device driver (to flush output to PDF)
#	dev.off()
#	par(mar=c(5, 4, 4, 2) + 0.1)


# relation between Raggio and Out
data.unsorted <- read.csv("result_list.csv")
data <- data.unsorted[order(data.unsorted$Raggio),]
aggdata <- tapply(data$Out,data$Raggio,mean)
aggdata <- as.data.frame(aggdata) 
head(aggdata)
aggdata$Raggio <- seq(from=1, to=40, 1)
colnames(aggdata) <- c("Out", "Raggio") 
head(aggdata)

#creating models for the regression
linearModel <- lm(data$Out ~ data$Raggio)
quadraticModel <- lm(data$Out ~ poly(data$Raggio, 2, raw=TRUE))
cubicModel <- lm(data$Out ~ poly(data$Raggio, 3, raw=TRUE))
highPolyModel <- lm(data$Out ~ poly(data$Raggio, 8, raw=TRUE))

#models for aggregated data
linearModelAgg <- lm(aggdata$Out ~ aggdata$Raggio)
quadraticModelAgg <- lm(aggdata$Out ~ poly(aggdata$Raggio, 2, raw=TRUE))
cubicModelAgg <- lm(aggdata$Out ~ poly(aggdata$Raggio, 3, raw=TRUE))
highPolyModelAgg <- lm(aggdata$Out ~ poly(aggdata$Raggio, 8, raw=TRUE))
loessModelAgg <- loess(aggdata$Out ~ aggdata$Raggio)
my.count <- seq(from=1, to=40, by=1)
pred <- predict(loessModelAgg,my.count,se=TRUE)

summary(linearModel)
summary(quadraticModel)
summary(cubicModel)
summary(highPolyModel)
anova(linearModel,quadraticModel,cubicModel,highPolyModel)

summary(linearModelAgg)
summary(quadraticModelAgg)
summary(cubicModelAgg)
summary(highPolyModelAgg)
summary(loessModelAgg)
anova(linearModelAgg,quadraticModelAgg,cubicModelAgg,highPolyModelAgg)

# Start PDF device driver to save output to figure.pdf
	pdf(file="/media/sda4/tesi/immagini/grafici/graphSimG_R_socR.pdf")
	par(mar=c(4.2, 4.0, 0.2, 0.2))

#graphs
#whole dataset
#plot(data$Out ~data$Raggio,type="n",lwd=3,ylab="Produzione Energetica ( kW )", xlab="Raggio",cex.lab=0.9)
#grid(lwd=2)
#points(data$Out ~ data$Raggio,col="black",pch=1)
#points(data$Raggio, predict(linearModel), type="l", col="red", lwd=2)
#points(data$Raggio, predict(quadraticModel), type="l", col="blue", lwd=2)
#points(data$Raggio, predict(cubicModel), type="l", col="green", lwd=2)
#points(data$Raggio, predict(highPolyModel), type="l", col="yellow", lwd=2)

#aggregated data
plot(aggdata$Out ~ aggdata$Raggio,type="p",lwd=3,ylab="Produzione Energetica ( kW )", xlab="Raggio",xlim=c(0,40),cex.lab=0.9) 
grid(lwd=2)
#points(aggdata$Raggio, predict(linearModelAgg), type="l", col="red", lwd=2)
#points(aggdata$Raggio, predict(quadraticModelAgg), type="l", col="blue", lwd=2)
#points(aggdata$Raggio, predict(cubicModelAgg), type="l", col="green", lwd=2)
#points(aggdata$Raggio, predict(highPolyModelAgg), type="l", col="yellow", lwd=2)
lines(aggdata$Raggio,pred$fit, lty="solid", col="darkred", lwd=2)

# Turn off device driver (to flush output to PDF)
	dev.off()
	par(mar=c(5, 4, 4, 2) + 0.1)

