data.unsorted <- read.csv("result_list.csv")
data <- data.unsorted[order(data.unsorted$Budget),]

#trying to predict Out based on Budget

#center variables
#predictor variable
#budgetC <- data$Budget - mean(data$Budget)

#dipendent variable
#outC <- data$Out - mean(data$Out)

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

#loess model ( local regression )
#should put average value of out per budget
aggdata <- tapply(data$Out,data$Budget,mean) 

#compare models
summary(linearModel)
summary(quadraticModel)
#summary(cubicModel)
#summary(highPolyModel)
anova(linearModel,quadraticModel)

#graphs
plot(aggdata$Budget,aggdata$Out,type="p",lwd=3) 
grid()
#points(data$Budget, predict(linearModel), type="l", col="red", lwd=2)
#points(data$Budget, predict(quadraticModel), type="l", col="blue", lwd=2)
#points(data$Budget, predict(cubicModel), type="l", col="green", lwd=2)
#points(data$Budget, predict(highPolyModel), type="l", col="yellow", lwd=2)

