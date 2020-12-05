#!/bin/bash

# Requires "module load python/2.7" (might need to purge current python loaded via "module purge")

root=/global/home/users/graveltr/ir_axion_decay_v2/

cd ${root}

printf "AOR Download Stage \n"
g++ -std=c++11 download_aors.cpp -o download_aors
./download_aors

printf "SPICE Gridded Reduction Stage \n"
${root}/./master_reduce_gridded.sh ${root}/datasets ${root}/spectra ${root}/logs ${root}

printf "Spectra Python Post Processing Stage \n"
python emptyspace.py
