# relation between Budget and Out

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

pred <- predict(loessModelAgg,my.count,se=TRUE)
predHP <- predict(highPolyModelAgg,se=TRUE)

 

#compare models
summary(linearModelAgg)
summary(quadraticModelAgg)
summary(cubicModelAgg)
summary(highPolyModelAgg)
summary(loessModelAgg)
anova(linearModelAgg,quadraticModelAgg,cubicModelAgg,highPolyModelAgg)

#	pdf(file="/media/sda4/tesi/immagini/grafici/ecms13/ECMS13_graphSimG_R.pdf")
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
#points(aggdata$Budget, predict(linearModelAgg), type="l", col="red", lwd=2)
#points(aggdata$Budget, predict(quadraticModelAgg), type="l", col="green", lwd=2)
#points(aggdata$Budget, predict(cubicModelAgg), type="l", col="yellow", lwd=2)
#points(aggdata$Budget, predict(highPolyModelAgg), type="l", col="blue", lwd=2)
#lines(aggdata$Budget,pred$fit, lty="solid", col="darkred", lwd=2)

#lines(aggdata$Budget,pred$fit-1.96*pred$se.fit, lty="dashed", col="blue", lwd=1)
#lines(aggdata$Budget,pred$fit+1.96*pred$se.fit, lty="dashed", col="blue", lwd=1)

#lines(aggdata$Budget,predHP$fit-1.96*pred$se.fit, lty="dashed", col="yellow", lwd=1)
#lines(aggdata$Budget,predHP$fit+1.96*pred$se.fit, lty="dashed", col="yellow", lwd=1)


#residuals analysis
#modelResidLinear=resid(linearModelAgg)
#modelResidQuadratic=resid(quadraticModelAgg)
#modelResidHighPoly=resid(highPolyModelAgg)
#modelResidLoess=resid(loessModelAgg)
#par(mfrow=c(2,2))

#plot(aggdata$Budget,modelResidLinear,type="p",lwd=3,ylab="Residuals", xlab="Budget Fotovoltaico ( milioni di Euro )",xlim=c(0,40),main="Linear Model") 
#abline(0, 0)
#plot(aggdata$Budget,modelResidQuadratic,type="p",lwd=3,ylab="Residuals", xlab="Budget Fotovoltaico ( milioni di Euro )",xlim=c(0,40),main="Quadratic Model") 
#abline(0, 0)
#plot(aggdata$Budget,modelResidHighPoly,type="p",lwd=3,ylab="Residuals", xlab="Budget Fotovoltaico ( milioni di Euro )",xlim=c(0,40),main="10th degree polynomial Model") 
#abline(0, 0)
#plot(aggdata$Budget,modelResidLoess,type="p",lwd=3,ylab="Residuals", xlab="Budget Fotovoltaico ( milioni di Euro )",xlim=c(0,40),main="LOESS Model") 
#abline(0, 0)

#plot(modelResidLinear,aggdata$Out,type="p",lwd=3,ylab="Residuals", xlab="Produzione Energetica ( kW )",main="Linear Model") 
#abline(0, 0)
#plot(modelResidQuadratic,aggdata$Out,type="p",lwd=3,ylab="Residuals", xlab="Produzione Energetica ( kW )",main="Quadratic Model") 
#abline(0, 0)
#plot(modelResidHighPoly,aggdata$Out,type="p",lwd=3,ylab="Residuals", xlab="Produzione Energetica ( kW )",main="10th degree polynomial Model") 
#abline(0, 0)
#plot(modelResidLoess,aggdata$Out,type="p",lwd=3,ylab="Residuals", xlab="Produzione Energetica ( kW )",main="LOESS Model") 
#abline(0, 0)

#normal probability plot
#lmstdres=rstandard(linearModelAgg)
#qmstdres=rstandard(quadraticModelAgg)
#cmstdres=rstandard(cubicModelAgg)
#hpmstdres=rstandard(highPolyModelAgg)
#qqnorm(lmstdres, ylab="Standardized Residuals", xlab="Normal Scores",main="Linear Model") 
#qqline(lmstdres)
#qqnorm(qmstdres, ylab="Standardized Residuals", xlab="Normal Scores",main="Quadratic Model") 
#qqline(qmstdres)
#qqnorm(cmstdres, ylab="Standardized Residuals", xlab="Normal Scores",main="Cubic Model") 
#qqline(cmstdres)
#qqnorm(hpmstdres, ylab="Standardized Residuals", xlab="Normal Scores",main="10th degree polynomial  Model") 
#qqline(hpmstdres)


#	dev.off()
#	par(mar=c(5, 4, 4, 2) + 0.1)








