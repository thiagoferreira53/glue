#####################################################################################################################

#####################################################################################################################
                        ______  _____ _____  ___ _____            _____  _     _   _ _____                       
                        |  _  \/  ___/  ___|/ _ \_   _|          |  __ \| |   | | | |  ___|                      
                        | | | |\ `--.\ `--./ /_\ \| |    ______  | |  \/| |   | | | | |__                        
                        | | | | `--. \`--. \  _  || |   |______| | | __ | |   | | | |  __|                       
                        | |/ / /\__/ /\__/ / | | || |            | |_\ \| |___| |_| | |___                       
                        |___/  \____/\____/\_| |_/\_/             \____/\_____/\___/\____/                       
                                    
#####################################################################################################################

#####################################################################################################################
#Contact Information:
#Thiago Berton Ferreira   <t.berton@ufl.edu>
#Vakthang Shelia          <vakhtang.shelia@ufl.edu>
#Gerrit Hoogenboom        <gerrit@ufl.edu>
#Cheryl Porter            <cporter@ufl.edu>
#####################################################################################################################

The GLUE (Generalized Likelihood Uncertainty Estimation) program is used to estimate genotype-specific coefficients 
for the DSSAT crop models. It is a Bayesian estimation method that uses Monte Carlo sampling from prior distributions 
of the coefficients and a Gaussian likelihood function to determine the best coefficients based on the data that are 
used in the estimation process. The GLUE program allows users to select a crop, then a cultivar to be estimated. The 
program will then identify all experiments and treatments in the DSSAT data files for the crop that have measurements 
for that cultivar. More information can be found on the User Guideline documentation.

(https://usermanual.wiki/Document/Glue20Users20Guide20Version2047.1359076516.pdf)

#####################################################################################################################

This version of DSSAT-GLUE was developed using a parallel computing approach to improve computer performance and 
significantly reduce the time required for estimating the genotype-specific coefficients. The original code was 
modified to break down the total number of simulations into parts according to the number of cores (CPUs) available.
Each core process the simulations independently, and the results are combined afterward to evaluate which
combination of genotype-specific coefficients had the best performance based on the data used in the estimation 
process.

**For this version, R library "parallel", "rjson" and depencies are required (GLUE will automatically download).**

How to use it:

- Create a "SimulationControl.csv" file. This is a configuration file for running GLUE. Find below the required structure 
  for the file.

- Create a C file (similar to a batch file) and put it in your working directory. 
  RUNNING THIS GLUE VERSION IN THE COMMAND LINE WILL NOT CREATE THE C FILE (Tip: Use GLUESelect to generate the file).

- Check if the cultivar to be calibrated is actually defined inside the .CUL with a unique ID and some initial values
  for the genotype-specific coefficients. GLUE will use the "MINIMA" and "MAXIMA" inside the cultivar/ecotype file to 
  estimate the new genetic coefficients. Also, make sure that your genotype files have a "!Calibration" line 
  identifying which coefficients are related to phenology ("P"), growth ("G"), and not applicable ("N").
  
- On the command-line interface (CLI), go to the GLUE directory and run GLUE using the command: "Rscript GLUE.r". 
  *GLUE.bat is not currently working with this version*
  *Windows users should specify the full path to Rscript (Usually located in C:\Program Files\R\...\bin\Rscript.exe)

- Currently, ecotype coefficient calibration requires changes in the .ECO structure. For this reason, trying to 
  calibrate ecotype coefficients using the standard .ECO files from DSSAT will produce errors.
  
- To save previous runs, please move the results to another folder or create a folder named "BackUp" inside your output 
  directory (usually defined as GLWork).
  
  
  **********************************************************************************************************************
  ALL DATA INSIDE THE OUTPUT DIRECTORY BESIDES THE "BackUp" FOLDER AND CALIBRATION FILES (..C EXTENSION) WILL BE DELETED 
  AT THE START OF A NEW CULTIVAR CALIBRATION. MAKE SURE TO MOVE ANY PREVIOUS RESULTS TO THE BackUp folder 
  **********************************************************************************************************************
  
*SimulationControl.csv file Structure:
 | CultivarBatchFile - Define the file C (batch) to be used (the file should be located inside the GLWork/working directory).
 | ModelID - Inform which model should be used for the calibration (Tip: All model IDs can be found in the DSCSM048.CTR).
 | EcotypeCalibration - Indicates if GLUE should also calibrate the coefficients on the respective ecotype (.ECO) file. 
                    EcotypeCalibration = "Y" indicates that GLUE should also calibrate the Ecotype coefficients for this 
                    cultivar. The .ECO file MUST be well structured with "MAXIMA" and "MINIMA" and each coefficient
                    MUST contain a header indicating whether it is associated with phenology ("P"), growth ("G"), or 
                    not applicable ("N").
 | GLUED - Define the path for the GLUE directory.
 | OutputD - Define the directory path for the working directory and cultivar calibration outputs.
 | DSSATD - Define the directory path where DSSAT is located.
 | GenotypeD - Define the directory path where the genotype-related files are located (.CUL, .ECO, .SPE).
 | GLUEFlag - Define the flag for GLUE procedure. 
              GLUEFlag = 1, both coefficients related to phenology and growth will be evaluated; 
              GLUEFlag = 2, only phenology will be evaluated; 
              GLUEFlag = 3, only growth will be evaluated;
 | NumberOfModelRun - Define the number of model runs for each treatment.
 | Cores - Indicate the number of cores (CPUs) to run the coefficient calibration. If Cores = "", GLUE will assume 
           that it is running on a High Perfomance Computer (SLURM job scheduler) and use the same amount of cores
           specified on through the "--cpus-per-task" command (usually defined in the job request file - .sh).
           *Use "parallel::detectCores()" command in R or RStudio to check the number of cores available. When 
           requesting more cores than what is actually available, GLUE will use the maximum number of cores - 1 to
           execute the calibration.*
           **We do not recommend the use of all available cores in your machine for running GLUE.**

  **IMPORTANT**
  - It is not necessary to add "/" at the end of each path in the SimulationControl.csv;
  - The size of the soil profile file (e.g. .SOL) has an impact in the time required to run the cultivar calibration.
    It is recommended to create a soil file with only the profiles being used during the calibration;

  **Windows users**
  - Use "/" instead of "\" when writing the paths in the .json file (R and the .json file will not run with "\");