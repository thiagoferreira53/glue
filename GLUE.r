####The main function to automatically realize the GLUE procedure for parameter estimation for DSSAT model.####

library(rjson)

#################Step 1: Get the fundamental information for GLUE procedure.##############
ncol(finf <- file.info(dir()))# at least six
## Not run: finf # the whole list
## Those that are more than 100 days old :
finf[difftime(Sys.time(), finf[,"mtime"], units="days") > 100 , 1:4]

file.info("no-such-file-exists")

GLUE_defs <- fromJSON(file = "/Users/thiagoferreira53/Projects/GLUE/GLUE_Defs.json")

## (1) Get the name of the batch file that was generated with GenSelect.
#CultivarBatchFile<-"Prisma_GC_Avg.MZC"; 
CultivarBatchFile<-GLUE_defs$CultivarBatchFile;
##Which batch file generated by GenSelect should be used? This information should be given to GLUE when 
##model users decide to use this program.

## (2) Get the information about the working directory of GLUE program (WD), 
#model output storage directory (OD) and DSSAT (DSSATD).
WorkDirectory<-getwd();

Cores <- GLUE_defs$Cores

#WorkDirectorySubstrings<-unlist(strsplit(WorkDirectory,"DSSAT48"));

#DSSATD<-paste(WorkDirectorySubstrings[1],"DSSAT48", sep=""); #Get the working directory of DSSAT.

#GLUED<-"/Tools/GLUE";#This one is the postion of GLUE under DSSAT and fixed by model developer.
#OutputD<-"/GLWork"; #This one is the position of DSSAT output and fixed by model developer.
#GenotypeD<-"/Genotype"; #This one is the position of Genotype file.
 
#WD<-paste(DSSATD, GLUED, sep="");
#OD<-paste(DSSATD, OutputD, sep="");
#GD<-paste(DSSATD, GenotypeD, sep="");

WD<- GLUE_defs$GLUED
OD<- GLUE_defs$OutputD
GD<- GLUE_defs$GenotypeD
DSSATD <- paste0(WorkDirectory,GLUE_defs$DSSATD)

eval(parse(text=paste("ModelRunIndicatorPath='",OD,"/ModelRunIndicator.txt'",sep = ''))); 
glueWarningLogFile <- file.path(OD, "GlueWarning.txt");
glueExcludedModelListFile <- file.path(WD, "GlueExcludedModels.csv");
##Path of the model run indicator file, which indicates which component of GLUE is finished so far.




##WD represents working directory. This is very important, because it is used to tell the main funtion where
##the sub-functions are. DSSATD represents the DSSAT directory. GLUED represents the GLUE directory.
##OutputD represents the output directory under DSSAT, while OD means the final output directory.
##GD ir the directory of genotype files in DSSAT.

## (3) Read the number of model runs and GLUE control flag from the "Simulation Control" file.
#library(xlsReadWrite);
#eval(parse(text = paste("SimulationControl<-read.xls('",WD,
#"/SimulationControl.xls',sheet = 'Sheet 1', rowNames = T, colNames=T)",sep = '')));

eval(parse(text = paste("SimulationControl<-read.csv('",WD,
"/SimulationControl.csv', header=T)",sep = '')));
newRownames <- SimulationControl[ , 1];
rownames(SimulationControl) <- newRownames;

#NumberOfModelRun<-as.numeric(SimulationControl["NumberOfModelRun", "Value"]);
NumberOfModelRun <- as.numeric(GLUE_defs$NumberOfModelRun)
write(c("The number of model runs = ",NumberOfModelRun), file = ModelRunIndicatorPath, ncolumns=2, append = F);

#print(NumberOfModelRun);
#Read the number of model running.
#GLUEFlag<-as.numeric(SimulationControl[2,"Value"]);
GLUEFlag <- as.numeric(GLUE_defs$GLUEFlag)

#Set the flag for whole GLUE procedure. If GLUEFlag==1, it means coefficients relative both to phenology and
#growth will be evaluated; GLUEFlag==2, only phenology will be evaluated; GLUEFlag==3, only growth will be evaluated.

## (4) Get the number of round of GLUE.
if (GLUEFlag==1)
{
StartRoundOfGLUE=1
TotalRoundOfGLUE=2;
write("GLUE will run for both phenology and growth.", file = ModelRunIndicatorPath, append = T); 
} else if (GLUEFlag==2)
{
StartRoundOfGLUE=1
TotalRoundOfGLUE=1;
write("GLUE will run for phenology only.", file = ModelRunIndicatorPath, append = T); 
} else
{
StartRoundOfGLUE=2
TotalRoundOfGLUE=2;
write("GLUE will run for growth only.", file = ModelRunIndicatorPath, append = T); 
}

