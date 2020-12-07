#!/bin/bash
#SBATCH --job-name=test
#SBATCH --qos=lr_normal
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --account=pc_heptheory
#SBATCH --partition=lr3
#SBATCH --time=0:15:00

module purge
module load python/2.7

PYTHON_POST_PROCESS_DIR=/global/home/users/graveltr/ir_axion_decay_v2/

python ${PYTHON_POST_PROCESS_DIR}/emptyspace.py 
