#!/bin/bash

if [ "$#" -ne 4 ]; then
	printf "Master data reduction script for batch processing aors using gridded method\n"
	printf "\n"
	printf "Note that dataset folder must conform to SHA format. So
	datasets
	  -> aors (e.g. r1234566)
	    -> ch0 
	      -> bcd
	        -> position\n"
	printf "\n"
	printf "parameters: 
	1 = datasets path (full path)
	2 = output path (full path)
	3 = log path (full path)
	4 = root path (full path) \n"
	exit 0
fi

datasets_path=$1
spectra_path=$2
log_path=$3
root_path=$4

# navigate into dataset directory
# extract aors into arrray
# navigate to root
cd ${datasets_path}
aors=(*/)
cd ${root_path}

# process aors
# note that there is a trailing
# "/" for the aor variable due
# to array instantiation technique
num_aors="${#aors[@]}"
curr_done=1
for aor in "${aors[@]}";
do
	printf "progress: ${curr_done} / ${num_aors} \n"
	printf "processing aor ${aor} \n"
	# create aor output folder
	rm -rf ${spectra_path}/${aor}
	mkdir ${spectra_path}/${aor}

	# check if SL (ch0) data exists, process it if it does
	if [[ -d "${datasets_path}/${aor}ch0" ]]; then
		# create ch0 output folder
		rm -rf ${spectra_path}/${aor}ch0
		mkdir ${spectra_path}/${aor}ch0

		# create ps and es output folders
		rm -rf ${spectra_path}/${aor}ch0/gridded
		mkdir ${spectra_path}/${aor}ch0/gridded
	
		# navigate into ch0 bcd folder
		# extract positions
		# navigate to root
		cd ${datasets_path}/${aor}ch0/bcd
		set -o noglob 
		positions_wext=($(find -name '*_bcd.fits' -type f))
		positions=("${positions_wext[@]%_bcd.fits}")
		cd ${root_path}

		# process each position
		ps_output_path=${spectra_path}/${aor}ch0/gridded
		input_path=${datasets_path}/${aor}ch0/bcd

		# MAKE SURE TO CHANGE SEQ VALUE
		centers=(1.78571429 5.35714286 8.92857143 12.5 16.07142857 19.64285714 23.21428571 26.78571429 30.35714286 33.92857143 37.5 41.07142857 44.64285714 48.21428571 51.78571429 55.35714286 58.92857143 62.5 66.07142857 69.64285714 73.21428571 76.78571429 80.35714286 83.92857143 87.5 91.07142857 94.64285714 98.21428571)
		for position in "${positions[@]}";
		do
			for i in `seq 0 27`;
			do
				printf "processing position $position, grid segment ${i}\n"
				${root_path}/./reduce_gridded.sh $position ${input_path} ${ps_output_path} p ${log_path} ${centers[${i}]}
			done
		done
	fi

	# check if SH (ch1) data exists, process it if it does
	if [[ -d "${datasets_path}/${aor}ch1" ]]; then
		# create ch1 output folder
		rm -rf ${spectra_path}/${aor}ch1
		mkdir ${spectra_path}/${aor}ch1

		# create ps and es output folders
		rm -rf ${spectra_path}/${aor}ch1/gridded
		mkdir ${spectra_path}/${aor}ch1/gridded
	
		# navigate into ch1 bcd folder
		# extract positions
		# navigate to root
		cd ${datasets_path}/${aor}ch1/bcd
		set -o noglob 
		positions_wext=($(find . -name '*_bcd.fits' -type f))
		positions=("${positions_wext[@]%_bcd.fits}")
		cd ${root_path}

		# process each position
		ps_output_path=${spectra_path}/${aor}ch1/gridded
		input_path=${datasets_path}/${aor}ch1/bcd

		# MAKE SURE TO CHANGE SEQ VALUE
		centers=(1.78571429 5.35714286 8.92857143 12.5 16.07142857 19.64285714 23.21428571 26.78571429 30.35714286 33.92857143 37.5 41.07142857 44.64285714 48.21428571 51.78571429 55.35714286 58.92857143 62.5 66.07142857 69.64285714 73.21428571 76.78571429 80.35714286 83.92857143 87.5 91.07142857 94.64285714 98.21428571)
		for position in "${positions[@]}";
		do
			for i in `seq 0 27`;
			do
				printf "processing position $position, grid segment ${i}\n"
				${root_path}/./reduce_gridded.sh $position ${input_path} ${ps_output_path} p ${log_path} ${centers[${i}]}
			done
		done
	fi
	curr_done=$((curr_done+1))
done