#write("Which round of GLUE to be done is known...", file = ModelRunIndicatorPath, append = T); 
#In default, totally two rounds of GLUE will be conducted. In the first round, only the genetic coefficients (P1, P2, p5, PHINT)
#that can influence phenology such as anthesis date and maturity date will be estimated, while other parameters (G2, G3)
#will be fixed at their mean values derived from DSSAT database.In the second round of GLUE, G2 and G3 will be estimated based on the likelihood values derived from growth outputs
#such LAIX, HWAM, CWAM. Finally, the two partial parameter sets will be conbined together to give us a final optimal parameter set.

#If only estimated phenology dates, then only the first round GLUE will be conducted; if only estimated growth, then only the
#second round GLUE will be conducted.

## (5) Get the  name of the genotype file of current crop and the name of current model
eval(parse(text=paste("BatchFile<-readLines('",OD,"/",CultivarBatchFile,"',n=-1)",sep = '')));
CropNameAddress<-grep('BATCH', BatchFile);
CropNameStart<-18; #
CropNameEnd<-19; #
CropName<-substr(BatchFile[CropNameAddress], CropNameStart, CropNameEnd);
write(c("Crop =",CropName), file = ModelRunIndicatorPath, ncolumns=2, append = T);
#Get the crop name in this model run.

CultivarIDStart<-20; #
CultivarIDEnd<-25; #Get the Cultivar ID number such as, "IB0001";

CultivarNameStart<-20;
CultivarNameEnd<-nchar(BatchFile[CropNameAddress]); #Get the Cultivar name such as, "ZA0002 Prisma GC Avg";

CultivarID<-substr(BatchFile[CropNameAddress], CultivarIDStart, CultivarIDEnd);
CultivarName<-substr(BatchFile[CropNameAddress], CultivarNameStart, CultivarNameEnd);
write(c("Cultivar ID =",CultivarName), file = ModelRunIndicatorPath, ncolumns=2, append = T);
#Get the cultivar ID and name.
## "$BATCH(CULTIVAR):MZIM0003 APPOLO" is an example to show how to get the crop name and cultivar ID. 
##From this line, we can get to know the crop name "MZ" (18-19), the cultivar ID "IM0003" (20-25).

# Model name
DSSATPro = readLines(paste0(DSSATD,"/DSSATPRO.L48"))
LineNo = grep(paste0("M",CropName),DSSATPro)
LineSplit = unlist(strsplit(DSSATPro[LineNo]," "))
ModelSelect = LineSplit[length(LineSplit)]
write(c("Model Name =",ModelSelect), file = ModelRunIndicatorPath, ncolumns=2, append = T);

# Check is model is in the exclusion list
eval(parse(text=paste("excludedFile<-readLines('",glueExcludedModelListFile,"',n=-1)",sep = '')));
excludedFile.df <- read.table(textConnection(excludedFile[-c(1,2)]),header=F, sep=",")
colnames(excludedFile.df) <- unlist(strsplit(sub("@", "", excludedFile[2]), split = ","))
if (CropName %in% excludedFile.df[which(substr(ModelSelect,1,5) == excludedFile.df[,"MODEL"]),][,"CROP"]) {
  errorMsg <- paste0("Currently model ", ModelSelect, " for ", CropName, " is not supported by GLUE, please modify the DSSATPRO.L48 file to change to other model for crop ", CropName, ".")
  write(errorMsg, file = glueWarningLogFile, ncolumns=1, append = T);
  # stop(errorMsg)
  q()
}

# Get the genotype file name
GenotypeFilePath<-GD;
CurrentGenotypeFile<-paste0(GD, "/",CropName,substr(ModelSelect,3,8),".CUL")

#Get the names of the genotype file template that will be used, which shoud start with crop name such as "MZ",
#and end with extension name ".CUL". Since there are two genotype files starting with "MZ" and ending with
#".CUL" under the "Genotype" folder of DSSAT, it was set as "MZCER048.CUL" as default value.

StringLength<-nchar(CurrentGenotypeFile);
GenotypeFileNameStartPosition<-(StringLength-(8+4)+1);
GenotypeFileNameEndPosition<-StringLength-4;
#Where 4 is the length of character ".CUL", 
#while 8 is the length of cultivar file name, such as "MZCER048".

GenotypeFileName<-substr(CurrentGenotypeFile, GenotypeFileNameStartPosition, GenotypeFileNameEndPosition);
write(c("Genotype file name =",GenotypeFileName), file = ModelRunIndicatorPath, ncolumns=2, append = T);
#Get the name of the genotype file used currently.

