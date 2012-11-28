# relation between Budget and Out

data.unsorted <- read.csv("result_list.csv")
data <- data.unsorted[order(data.unsorted$Budget),]

#trying to predict Out based on Budget

#center variables
#predictor variable
#budgetC <- data$Budget - mean(data$Budget)
#dipendent variable
#outC <- data$Out - mean(data$Out)

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
highPolyModelAgg <- lm(aggdata$Out ~ poly(aggdata$Budget, 8, raw=TRUE))

#loess model ( local regression )
loessModelAgg <- loess(aggdata$Out ~ aggdata$Budget)
my.count <- seq(from=0, to=30, by=1)

pred <- predict(loessModelAgg,my.count,se=TRUE)
#pred <- predict(highPolyModelAgg,se=TRUE)

 

#compare models
summary(linearModelAgg)
summary(quadraticModelAgg)
summary(cubicModelAgg)
summary(highPolyModelAgg)
summary(loessModelAgg)
anova(linearModelAgg,quadraticModelAgg,cubicModelAgg,highPolyModelAgg)

# Start PDF device driver to save output to figure.pdf
#	pdf(file="/media/sda4/tesi/immagini/grafici/graphSimR_R.pdf")
	# Trim off excess margin space (bottom, left, top, right)
#	par(mar=c(4.2, 4.0, 0.2, 0.2))
	
#graphs
#par(mfrow=c(2,1),pch=1)
plot(data$Out ~ data$Budget,type="n",lwd=3,ylab="Produzione Energetica ( kW )", xlab="Budget Fotovoltaico ( milioni di Euro )",cex.lab=0.9)
points(data$Out ~ data$Budget,col="blue4",pch=1)

#plot(aggdata$Out ~ aggdata$Budget,type="p",lwd=3,ylab="Produzione Energetica ( kW )", xlab="Budget Fotovoltaico ( milioni di Euro )",xlim=c(0,30),cex.lab=0.9) 
grid(lwd=2)

#points(data$Budget, predict(linearModel), type="l", col="red", lwd=2)
#points(data$Budget, predict(quadraticModel), type="l", col="blue", lwd=2)
#points(data$Budget, predict(cubicModel), type="l", col="green", lwd=2)
#points(data$Budget, predict(highPolyModel), type="l", col="yellow", lwd=2)

#apply best regression: linear model for Asta and Rotazione,polynomial higher degree for Garanzia,loess for Conto Interessi
#points(aggdata$Budget, predict(linearModelAgg), type="l", col="red", lwd=2)
#points(aggdata$Budget, predict(quadraticModelAgg), type="l", col="red", lwd=2)
#points(aggdata$Budget, predict(cubicModelAgg), type="l", col="green", lwd=2)
#points(aggdata$Budget, predict(highPolyModelAgg), type="l", col="red", lwd=2)

#lines(aggdata$Budget,pred$fit, lty="solid", col="red", lwd=2)
#lines(aggdata$Budget,pred$fit-1.96*pred$se.fit, lty="dashed", col="blue", lwd=1)
#lines(aggdata$Budget,pred$fit+1.96*pred$se.fit, lty="dashed", col="blue", lwd=1)

# Turn off device driver (to flush output to PDF)
#	dev.off()

	# Restore default margins
#	par(mar=c(5, 4, 4, 2) + 0.1)
