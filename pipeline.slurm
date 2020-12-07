#!/bin/bash
#SBATCH --job-name=ir_axion_decay
#SBATCH --qos=lr_normal
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --account=pc_heptheory
#SBATCH --partition=lr3
#SBATCH --time=10:00:00

# load modules
module purge
module load python/2.7

# define globals
root=/global/home/users/graveltr/ir_axion_decay_v2/
cd ${root}

# commands
./pipeline.sh
