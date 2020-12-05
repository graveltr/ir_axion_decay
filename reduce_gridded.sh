#!/bin/bash

# echo 'spice data reduction and spectrum producing script'

if [ "$#" -ne 6 ]; then
    	echo "Illegal number of parameters"
	printf "parameters: 
		1 = position (e.g. SPITZER_S0_...)
		2 = input directory path (full path)
		3 = output directory path (full path)
		4 = point source (p) or extended source (e)
		5 = log directory path (full path) 
		6 = center (in pct) \n"
	exit 0
fi

position=$1
input_path=$2
output_path=$3
extract_type=$4
log=$5/${position}.log
center=$6

rm -rf ${log}
touch ${log}

#echo 'running profile'
profile \
-i $input_path/${position}_bcd.fits \
-b $input_path/${position}_bmask.fits \
-fb 28800 \
-t /global/home/users/graveltr/code/SPICE/cal/C18.18PRE25/b0_psf_fov.tbl \
-w /global/home/users/graveltr/code/SPICE/cal/C18.18PRE25/b0_wavsamp.tbl \
-c 1000 \
-o $output_path/${position}_bcd.profile.tbl \
-q $output_path/${position}_bcd.profile.qa >> ${log}

ridges=(0.0 50.0 100.0)
overlays=(0 1 2)
for i in `seq 0 2`;
do
	#echo "running ridge [${ridges[${i}]}]"
	ridge \
	-p $output_path/${position}_bcd.profile.tbl \
	-f /global/home/users/graveltr/code/SPICE/cal/C18.18PRE25/b0_psf_fov.tbl \
	-m 5.0 \
	-s 3.0 \
	-g 25.0 \
	-c ${ridges[${i}]} \
	-o $output_path/${position}_bcd.ridge.tbl \
	-i /global/home/users/graveltr/code/SPICE/cal/C18.18PRE25/b0_wavsamp.tbl >> ${log}

	#echo "running extract [${overlays[${i}]}]"
	if [ "${extract_type}" = "p" ]; then
		extract \
		-i $input_path/${position}_bcd.fits \
		-r $output_path/${position}_bcd.ridge.tbl \
		-p /global/home/users/graveltr/code/SPICE/cal/C18.18PRE25/b0_psf_fov.tbl \
		-ord 0 \
		-w 1.0 \
		-l 12.0 \
		-w 1.0 \
		-l 8.0 \
		-w 1.0 \
		-l 6.0 \
		-full 0 \
		-over $output_path/${position}_bcd.overlay.${overlays[${i}]}.tbl >> ${log}
	else
		extract \
		-i $input_path/${position}_bcd.fits \
		-r $output_path/${position}_bcd.ridge.tbl \
		-p /global/home/users/graveltr/code/SPICE/cal/C18.18PRE25/b0_psf_fov.tbl \
		-ord 0 \
		-full 1 \
		-over $output_path/${position}_bcd.overlay.${overlays[${i}]}.tbl >> ${log}
	fi	

done


#echo 'running ridge [final]'
ridge \
-p $output_path/${position}_bcd.profile.tbl \
-f /global/home/users/graveltr/code/SPICE/cal/C18.18PRE25/b0_psf_fov.tbl \
-m 5.0 \
-s 3.0 \
-g 25.0 \
-c ${center} \
-o $output_path/${position}_bcd.ridge.tbl \
-i /global/home/users/graveltr/code/SPICE/cal/C18.18PRE25/b0_wavsamp.tbl >> ${log}

#echo 'running extract [final]'
if [ "${extract_type}" = "p" ]; then
	extract \
	-i $input_path/${position}_bcd.fits \
	-r $output_path/${position}_bcd.ridge.tbl \
	-p /global/home/users/graveltr/code/SPICE/cal/C18.18PRE25/b0_psf_fov.tbl \
	-ord 0 \
	-w 1.0 \
	-l 12.0 \
	-w 1.0 \
	-l 8.0 \
	-w 1.0 \
	-l 6.0 \
	-full 0 \
	-over $output_path/${position}_bcd.overlay.tbl >> ${log}
else
	extract \
	-i $input_path/${position}_bcd.fits \
	-r $output_path/${position}_bcd.ridge.tbl \
	-p /global/home/users/graveltr/code/SPICE/cal/C18.18PRE25/b0_psf_fov.tbl \
	-ord 0 \
	-full 1 \
	-over $output_path/${position}_bcd.overlay.tbl >> ${log}
fi	


#echo 'running extract [spectrum]'
if [ "${extract_type}" = "p" ]; then
	extract \
	-i $input_path/${position}_bcd.fits \
	-b $input_path/${position}_bmask.fits \
	-o $output_path/${position}_bcd.extract.tbl \
	-norm 1 \
	-fix 2 \
	-nanDrop 1 \
	-f 29056 \
	-e $input_path/${position}_func.fits \
	-r $output_path/${position}_bcd.ridge.tbl \
	-ord 0 \
	-p /global/home/users/graveltr/code/SPICE/cal/C18.18PRE25/b0_psf_fov.tbl \
	-height1 0 \
	-w 1.0 \
	-l 12.0 \
	-w 1.0 \
	-l 8.0 \
	-w 1.0 \
	-l 6.0 \
	-full 0 >> ${log}
else
	extract \
	-i $input_path/${position}_bcd.fits \
	-b $input_path/${position}_bmask.fits \
	-o $output_path/${position}_bcd.extract.tbl \
	-norm 1 \
	-fix 2 \
	-nanDrop 1 \
	-f 29056 \
	-e $input_path/${position}_func.fits \
	-r $output_path/${position}_bcd.ridge.tbl \
	-ord 0 \
	-p /global/home/users/graveltr/code/SPICE/cal/C18.18PRE25/b0_psf_fov.tbl \
	-height1 0 \
	-full 1 >> ${log}
fi	

#echo 'running irs_tune'
irs_tune \
-i $output_path/${position}_bcd.extract.tbl \
-t /global/home/users/graveltr/code/SPICE/cal/C18.18PRE25/b0_fluxcon.tbl \
-m tune_down \
-o $output_path/${position}_C${center}_bcd.spect.tbl \
-a 3 >> ${log}

# copy over bcd for FITS header
cp $input_path/${position}_bcd.fits $output_path > /dev/null

# delete temporary files using some trickery
cd $output_path
ls | grep -v -e .*spect.tbl -e .*_bcd.fits -e .*profile.tbl | xargs rm > /dev/null