## (6) Set up batch file.
##Only copy the information below @FILEX in the genotype file generated by GenSelect, such as "APPOLO.MZC",
##to the batch file template "DSSBatch.template". Thus a new batch file can be generated and save it as
##"DSSBatch.v48" in the output directory.

eval(parse(text=paste("source('",WD,"/BatchFileSetUp.r')",sep = '')));
BatchFileSetUp(WD, OD, CultivarBatchFile);
write(c("DSSAT batch file =",CultivarBatchFile), file = ModelRunIndicatorPath, ncolumns=2, append = T);

## (7) Get the parameter property file (miminum, maximum, and flg values) and the number of parameters.
CulFile.origin= readLines(paste0(GD,"/",GenotypeFileName,".CUL"), encoding="UTF-8")
caliLine = CulFile.origin[which(substr(CulFile.origin,1,12) == "!Calibration")]
CulFile = CulFile.origin[-which(substr(CulFile.origin,1,1) == "!")] #ignore lines starting with !
CulFile = c(CulFile,caliLine)

#locate parameter properties
LineNo.title = grep("@VAR#",CulFile)[1]
LineNo.min = grep("999991 MINIMA",CulFile)
LineNo.max = grep("999992 MAXIMA",CulFile)
LineNo.cal = grep("!Calibration",CulFile)
Lineno.thiscul = grep(paste0("^",CultivarID),CulFile)

LineNo.all = c(LineNo.cal[1],LineNo.title,LineNo.min,LineNo.max,Lineno.thiscul)

if(length(LineNo.cal)>1){
  LineNo.cal = grep("!Calibration",CulFile)[1]
  warning("Please use the first !Calibration line to define the calibration switch!")
}

CulFile = CulFile[LineNo.all]
write(c("Parameter property:",CulFile ), file = ModelRunIndicatorPath, append = T);

# discard content after !, and remove the extra space at the end of lines
# LineNo.exc = grep("!",CulFile)
# 
# 
# # if (length(LineNo.exc)>1){
# #   
# #   for (itemp in 1:length(LineNo.exc)-1){
# #     
# #     ExcSplit = unlist(strsplit(CulFile[LineNo.exc[itemp]],"!"))
# #     
# #   }
#   
#   
#   # for (itemp in 1:length(LineNo.exc)-1){
#   #   
#   #   ExcSplit = unlist(strsplit(CulFile[LineNo.exc[itemp]],"!"))
#   #   CulFile[LineNo.exc[itemp]] = ExcSplit[1]
#   #   
#   #   Loc.space = unlist(stringr::str_locate_all(ExcSplit[1]," "))
#   #   
#   #   for (iLoc in length(Loc.space):1) {
#   #     
#   #     if(Loc.space[iLoc]-Loc.space[iLoc-1] > 1){
#   #       
#   #       No.space = length(Loc.space) - iLoc + 1
#   #       break
#         
#       } else {
#         
#         No.space = 0
#         
#       }
#       
#     }
#     CulFile[LineNo.exc[itemp]] = substr(ExcSplit[1],1,nchar(ExcSplit[1])-No.space)
#     
#     # print(No.space)
#     # print(CulFile)
#   }
#   
# }

# convert text to dataframe
CulFile.df = paste0(substr(CulFile,1,6), substr(CulFile,30,nchar(CulFile)[1]))
header = unlist(strsplit(CulFile.df[2],split="(\\s|\\|)+"))
header = header[which(nchar(header)>0)]
CulData = read.table(textConnection(CulFile.df[-c(1,2)]),header=F)
header = header[1:length(colnames(CulData))]
colnames(CulData) = header

Cali = unlist(strsplit(CulFile[1],"\\s+"))
Cali.reshape = paste(c(Cali[1],"placeholder", Cali[2:length(Cali)]), sep=" ", collapse = " ")
Cali.df = read.table(textConnection(Cali.reshape),header = F)
colnames(Cali.df) = header
Cali.df = Cali.df[1:length(header)]
CulData = rbind(CulData,Cali.df)

ncol.predefined = which(header=="ECO#")
TotalParameterNumber = ncol(CulData) - ncol.predefined #Get the total number of the parameters.
ParameterNames = header[-c(1:ncol.predefined)]
write(c("Parameters =",ParameterNames), file = ModelRunIndicatorPath, append = T)

#################Step 2: Begin the GLUE procedure.#################
for (i in StartRoundOfGLUE:TotalRoundOfGLUE)
{

RoundOfGLUE<-i;

## (1) Generate random values for the paramter set concerned.
eval(parse(text = paste("source('",WD,"/RandomGeneration.r')",sep = '')));
RandomMatrix<-RandomGeneration(WD,CulData, TotalParameterNumber, ncol.predefined,NumberOfModelRun, RoundOfGLUE, GLUEFlag);
write(paste0("GLUE Flag: ", RoundOfGLUE), file = ModelRunIndicatorPath, append = T);
write("Random parameter sets have been generated...", file = ModelRunIndicatorPath, append = T);
write("Model runs are starting...", file = ModelRunIndicatorPath, append = T);

## (2) Create new genotype files with the generated parameter sets and run the DSSAT model with them.
eval(parse(text = paste("source('",WD,"/ModelRun.r')",sep = '')));
ModelRun(WD, OD, DSSATD, GD, CropName, GenotypeFileName, CultivarID, RoundOfGLUE, TotalParameterNumber, NumberOfModelRun, RandomMatrix, Cores);
write("Model run is finished...", file = ModelRunIndicatorPath, append = T)

EvaluateFiles <- dir(OD, recursive=TRUE, full.names=TRUE, pattern=paste0("EvaluateFrame_",RoundOfGLUE,".txt"));

EvaluateOutTxt <- dir(OD, recursive=TRUE, full.names=TRUE, pattern=paste0("Evaluate_output.txt"));

RealRandomSetsFiles <- dir(OD, recursive=TRUE, full.names=TRUE, pattern=paste0("RealRandomSets_",RoundOfGLUE,".txt"));
print(RealRandomSetsFiles)

EvaluateFrameData <- c();

RealRandomSetsFrame <- c();

for(Eval_out in EvaluateFiles){
  
  eval(parse(text=paste("FileE<-readLines('",Eval_out,"',n=-1)",sep = '')));
  
  FileLength<-length(FileE);
  
  TitleLine = grep("@RUN",FileE);
  #print(TitleLine)
  
  if(Eval_out==EvaluateFiles[1]){
    EvaluateFrameTitle<-FileE[TitleLine]
    file.copy(EvaluateOutTxt[1], OD) #doing this just because IntegratedLikelihoodCalculation scripts check the header
  }
  
  File_no_title <- FileE[-TitleLine]; #remove title
  
  EvaluateFrameData=append(EvaluateFrameData,File_no_title);
}

EvaluateFrame<-append(EvaluateFrameTitle, EvaluateFrameData);
eval(parse(text = paste('write(EvaluateFrame, "',OD,'/EvaluateFrame_',RoundOfGLUE,'.txt", append = T)',sep="")))

for (Rand_out in RealRandomSetsFiles){
  eval(parse(text=paste("FileRand<-readLines('",Rand_out,"',n=-1)",sep = '')));
  RealRandomSetsFrame=append(RealRandomSetsFrame,FileRand); 
}

print("AAAAAAABCCCCCCCCCCC")
print(RealRandomSetsFrame)
print("AAAAAAABCCCCCCCCCCC")

eval(parse(text = paste('write(RealRandomSetsFrame, "',OD,'/RealRandomSets_',RoundOfGLUE,'.txt", append = T)',sep="")))


write("Likelihood calculation is starting...", file = ModelRunIndicatorPath, append = T);

## (3) Calculate the likelihood values for each parameter set.
eval(parse(text = paste("source('",WD,"/LikelihoodCalculation.r')",sep = '')));
LikelihoodCalculation(WD, OD, CropName, ParameterNames, RoundOfGLUE);
write("Likelihood calculation is finished...", file = ModelRunIndicatorPath, append = T);
write("Starting calculation of posterior distribution...", file = ModelRunIndicatorPath, append = T);

## (4) Derivation of posterior distribution.
eval(parse(text = paste("source('",WD,"/PosteriorDistribution.r')",sep = '')));
PosteriorDistribution(WD, OD, ParameterNames, ParameterProperty, CropName, RoundOfGLUE);
write("Posterior distribution is derived...", file = ModelRunIndicatorPath, append = T);

## (5)  Indicator of model running to show the round of GLUE is finished.

if (RoundOfGLUE==1)
{
Indicator<-'The first round of GLUE is finished.';
write(Indicator, file = ModelRunIndicatorPath, append = T);
} else
{ 
Indicator<-'The second round of GLUE is finished.';
write(Indicator, file = ModelRunIndicatorPath, append = T);
}

}

#################Step 3: Get a final optimal parameter set.############## 
eval(parse(text = paste("source('",WD,"/OptimalParameterSet.r')",sep = '')));
OptimalParameterSet(GLUEFlag, OD, DSSATD, CropName, CultivarID, CultivarName, GenotypeFileName, TotalParameterNumber);

options(show.error.message=T)

 








