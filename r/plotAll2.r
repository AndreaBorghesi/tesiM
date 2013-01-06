#plot a graph containing piecewise regression line for each incentive
	library(segmented)
	
	dataA.unsorted <- read.csv("../sim/results/result_listA_60M.csv")
	dataA <- dataA.unsorted[order(dataA.unsorted$Budget),]
	dataCI.unsorted <- read.csv("../sim/results/result_listCI_60M.csv")
	dataCI <- dataCI.unsorted[order(dataCI.unsorted$Budget),]
	dataR.unsorted <- read.csv("../sim/results/result_listR_60M.csv")
	dataR <- dataR.unsorted[order(dataR.unsorted$Budget),]
	dataG.unsorted <- read.csv("../sim/results/result_listG_60M.csv")
	dataG <- dataG.unsorted[order(dataG.unsorted$Budget),]
	
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
	
	#linear models
	glmA <- glm(Out ~ Budget,data=aggdataA)
	glmCI <- glm(Out ~ Budget,data=aggdataCI)
	glmR <- glm(Out ~ Budget,data=aggdataR)
	glmG <- glm(Out ~ Budget,data=aggdataG)
	
	#segmented regression
	segA <- segmented(glmA,seg.Z=~ Budget,psi=c(33))
	segCI <- segmented(glmCI,seg.Z=~ Budget,psi=c(3))
	segR <- segmented(glmR,seg.Z=~ Budget,psi=c(30))
	segG <- segmented(glmG,seg.Z=~ Budget,psi=c(12,30))
	
#	pdf(file="/media/sda4/tesi/immagini/grafici/incCompare/incentComparePiecewise.pdf")
#	par(mar=c(4.2, 4.0, 0.2, 0.2))

#graph
plot(aggdataA$Out ~ aggdataA$Budget,type="n",lwd=3,ylab="Produzione Energetica ( kW )", xlab="Budget Fotovoltaico ( milioni di Euro )",ylim=c(21000,27500),xlim=c(0,40),cex.lab=1.3) 
	grid()
	legend("topright", inset=.05, title="Tipo Incentivo", c("Asta","Conto Interessi","Rotazione","Garanzia"), fill=c("blue","red","green","yellow"),cex=1)
	
	points(aggdata$Budget, predict(segA), type="l", col="blue", lwd=2)
	points(aggdata$Budget, predict(segCI), type="l", col="red", lwd=2)
	points(aggdata$Budget, predict(segR), type="l", col="green", lwd=2)
	points(aggdata$Budget, predict(segG), type="l", col="yellow", lwd=2)

#	dev.off()
#	par(mar=c(5, 4, 4, 2) + 0.1)