#plot a graph containing regression line for each incentive

	dataN.unsorted <- read.csv("../sim/results/result_listN_60M.csv")
	dataN <- dataN.unsorted[order(dataN.unsorted$Budget),]
	dataA.unsorted <- read.csv("../sim/results/result_listA_60M.csv")
	dataA <- dataA.unsorted[order(dataA.unsorted$Budget),]
	dataCI.unsorted <- read.csv("../sim/results/result_listCI_60M.csv")
	dataCI <- dataCI.unsorted[order(dataCI.unsorted$Budget),]
	dataR.unsorted <- read.csv("../sim/results/result_listR_60M.csv")
	dataR <- dataR.unsorted[order(dataR.unsorted$Budget),]
	dataG.unsorted <- read.csv("../sim/results/result_listG_60M.csv")
	dataG <- dataG.unsorted[order(dataG.unsorted$Budget),]

	aggdataN <- tapply(dataN$Out,dataN$Budget,mean)
	aggdataN <- as.data.frame(aggdataN)  
	head(aggdataN)
	aggdataN$Budget <- seq(from=0, to=(length(aggdataN[,1]))-1, 1)
	colnames(aggdataN) <- c("Out", "Budget") 
	head(aggdataN)
	aggdataA <- tapply(dataA$Out,dataA$Budget,mean)
	aggdataA <- as.data.frame(aggdataA)  
	head(aggdataA)
	aggdataA$Budget <- seq(from=0, to=(length(aggdataA[,1]))-1, 1)
	colnames(aggdataA) <- c("Out", "Budget") 
	head(aggdataA)
	aggdataCI <- tapply(dataCI$Out,dataCI$Budget,mean)
	aggdataCI <- as.data.frame(aggdataCI)  
	head(aggdataCI)
	aggdataCI$Budget <- seq(from=0, to=(length(aggdataCI[,1]))-1, 1)
	colnames(aggdataCI) <- c("Out", "Budget") 
	head(aggdataCI)
	aggdataR <- tapply(dataR$Out,dataR$Budget,mean)
	aggdataR <- as.data.frame(aggdataR)  
	head(aggdataR)
	aggdataR$Budget <- seq(from=0, to=(length(aggdataR[,1]))-1, 1)
	colnames(aggdataR) <- c("Out", "Budget") 
	head(aggdataR)
	aggdataG <- tapply(dataG$Out,dataG$Budget,mean)
	aggdataG <- as.data.frame(aggdataG)  
	head(aggdataG)
	aggdataG$Budget <- seq(from=0, to=(length(aggdataG[,1]))-1, 1)
	colnames(aggdataG) <- c("Out", "Budget") 
	head(aggdataG)

	#creating models for the regression
	#linear model for N
	#quadratic model for A,R
	linearModelN <- lm(aggdataN$Out ~ aggdataN$Budget)
	quadraticModelA <- lm(aggdataA$Out ~ poly(aggdataA$Budget, 2, raw=TRUE))
	quadraticModelR <- lm(aggdataR$Out ~ poly(aggdataR$Budget, 2, raw=TRUE))
	#linearModelCI <- lm(aggdataCI$Out ~ aggdataCI$Budget)
	#linearModelG <- lm(aggdataG$Out ~ aggdataG$Budget)
	#LOESS model for G
	loessModelG <- loess(aggdataG$Out ~ aggdataG$Budget,span=0.65)
	my.count <- seq(from=0, to=(length(aggdataG[,1]))-1, by=1)
	predG <- predict(loessModelG,my.count,se=TRUE)
	#higher polynomial for CI (10th degree)
	highPolyModelCI <- lm(aggdataCI$Out ~ poly(aggdataCI$Budget, 10, raw=TRUE))
	predCI <- predict(highPolyModelCI,se=TRUE)

	#compare models
	summary(linearModelN)
	summary(quadraticModelA)
	summary(loessModelG)
	summary(quadraticModelR)
	summary(highPolyModelCI)


	#graphs
	# Start PDF device driver to save output to figure.pdf
#	pdf(file="/media/sda4/tesi/immagini/grafici/ecms13/ECMS13incentCompare_e_noInc.pdf")
#	par(mar=c(4.2, 4.0, 0.2, 0.2))
	
	#plot(dataA$Budget,dataA$Out,type="n",lwd=3,ylab="Produzione Energetica ( MW )", xlab="Budget Fotovoltaico ( milioni di Euro )") 
	#grid()
	#points(dataN$Budget, predict(linearModelN), type="l", col="black", lwd=2)
	#points(dataA$Budget, predict(linearModelA), type="l", col="blue", lwd=2)
	#points(dataCI$Budget, predict(linearModelCI), type="l", col="red", lwd=2)
	#points(dataR$Budget, predict(linearModelR), type="l", col="green", lwd=2)
	#points(dataG$Budget, predict(linearModelG), type="l", col="yellow", lwd=2)

	plot(aggdataN$Out ~ aggdataN$Budget,type="n",lwd=3,ylab="Installed Power (kW)", xlab="Budget PV (Milions of Euros )",ylim=c(21000,27500),xlim=c(0,40),cex.lab=1.3) 
	grid()
	points(aggdataN$Budget, predict(linearModelN), type="l", col="black", lwd=2)
	points(aggdataA$Budget, predict(quadraticModelA), type="l", col="blue", lwd=2)
	lines(aggdataCI$Budget,predCI$fit, lty="solid", col="red", lwd=3)
	points(aggdataR$Budget, predict(quadraticModelR), type="l", col="green", lwd=2)
	points(aggdataG$Budget, predG$fit, type="l", col="yellow", lwd=2)
	legend("topright", inset=.05, title="Incentive type", c("None","Investment Grant","Interest Fuds","Fiscal Incentives","Guarantee Funds"), fill=c("black","blue","red","green","yellow"),cex=1)
	
	# Turn off device driver (to flush output to PDF)
#	dev.off()
#	par(mar=c(5, 4, 4, 2) + 0.1)
