# Dependencies
* [SPICE](https://irsa.ipac.caltech.edu/data/SPITZER/docs/dataanalysistools/tools/spice/)
* python 2.7


# The Pipeline
**Important** - create directories /datasets and /spectra, leave them empty. Also you must configure $root in pipeline.sh to be the directory in which /datasets and /spectra live in (the directory containing this repo). Use full path.

Use pipeline.sh to run the entire pipeline, do a "module load python/2.7". Make sure to add AORs to aors.txt.
Use pipeline.slurm with sbatch to run via slurm.

## AOR Download Stage
* inputs: aors.txt
* source: download_aors.cpp
* outputs: /datasets

Downloads aors from the [Spitzer Heritage Archive
(SHA)](SPIC://sha.ipac.caltech.edu/applications/Spitzer/SHA/). Use
[heasarc](https://heasarc.gsfc.nasa.gov/db-perl/W3Browse/w3table.pl?tablehead=name%3Dspitzmastr&Action=More+Options)
for finding aors to put in aors.txt. 

## SPICE Gridded Reduction Stage
* inputs: /datasets
* source: master_reduce_gridded.sh, reduce_gridded.sh
* outputs: /spectra

##  Spectra Python Post Processing Stage
* inputs: /spectra
* source: emptyspace.py, post_process_gridded.py
* outputs: /spectra (augmented)
