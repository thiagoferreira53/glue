library(iterators)
library(parallel)

##This is the function to run the DSSAT model.
ModelRun<-function(WD, OD, DSSATD, GD, CropName, GenotypeFileName, CultivarID, RoundOfGLUE, TotalParameterNumber, NumberOfModelRun, RandomMatrix, cores_available)
{

  ListModelRun<- 1:NumberOfModelRun
  #print(paste0("OD: ", OD))

  ParameterSetIndex<-c();

  mclapply(ListModelRun, function(i) {
    core_dir_name <<- paste0(OD,'/core_',Sys.getpid())
    
    if(!dir.exists(core_dir_name)){
      dir.create(core_dir_name)
      write('',paste0(core_dir_name,'/Evaluate_output.txt'))
      write('',paste0(core_dir_name,'/Run_check_',Sys.getpid(),'.txt'))
      file.copy(paste0(WD,'/DSSBatch.v48'), core_dir_name)
      file.copy(paste0(GD,'/',GenotypeFileName,'.CUL'), core_dir_name)
      file.copy(paste0(GD,'/',GenotypeFileName,'.CUL'), OD) #add a copy to
    }
    setwd(core_dir_name);
    #Set the path for program to call the bath file running.

    ################### 1. Model Run ##################
    ModelRunNumber<- i
    #print(ModelRunNumber)
    eval(parse(text = paste("source('",WD,"/GenotypeChange.r')",sep = '')));#Tell the location of the function.
    GenotypeChange(GD, DSSATD, core_dir_name, CropName, GenotypeFileName, CultivarID, TotalParameterNumber, ModelRunNumber, RandomMatrix); #Change the genotype file.
    
    
    eval(parse(text = paste("system('",DSSATD,"/dscsm048 ",ModelSelect," B ","DSSBatch.v48')",sep = '')));
    
    #Call the bath file to run the model.
    if (file.exists("Evaluate.OUT")== F)
    {
      eval(parse(text = paste("write('x', file = '",core_dir_name,"/Run_check_",Sys.getpid(),".txt',append = T)",sep = '')));
      next;
    }else
    {
      eval(parse(text = paste("EvaluateOut<<-readLines('",core_dir_name,"/Evaluate.OUT',n=-1)",sep = '')));
      #Read the output in evaluate file.
      
      eval(parse(text = paste("write(EvaluateOut, file = '",core_dir_name,"/Evaluate_output.txt',append = F)",sep = '')));
      #Save the evaluate output, but replace the previous output.

      ################### 2. Data Processing ##################
      eval(parse(text = paste("EvaluateFile<-readLines('",core_dir_name,"/Evaluate_output.txt',n=-1)",sep = '')));
      
      Error1Address<-match('NaN',EvaluateFile);
      Error2Address<-match("********",EvaluateFile);
      ##Make a judgement with the Evaluate file. If there are something like "********", or "NaN" appeared
      ##in the Evaluate file, this set of model run will be neglected directly, don't need go for data processing.
      
      FileLength<-length(EvaluateFile);
      TreatmentNumber<-(FileLength-3);
    }
    
    if (is.na(Error1Address) & is.na(Error2Address))
    {
      
      eval(parse(text = paste("write('.', file = '",core_dir_name,"/Run_check_",Sys.getpid(),".txt',append = T)",sep = '')));
      
      eval(parse(text = paste("source('",WD,"/OutputProcessing.r')",sep = '')));
      OutputProcessing(WD, core_dir_name, CropName, RoundOfGLUE, ModelRunNumber);
      #Call the function to process the output data of evaluate and plant growth in each model run.
      
      ParameterSetIndex<-c(ParameterSetIndex,i);
      #Select the parameter set that match the requirement, i.e. do not have bad outputs.
    }
    else {
      eval(parse(text = paste("write('x', file = '",core_dir_name,"/Run_check_",Sys.getpid(),".txt',append = T)",sep = '')));
    }
    
    if(RoundOfGLUE==1)
    {
      RealRandomSets<-RandomMatrix[ParameterSetIndex,];
      eval(parse(text = paste("write(t(RealRandomSets), file = '",core_dir_name,"/RealRandomSets_1.txt',,append = T, ncolumns =TotalParameterNumber)",sep = '')));
      ##Get and save really used random parameter sets as a table for future use.
    } else
    {
      RealRandomSets<-RandomMatrix[ParameterSetIndex,];
      eval(parse(text = paste("write(t(RealRandomSets), file = '",core_dir_name,"/RealRandomSets_2.txt',,append = T, ncolumns =TotalParameterNumber)",sep = '')));
    }
    
    }, mc.cores = cores_available)

}

