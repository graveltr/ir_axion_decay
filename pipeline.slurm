#!/bin/bash
#SBATCH --job-name=test
#SBATCH --qos=lr_normal
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --account=pc_heptheory
#SBATCH --partition=lr3
#SBATCH --time=0:15:00

# load modules
module purge
module load python/2.7

# define globals

# commands
./pipeline.sh
