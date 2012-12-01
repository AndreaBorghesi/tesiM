#relation between budget given and actual budget used

data.unsorted <- read.csv("result_list.csv")
data <- data.unsorted[order(data.unsorted$Budget),]

aggdata <- tapply(data$Spesa,data$Budget,mean)
aggdata <- as.data.frame(aggdata)  
head(aggdata)
aggdata$Budget <- seq(from=0, to=(length(aggdata[,1]))-1, 1)
colnames(aggdata) <- c("Spesa", "Budget") 
head(aggdata)

#models for aggregated data
linearModelAgg <- lm(aggdata$Spesa ~ aggdata$Budget)
quadraticModelAgg <- lm(aggdata$Spesa ~ poly(aggdata$Budget, 2, raw=TRUE))
cubicModelAgg <- lm(aggdata$Spesa ~ poly(aggdata$Budget, 3, raw=TRUE))
highPolyModelAgg <- lm(aggdata$Spesa ~ poly(aggdata$Budget, 10, raw=TRUE))
#loess model ( local regression )
loessModelAgg <- loess(aggdata$Spesa ~ aggdata$Budget,span=0.65)
my.count <- seq(from=0, to=(length(aggdata[,1]))-1, by=1)

pred <- predict(loessModelAgg,my.count,se=TRUE)
predHP <- predict(highPolyModelAgg,se=TRUE)

 
#compare models
summary(linearModelAgg)
summary(quadraticModelAgg)
summary(cubicModelAgg)
summary(highPolyModelAgg)
summary(loessModelAgg)
anova(linearModelAgg,quadraticModelAgg,cubicModelAgg,highPolyModelAgg)

# Start PDF device driver to save output to figure.pdf
#	pdf(file="/media/sda4/tesi/immagini/grafici/graphSimG_R_b.pdf")
#	par(mar=c(4.2, 4.0, 0.2, 0.2))

#graphs
#whole dataset
#plot(data$Spesa ~ data$Budget,type="n",lwd=3,ylab="Spesa Effettiva ( Euro )", xlab="Budget Fotovoltaico ( milioni di Euro )",cex.lab=0.9,xlim=c(0,40))
#points(data$Spesa ~ data$Budget,col="blue4",pch=1)

#regression
#high poly for A ( 10th degree)
#high poly for CI ( 10th degree)
#loess for R
#high poly for G ( 10th degree)

plot(aggdata$Spesa ~ aggdata$Budget,type="p",lwd=3,ylab="Spesa Effettiva ( milioni di Euro )", xlab="Budget Fotovoltaico ( milioni di Euro )",xlim=c(0,40)) 
grid(lwd=2)

points(aggdata$Budget, predict(linearModelAgg), type="l", col="red", lwd=2)
points(aggdata$Budget, predict(quadraticModelAgg), type="l", col="yellow", lwd=2)
points(aggdata$Budget, predict(cubicModelAgg), type="l", col="blue", lwd=2)
points(aggdata$Budget, predict(highPolyModelAgg), type="l", col="darkgreen", lwd=2)
lines(aggdata$Budget,pred$fit, lty="solid", col="darkred", lwd=2)

# Turn off device driver (to flush output to PDF)
#	dev.off()
#	par(mar=c(5, 4, 4, 2) + 0.1)
