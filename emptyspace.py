#!/usr/bin/python

import sys
import os
import glob

# print 'Number of arguments:', len(sys.argv), 'arguments.'
# print 'Argument List:', str(sys.argv)

aors = glob.glob("spectra/*")
for i in range(0, len(aors)):
    aors[i] = aors[i] + "/ch0/gridded/"

observations = []
for aor in aors:
    profiles = glob.glob(aor + "*.profile.tbl")
    for i in range(0, len(profiles)):
        observations.append(profiles[i].replace("_bcd.profile.tbl", ""))

for observation in observations:
    os.system("python post_process_gridded.py " + observation)
    
# observation = "spectra/r10422784/ch0/gridded/SPITZER_S0_10422784_0000_0000_8"
# os.system("python gridded.py " + observation)
