#!/usr/bin/env python
# coding: utf-8

# In[1]:


import numpy as np
import inspect

import matplotlib
matplotlib.use('agg')

import pylab as plt
import pandas as pd

from astropy import constants as const
from astropy import units as u
from astropy.io import ascii

from matplotlib import rc

from copy import copy, deepcopy

# curve fitting
from numpy import exp, linspace, random
from scipy.optimize import curve_fit

from scipy import integrate

import sys
import os

# In[21]:


# change the path depending on your directory structure

if (len(sys.argv) != 2):
    exit()

observation = str(sys.argv[1])
dir_path = observation[0:observation.rfind("/") + 1]
observation_code = observation[observation.rfind("/") + 1:len(observation)]
output_dir = dir_path + observation_code + "_emptyspace/"
os.system("mkdir " + output_dir)

print("processing observation: " + observation)
NUMSEGMENTS = 28
bounds = np.linspace(0.0, 100.0, NUMSEGMENTS + 1)
centers =(bounds[1:] + bounds[:-1]) / 2
data = []
profiles = []
profiles.append(ascii.read(observation + "_bcd.profile.tbl"))
for center in centers:
    center = "{:.8f}".format(center)
    table = ascii.read(observation + "_C"+ str(float(center)) + "_bcd.spect.tbl")
    data.append(table)

# In[4]:


# extract a column of data from the ascii table
def extract_col(tables, col): 
    ret = []
    for table in tables:
        curr = np.zeros(len(table))
        i = 0
        for row in table:
            curr[i] = row[col]
            i = i + 1
        ret.append(curr)
    return ret

def find_order_change_idx(tables):
    ret = []
    for table in tables:
        i = 0
        curr = len(table)
        found = 0
        for row in table:
            if(row[0] == 3 and found == 0):
                curr = i
                found = 1
            i = i + 1
        ret.append(curr)
    return ret


# In[5]:


wavelengths = extract_col(data,1)
flux_densities = extract_col(data,2)
flux_errors = extract_col(data,3)

order_change_idxs = find_order_change_idx(data)

SUBPLOT_COLS = 2
SUBPLOT_ROWS = len(centers)/2
fig = plt.figure(figsize=(40,80))
fig.tight_layout()
integrals = []
for i in range(0, len(centers)):
    order_2_int = integrate.cumtrapz(flux_densities[i][0:order_change_idxs[i]], wavelengths[i][0:order_change_idxs[i]], initial=0)
    order_3_int = integrate.cumtrapz(flux_densities[i][order_change_idxs[i]:], wavelengths[i][order_change_idxs[i]:], initial=0)
    curr_int = order_2_int[-1] + order_3_int[-1]
    integrals.append(curr_int)
    curr_ax = fig.add_subplot(SUBPLOT_ROWS, SUBPLOT_COLS, i + 1)
    curr_ax.errorbar(wavelengths[i][0:order_change_idxs[i]], flux_densities[i][0:order_change_idxs[i]], flux_errors[i][0:order_change_idxs[i]], fmt='o', label="order 2")
    curr_ax.errorbar(wavelengths[i][order_change_idxs[i]:], flux_densities[i][order_change_idxs[i]:], flux_errors[i][order_change_idxs[i]:], fmt='o', label="order 3")
    curr_ax.legend(loc='best')
    curr_ax.set_title("center = " + str(centers[i]) + "%, integral = " + str(curr_int))
    curr_ax.set_xlabel("wavelength [um]")
    curr_ax.set_ylabel("flux density [Jy]")
#plt.show() 

print("saving per pixel spectra with integral values plots as image")
fig.savefig(output_dir + './gridded.png')


# In[6]:


fig = plt.figure(figsize=(10,5))
curr_ax = fig.add_subplot(1,1,1)
curr_ax.plot(centers, integrals)
# curr_ax.set_title("")
curr_ax.set_xlabel("center [pct]")
curr_ax.set_ylabel("integral [flux]")
#plt.show() 
print("saving reconstructed profile image")
fig.savefig(output_dir + './dn_reconstructed.png')


# In[7]:


pct = extract_col(profiles, 0)
dn = extract_col(profiles, 1)
fig = plt.figure(figsize=(10,5))
curr_ax = fig.add_subplot(1,1,1)
curr_ax.plot(pct[0], dn[0])
curr_ax.set_xlabel("center [pct]")
curr_ax.set_ylabel("dn")
#plt.show() 
print("saving original profile image")
fig.savefig(output_dir + './dn.png')

# In[9]:


def search(arr, target):
    for i in range(0, len(arr)):
        if arr[i] == target:
            return i 
    return -1

