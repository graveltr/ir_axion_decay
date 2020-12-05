# The Pipeline

## (1) AOR Download Stage
inputs: aors.txt
source: download_aors.cpp
outputs: /datasets

## (2) SPICE Gridded Reduction Stage
inputs: /datasets
source: master_reduce_gridded.sh, reduce_gridded.sh
outputs: /spectra

## (3) Spectra Python Post Processing Stage
inputs: /spectra
source: emptyspace.py, gridded.py
outputs: /spectra (augmented)

# Spitzer Data Retrieval and Spectrum Extraction
## Data Retrieval
Put all of the AORs that you would like to retreive from the archive in the
"aors.txt" filein this root directory, separate them by newlines, no extra
spaces, no extra new lines. The "download_aors.cpp" file is the source code.
Compile the code using "g++ -std=c++11 download_aors.cpp -o aors" and then run
the executable usign "./aors". The script will retrieve SL and SH data. If you
want LL, LH, or other data, you'll have to modify the source, but it should be
straightforward to do. The script will construct a directory structure that
conforms to heritage archive format starting in "/datasets". 

## Spectrum Extraction
After downloading your AORs, you can perform spice pipeline extraction using
the "master_reduce.sh" script. Run the script once with no arguments and the
script will print out the necessary arguments that you'll have to input. Master
reduce will perform a point source and extended source extraction for each bcd
file, and will output spectra in an identical directory structure rooted at
"/spectra".  

## Load and Reduce
Just run "./load_and_reduce.sh" to perform both of these operations if your
directory structure is identical to my own.
