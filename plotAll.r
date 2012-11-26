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

#creating models for the regression
#linear model
linearModelN <- lm(dataN$Out ~ dataN$Budget)
linearModelA <- lm(dataA$Out ~ dataA$Budget)
linearModelCI <- lm(dataCI$Out ~ dataCI$Budget)
linearModelR <- lm(dataR$Out ~ dataR$Budget)
linearModelG <- lm(dataG$Out ~ dataG$Budget)

#compare models
summary(linearModelN)
summary(linearModelA)
summary(linearModelCI)
summary(linearModelR)
summary(linearModelG)
anova(linearModelA,linearModelCI,linearModelR,linearModelG)

#graphs
plot(dataA$Budget,dataA$Out,type="n",lwd=3,ylab="Produzione Energetica ( MW )", xlab="Budget Fotovoltaico ( milioni di Euro )") 
grid()
points(dataN$Budget, predict(linearModelN), type="l", col="black", lwd=2)
points(dataA$Budget, predict(linearModelA), type="l", col="blue", lwd=2)
points(dataCI$Budget, predict(linearModelCI), type="l", col="red", lwd=2)
points(dataR$Budget, predict(linearModelR), type="l", col="green", lwd=2)
points(dataG$Budget, predict(linearModelG), type="l", col="yellow", lwd=2)

