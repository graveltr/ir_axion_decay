#!/bin/bash
#SBATCH --job-name=test
#SBATCH --qos=lr_normal
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --account=pc_heptheory
#SBATCH --partition=lr3
#SBATCH --time=0:15:00

SPICE_REDUCE_GRIDDED_DIR=/global/home/users/graveltr/ir_axion_decay_v2/gridded_reduction

${SPICE_REDUCE_GRIDDED_DIR}/./master_reduce_gridded.sh ${SPICE_REDUCE_GRIDDED_DIR}/datasets ${SPICE_REDUCE_GRIDDED_DIR}/spectra ${SPICE_REDUCE_GRIDDED_DIR}/logs ${SPICE_REDUCE_GRIDDED_DIR}
