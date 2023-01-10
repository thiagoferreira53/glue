#####################################################################################################################

#####################################################################################################################
                        ______  _____ _____  ___ _____            _____  _     _   _ _____                       
                        |  _  \/  ___/  ___|/ _ \_   _|          |  __ \| |   | | | |  ___|                      
                        | | | |\ `--.\ `--./ /_\ \| |    ______  | |  \/| |   | | | | |__                        
                        | | | | `--. \`--. \  _  || |   |______| | | __ | |   | | | |  __|                       
                        | |/ / /\__/ /\__/ / | | || |            | |_\ \| |___| |_| | |___                       
                        |___/  \____/\____/\_| |_/\_/             \____/\_____/\___/\____/                       
                                    
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
Each individual core process the simulations independently and the results are combined afterwards to evaluate which
combination of genotype-specific coefficients had the best performance based on the data used in the estimation 
process.

**For this version, R library "parallel", "rjson" and depencies are required**

How to use it:

- Create a "GLUE_Defs.json". Find bellow the required strucuture for this .json file.

- Create a .WHC file (similar structure of a batch file) and put in on your working directory.

- Check if the cultivar to be calibrated is actually defined inside the .CUL with a unique ID and some initial values for 
  the genotype-specific coefficients. GLUE will use the "MINIMA" and "MAXIMA" inside the cultivar file to estimate the new
  genetic coefficients.
  
- On the command-line interface (CLI), go to the GLUE directory and run GLUE using the command: "Rscript GLUE.r".


*GLUE_Defs.json File Structure
 | CultivarBatchFile - Define the .WHC to be used (the file should be located inside the GLWork folder).
 | ModelID - Inform which model should be used for the calibration (You can find the respective model ID in the 
             DSCSM048.CTR file for more details).
 | GLUED - Define the path for the GLUE directory.
 | OutputD - Define the directory path for the workind directory and cultivar calibration outputs.
 | DSSATD - Define the directory path where DSSAT is located.
 | GenotypeD - Define the directory path where the genotype-related files are located (.CUL, .ECO, .SPE).
 | GLUEFlag - Define the flag for whold GLUE procedure. 
              GLUEFlag = 1, it means that coefficients related both to phenology and growth will be evaluated; 
              GLUEFlag = 2, only phenology will be evaluated; 
              GLUEFlag = 3, only growth will be evaluated.
 | NumberOfModelRun - Define the number of model runs for each treatment
 | Cores - Indicate the number of cores (CPUs) to be used for running the simulation. If Cores = "", GLUE will assume 
           that it will calibrate on a High Perfomance Computer (SLURM job scheduler) and use the same amount of cores
           specified on through the "--cpus-per-task" command (usually defined in the job request file - .sh).
           *You can use parallel::detectCores() command on R to check the number of cores available.*
           **we do not recommend the use of all available cores in your machine for running GLUE.**
           
           