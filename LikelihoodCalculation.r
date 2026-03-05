# This is the main function to calculate the combined likelihood values for each measurement and
# each treatment.

LikelihoodCalculation<-function(WD, OD, CropName, ParameterNames, RoundOfGLUE)
{

# Step 1. Calculate the likelihood values for the integrated measurements.
if(RoundOfGLUE==1)
{
eval(parse(text=paste('source ("',WD,'/IntegratedLikelihoodCalculation1.r")',sep = '')));
TreatmentNumber<-IntegratedLikelihoodCalculation1(WD, OD, CropName);
} else
{
eval(parse(text=paste('source ("',WD,'/IntegratedLikelihoodCalculation2.r")',sep = '')));
TreatmentNumber<-IntegratedLikelihoodCalculation2(WD, OD, CropName);
}
#Treatment number was returned from the function of integrated likelhood calculation.

# Step 2. Calculate the probability or normalized likelihood values for each treatment.
for (i in 1:TreatmentNumber)
{
eval(parse(text = paste('IntegratedLikelihoodTreatment',i,
'<-read.table("',OD,'/IntegratedLikelihoodTreatment_',RoundOfGLUE,'_',i,
'.txt",header=TRUE,comment.char="")',sep="")));
##Read the integrated likelihood values.

ColumnNumber<-dim(IntegratedLikelihoodTreatment1);

eval(parse(text = paste('ProbabilityTreatment',i,'<-IntegratedLikelihoodTreatment',i,sep="")));

for (j in 2:ColumnNumber[2])
{
eval(parse(text = paste('ProbabilityTreatment',i,'[,j]<-IntegratedLikelihoodTreatment',i,
'[,j]/sum(IntegratedLikelihoodTreatment',i,'[,j])',sep="")));
}
##Calculate the probability or normalized likelihood values for each observation.

}

# Step 3. Calculate the combined probability or normalized likelihood values for all treatments.
# Use log-space arithmetic to avoid numerical underflow when multiplying very small probabilities
# across many treatments (log-sum-exp).

LogCombinedProbability <- rep(0, nrow(ProbabilityTreatment1));

for (i in 1:TreatmentNumber)
{
  eval(parse(text = paste('currentProb <- ProbabilityTreatment',i,
  '[,"IntegratedCombinedLikelihood"]',sep="")));

  # Replace zeros with a very small number to avoid log(0) = -Inf
  currentProb[currentProb <= 0] <- .Machine$double.xmin;

  LogCombinedProbability <- LogCombinedProbability + log(currentProb);
  ##Summing log-probabilities is equivalent to multiplying probabilities, but avoids underflow.
}

# Normalize using log-sum-exp trick: subtract the max for numerical stability, then exponentiate.
LogMax <- max(LogCombinedProbability);
Probability <- exp(LogCombinedProbability - LogMax);
Probability <- Probability / sum(Probability);

#Calculate the normalized probability values for each of the random parameter sets.

# Step 4. Combine the generated random parameter sets and the final normalized probability together.
if(RoundOfGLUE==1)
{
eval(parse(text=paste('RandomParameterSets<-read.table("',OD,
'/RealRandomSets_1.txt", header=FALSE,comment.char="")',sep="")));

colnames(RandomParameterSets)<-ParameterNames;

RandomParameterSets<-cbind(RandomParameterSets,Probability);
#Read the generated radom parameter sets and assign names to them.

#library ('MASS');
#eval(parse(text=paste('write.matrix(RandomParameterSets,file ="',OD,
#'/RandomParameterSetsAndProbability_1.txt")',sep="")));

eval(parse(text=paste('write.table(as.matrix(RandomParameterSets), file ="',OD,
'/RandomParameterSetsAndProbability_1.txt", row.names = F, col.names = T, append = F)',sep="")));
#Save the random parameter sets with their probabilities in a file for future procedure.
} else
{
eval(parse(text=paste('RandomParameterSets<-read.table("',OD,
'/RealRandomSets_2.txt", header=FALSE, comment.char="")',sep="")));
colnames(RandomParameterSets)<-ParameterNames;

RandomParameterSets<-cbind(RandomParameterSets,Probability);
#Read the generated radom parameter sets and assign names to them.
#library ('MASS');
#eval(parse(text=paste('write.matrix(RandomParameterSets,file ="',OD,
#'/RandomParameterSetsAndProbability_2.txt")',sep="")));

eval(parse(text=paste('write.table(as.matrix(RandomParameterSets), file ="',OD,
'/RandomParameterSetsAndProbability_2.txt", row.names = F, col.names = T, append = F)',sep="")));
#Save the random parameter sets with their probabilities in a file for future procedure.
}

}




