#plot a graph containing regression line for each incentive

	dataN.unsorted <- read.csv("result_listN.csv")
	dataN <- dataN.unsorted[order(dataN.unsorted$Budget),]
	dataA.unsorted <- read.csv("result_listA.csv")
	dataA <- dataA.unsorted[order(dataA.unsorted$Budget),]
	dataCI.unsorted <- read.csv("result_listCI.csv")
	dataCI <- dataCI.unsorted[order(dataCI.unsorted$Budget),]
	dataR.unsorted <- read.csv("result_listR.csv")
	dataR <- dataR.unsorted[order(dataR.unsorted$Budget),]
	dataG.unsorted <- read.csv("result_listG.csv")
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
	#linear model for N,A,R
	linearModelN <- lm(aggdataN$Out ~ aggdataN$Budget)
	linearModelA <- lm(aggdataA$Out ~ aggdataA$Budget)
	#linearModelCI <- lm(aggdataCI$Out ~ aggdataCI$Budget)
	linearModelR <- lm(aggdataR$Out ~ aggdataR$Budget)
	#linearModelG <- lm(aggdataG$Out ~ aggdataG$Budget)
	#LOESS model for CI
	loessModellCI <- loess(aggdataCI$Out ~ aggdataCI$Budget)
	my.count <- seq(from=0, to=30, by=1)
	predCI <- predict(loessModellCI,my.count,se=TRUE)
	#high polynomial for G
	highPolyModelG <- lm(aggdataG$Out ~ poly(aggdataG$Budget, 8, raw=TRUE))
	#predG <- predict(highPolyModelG,my.counT,se=)

	#compare models
	summary(linearModelN)
	summary(linearModelA)
	summary(loessModellCI)
	summary(linearModelR)
	summary(highPolyModelG)
	#anova(linearModelA,linearModelCI,linearModelR,linearModelG)

	#graphs
	# Start PDF device driver to save output to figure.pdf
	pdf(file="/media/sda4/tesi/immagini/grafici/incentCompare.pdf")
	# Trim off excess margin space (bottom, left, top, right)
	par(mar=c(4.2, 4.0, 0.2, 0.2))
	
	#plot(dataA$Budget,dataA$Out,type="n",lwd=3,ylab="Produzione Energetica ( MW )", xlab="Budget Fotovoltaico ( milioni di Euro )") 
	#grid()
	#points(dataN$Budget, predict(linearModelN), type="l", col="black", lwd=2)
	#points(dataA$Budget, predict(linearModelA), type="l", col="blue", lwd=2)
	#points(dataCI$Budget, predict(linearModelCI), type="l", col="red", lwd=2)
	#points(dataR$Budget, predict(linearModelR), type="l", col="green", lwd=2)
	#points(dataG$Budget, predict(linearModelG), type="l", col="yellow", lwd=2)

	plot(aggdataN$Out ~ aggdataN$Budget,type="n",lwd=3,ylab="Produzione Energetica ( kW )", xlab="Budget Fotovoltaico ( milioni di Euro )",ylim=c(21000,27500),xlim=c(0,30),cex.lab=0.9) 
	grid()
	#points(aggdataN$Budget, predict(linearModelN), type="l", col="black", lwd=2)
	points(aggdataA$Budget, predict(linearModelA), type="l", col="blue", lwd=2)
	lines(aggdataCI$Budget,predCI$fit, lty="solid", col="red", lwd=3)
	points(aggdataR$Budget, predict(linearModelR), type="l", col="green", lwd=2)
	points(aggdataG$Budget, predict(highPolyModelG), type="l", col="yellow", lwd=2)
	legend("topright", inset=.05, title="Tipo Incentivo", c("Asta","Conto Interessi","Rotazione","Garanzia"), fill=c("blue","red","green","yellow"),cex=0.9)
	
	# Turn off device driver (to flush output to PDF)
	dev.off()

	# Restore default margins
	par(mar=c(5, 4, 4, 2) + 0.1)
	
	

