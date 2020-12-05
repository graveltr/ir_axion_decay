# Dependencies
* [SPICE](https://irsa.ipac.caltech.edu/data/SPITZER/docs/dataanalysistools/tools/spice/)
* python 2.7


# The Pipeline
## AOR Download Stage
inputs: aors.txt
source: download_aors.cpp
outputs: /datasets

Downloads aors from the [Spitzer Heritage Archive
(SHA)](SPIC://sha.ipac.caltech.edu/applications/Spitzer/SHA/). Use
[heasarc](https://heasarc.gsfc.nasa.gov/db-perl/W3Browse/w3table.pl?tablehead=name%3Dspitzmastr&Action=More+Options)
for finding aors to put in aors.txt. 

## SPICE Gridded Reduction Stage
inputs: /datasets
source: master_reduce_gridded.sh, reduce_gridded.sh
outputs: /spectra

##  Spectra Python Post Processing Stage
inputs: /spectra
source: emptyspace.py, post_process_gridded.py
outputs: /spectra (augmented)