# need to align wavelength values to properly sum the spectra
# will just put 0 flux densities at wavelengths not present
def align_wavelengths(wavelengths, flux_densities, flux_errors):
    total_range = wavelengths[0]
    # first establish total range (I know this is slow)
    for i in range(1, len(wavelengths)):
        for wavelength in wavelengths[i]:
            if search(total_range, wavelength) == -1:
                idx = total_range.searchsorted(wavelength)
                total_range = np.concatenate((total_range[:idx], [wavelength], total_range[idx:]))
    
    # now fill in missing values for each pixel (yes this is also slow)
    ret_wavelengths = np.empty([len(wavelengths), len(total_range)])
    ret_flux_densities = np.empty([len(wavelengths), len(total_range)])
    ret_flux_errors = np.empty([len(wavelengths), len(total_range)])
    for i in range(0, len(wavelengths)):
        ret_wavelengths[i] = total_range
        for j in range(0, len(total_range)):
            idx = search(wavelengths[i], total_range[j])
            if idx == -1:
                ret_flux_densities[i][j] = 0.0
                ret_flux_errors[i][j] = 0.0
            else:
                ret_flux_densities[i][j] = flux_densities[i][idx]
                ret_flux_errors[i][j] = flux_errors[i][idx]
    return ret_wavelengths, ret_flux_densities, ret_flux_errors


wavelengths, flux_densities, flux_errors = align_wavelengths(wavelengths, flux_densities, flux_errors)


# In[13]:


summed_wavelengths = wavelengths[0]
summed_flux_densities = np.empty(len(flux_densities[0]))
summed_flux_errors = np.empty(len(flux_errors[0]))

# extract spectra of all pixels with total flux
# less than 68th percentile
CUTOFF = np.percentile(integrals, 68)
cutoff_idxs = []
for i in range(0, len(integrals)):
    if integrals[i] < CUTOFF:
        cutoff_idxs.append(i)

for i in range(0, len(wavelengths[0])):
    pixel_values = np.empty(len(cutoff_idxs))
    pixel_errors = np.empty(len(cutoff_idxs))
    j = 0
    for idx in cutoff_idxs:
        pixel_values[j] = flux_densities[idx][i]
        pixel_errors[j] = flux_errors[idx][i]
        j = j + 1
    summed_flux_densities[i] = np.mean(pixel_values)
    summed_flux_errors[i] = np.sqrt(np.mean(pixel_errors**2))

fig = plt.figure(figsize=(10,5))
curr_ax = fig.add_subplot(1,1,1)
curr_ax.errorbar(summed_wavelengths, summed_flux_densities, summed_flux_errors, fmt='o')
curr_ax.set_title("Summed Spectra for CUTOFF: " + str(CUTOFF))
curr_ax.set_xlabel("wavelength [um]")
curr_ax.set_ylabel("flux density [Jy]")
# curr_ax.set_xlim([5.0,6.5])
#plt.show() 
print("saving summed spectra image")
fig.savefig(output_dir + './cutoff_summed.png')



# In[49]:


# configure the output file

# copy over spect.tbl header stuff
# from first center file (doesn't matter)
# since all the headers are the same (I think?)
center = centers[0]
center = "{:.8f}".format(center)
ifile = open(observation + "_C"+ str(float(center)) + "_bcd.spect.tbl", 'r')
ofile = open(output_dir + observation_code + '_emptyspace.spect.tbl', 'wb')
for line in ifile:
    if(line.find('2', 0, 2) == -1 and line.find('3', 0, 2) == -1 and line.find('|', 0, 2)):
        ofile.write(line)

# write column headers for table section
NUM_DIGITS = 18;
PADDING = 4;
ofile.write("|wavelength" + ' ' * (NUM_DIGITS - len("|wavelength") + PADDING) + 
            "|flux_density" + ' ' * (NUM_DIGITS - len("|flux_density") + PADDING)+ 
            "|error" + ' ' * (NUM_DIGITS - len("|error") + PADDING) + 
            "|\n")
ofile.write("|real" + ' ' * (NUM_DIGITS - len("|real") + PADDING) + 
            "|real" + ' ' * (NUM_DIGITS - len("|real") + PADDING)+ 
            "|real" + ' ' * (NUM_DIGITS - len("|real") + PADDING) + 
            "|\n")
ofile.write("|" + ' ' * (NUM_DIGITS - len("|") + PADDING) + 
            "|Jy" + ' ' * (NUM_DIGITS - len("|Jy") + PADDING)+ 
            "|Jy" + ' ' * (NUM_DIGITS - len("|Jy") + PADDING) + 
            "|\n")
    
# write the data to the table section
print("writing data to emptyspace_bcd.spect.tbl")
for i in range(len(summed_wavelengths)):
    ofile.write("%.16f" % summed_wavelengths[i])
    ofile.write(' ' * PADDING)
    ofile.write("%.16f" % summed_flux_densities[i])
    ofile.write(' ' * PADDING)
    ofile.write("%.16f" % summed_flux_errors[i])
    ofile.write(' ' * PADDING + "\n")
ifile.close()
ofile.close()


# In[15]:


def find_nearest(array, value):
    array = np.asarray(array)
    idx = (np.abs(array - value)).argmin()
    return idx

dn_indices = []
for idx in cutoff_idxs:
    dn_indices.append(find_nearest(pct[0], centers[idx]))

pct = extract_col(profiles, 0)
dn = extract_col(profiles, 1)
fig = plt.figure(figsize=(10,5))
curr_ax = fig.add_subplot(1,1,1)
curr_ax.plot(pct[0], dn[0])
curr_ax.scatter(np.take(centers, cutoff_idxs), np.take(dn, dn_indices), c='r')
curr_ax.set_xlabel("center [pct]")
curr_ax.set_ylabel("dn")
#plt.show() 
print("saving taken pixel profile overlay image")
fig.savefig(output_dir + './dn_pixels.png')


# In[ ]:




