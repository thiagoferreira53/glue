library(parallel)

##This is the function to run the DSSAT model.
ModelRun<-function(WD, OD, DSSATD, GD, CropName, GenotypeFileName, CultivarID, RoundOfGLUE, TotalParameterNumber, 
                   NumberOfModelRun, RandomMatrix, CoresAvailable, EcotypeID, EcotypeParameters, ModelSelect, CTR)
{
  CTR
  ListModelRun<- 1:NumberOfModelRun
  
  ParameterSetIndex<-c();

  run_simulations <<- function(i) {
    core_dir_name <<- paste0(OD,'/core_',Sys.getpid())
    
    if(!dir.exists(core_dir_name)){
      dir.create(core_dir_name)
      write('',paste0(core_dir_name,'/Evaluate_output.txt'))
      write('',paste0(core_dir_name,'/Error_list_',Sys.getpid(),'.txt'))
      file.copy(paste0(OD,'/DSSBatch.v48'), core_dir_name)
      file.copy(paste0(GD,'/',GenotypeFileName,'.CUL'), core_dir_name)
      file.copy(paste0(GD,'/',GenotypeFileName,'.ECO'), core_dir_name) #added to run on HiPerGator
      file.copy(paste0(GD,'/',GenotypeFileName,'.SPE'), core_dir_name) #added to run on HiPerGator
      file.copy(paste0(GD,'/',GenotypeFileName,'.CUL'), OD) #adding a copy since GLUE needs to read the header after ModelRun.r
      writeLines(CTR,paste0(core_dir_name,"/DSCSM048.CTR")) #writing control file in each core directory
    }
    setwd(core_dir_name);
    #Set the path for program to call the bath file running.

    ################### 1. Model Run ##################
    ModelRunNumber<- i
    #print(ModelRunNumber)
    eval(parse(text = paste("source('",WD,"/GenotypeChange.r')",sep = '')));#Tell the location of the function.
    GenotypeChange(GD, DSSATD, core_dir_name, CropName, GenotypeFileName, CultivarID, TotalParameterNumber, ModelRunNumber, RandomMatrix, EcotypeID, EcotypeParameters); #Change the genotype file.
    
    
    #cat(RandomMatrix[ModelRunNumber,])
    #check which OS GLUE is running in order to run the simulations
    if(.Platform$OS.type == "windows"){
      eval(parse(text = paste("system('",DSSATD,"/DSCSM048.EXE ",ModelSelect," B ",OD,"/DSSBatch.v48 DSCSM048.CTR')",sep = '')));
    }else{
      eval(parse(text = paste("system('",DSSATD,"/dscsm048 ",ModelSelect," B ","DSSBatch.v48 DSCSM048.CTR')",sep = '')));
    }
    
    #Call the bath file to run the model.
    if (file.exists("Evaluate.OUT")== F)
    {
      cat(paste0("An error occurred in ", core_dir_name, " when using the following cultivar coefficients:\n"), file = paste0(core_dir_name,"/Error_list_",Sys.getpid(),".txt"),append = T)
      eval(parse(text = paste("cat(",list(RandomMatrix[ModelRunNumber,(1:(TotalParameterNumber -EcotypeParameters))]),", file = '",core_dir_name,"/Error_list_",Sys.getpid(),".txt',append = T)",sep = '')));
      #next;
      if(EcotypeParameters>0){
        cat(paste0("\nand ecotype coefficients:\n"), file = paste0(core_dir_name,"/Error_list_",Sys.getpid(),".txt"),append = T)
          eval(parse(text = paste("cat(",list(RandomMatrix[ModelRunNumber,(TotalParameterNumber -EcotypeParameters:TotalParameterNumber)]),"\n, file = '",core_dir_name,"/Error_list_",Sys.getpid(),".txt',append = T)",sep = '')));
      }
    }else
    {
      eval(parse(text = paste("EvaluateFile<-readLines('",core_dir_name,"/Evaluate_output.txt',n=-1)",sep = '')));
      
      ##Make a judgement with the Evaluate file. If there are something like "********", or "NaN" appeared
      ##in the Evaluate file, this set of model run will be neglected directly, don't need go for data processing.
      Error1Address<-match('NaN',EvaluateFile);
      Error2Address<-match("********",EvaluateFile);
      
      if (is.na(Error1Address) & is.na(Error2Address)){
        eval(parse(text = paste("EvaluateOut<<-readLines('",core_dir_name,"/Evaluate.OUT',n=-1)",sep = '')));
        #Read the output in evaluate file.
        
        eval(parse(text = paste("write(EvaluateOut, file = '",core_dir_name,"/Evaluate_output.txt',append = F)",sep = '')));
        #Save the evaluate output, but replace the previous output.
  
        ################### 2. Data Processing ##################
        
        
        FileLength<-length(EvaluateFile);
        TreatmentNumber<-(FileLength-3);

        #eval(parse(text = paste("write('.', file = '",core_dir_name,"/Error_list_",Sys.getpid(),".txt',append = T)",sep = '')));
        
        eval(parse(text = paste("source('",WD,"/OutputProcessing.r')",sep = '')));
        OutputProcessing(WD, core_dir_name, CropName, RoundOfGLUE, ModelRunNumber);
        #Call the function to process the output data of evaluate and plant growth in each model run.
        
        ParameterSetIndex<-c(ParameterSetIndex,i);
        #Select the parameter set that match the requirement, i.e. do not have bad outputs.            
      }else{
      cat(paste0("Missing values found in ", core_dir_name, " when using the following combination of cultivar coefficients:\n"), file = paste0(core_dir_name,"/Error_list_",Sys.getpid(),".txt"),append = T)
      eval(parse(text = paste("cat(",list(RandomMatrix[ModelRunNumber,(1:(TotalParameterNumber -EcotypeParameters))]),'\n',", file = '",core_dir_name,"/Error_list_",Sys.getpid(),".txt',append = T)",sep = '')));
        if(EcotypeParameters>0){
          cat(paste0("\nand ecotype coefficients:\n"), file = paste0(core_dir_name,"/Error_list_",Sys.getpid(),".txt"),append = T)
            eval(parse(text = paste("cat(",list(RandomMatrix[ModelRunNumber,(TotalParameterNumber -EcotypeParameters:TotalParameterNumber)]),'\n',", file = '",core_dir_name,"/Error_list_",Sys.getpid(),".txt',append = T)",sep = '')));
        }
      }
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

  }
    
    #
    #mclapply(ListModelRun, run_simulations, mc.cores = CoresAvailable)
    
    cl <- makePSOCKcluster(CoresAvailable)
    setDefaultCluster(cl)
    clusterExport(NULL, c('ModelSelect', 'run_simulations','WD', 'OD', 'DSSATD', 'GD', 'CropName', 
                          'GenotypeFileName', 'CultivarID', 'RoundOfGLUE', 'TotalParameterNumber', 
                          'NumberOfModelRun', 'RandomMatrix', 'EcotypeID', 'EcotypeParameters'))
    parLapply(NULL, ListModelRun, function(z) run_simulations(z))
    stopCluster(cl)

}

