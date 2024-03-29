#!/bin/sh

# ct2mri.sh
# 
#The second argument is the nii.gz file of the CT scan that you need to create with something like Matlab or FSL's mri_convert function.
#This script uses FSL's flirt command to rigidly (i.e., 6 degrees of freedom mapping) transform the CT scan so that it lines up with the preimplant MRI by maximizing the mutual information between the volumes.
#Images of the two volumes overlayed are automatically generated so that you can inspect the quality of the coregistration. 
#In the process the elec_recon subfolder in the patient's FreeSurfer folder is created along with the following files:
#    T1.nii.gz: The full head MRI
#    brainmask.nii.gz: The skull stripped MRI
#    rCT.nii: The post-implant CT coregistered to the pre-implant MRI
#
# Created by David Groppe on 2/11/15.
# Questions? Email: david.m.groppe@gmail.com
# Copyright 2015 __MyCompanyName__. All rights reserved.

usage='\nUSAGE:\n  ct2mri.sh freesurferSubjectName ctNiiFile\n\nEXAMPLE:\n ct2mri.sh TWH014 /Users/dgroppe/Desktop/TWH_14_DICOMS/ct.nii.gz\n'

if [ "$#" = 0 ]; then
 echo $usage
 exit 2
fi

sub=$1
fsDir=$SUBJECTS_DIR/$sub
if [ ! -d $fsDir ]; then
  echo
  echo "... ${fsDir} is not a directory."
  echo "...you have the wrong FreeSurfer codename for the subject or you have not yet run recon-all on this subject's MRI " 
  echo
  exit 2
fi

if [ ! -f  $2 ]; then
 echo
 echo "...File ${2} not found. Exit."
 echo
 exit 2
fi

elecReconPath=$SUBJECTS_DIR/$sub/CT

echo 'Creating T1.nii.gz in CT folder for coregistration.'
mriPath=$SUBJECTS_DIR/$sub/mri
mri_convert $mriPath/T1.mgz $elecReconPath/T1.nii

echo 'Registering ' $2 ' to T1.nii.gz with a rigid (6 degrees of freedom) transformation that maximizes mutual information between the volumes. This takes awhile....'
flirt -in $2  -ref $elecReconPath/T1.nii -out $elecReconPath/mri2CT.nii -omat $elecReconPath/mri2CT.mat -interp trilinear -cost mutualinfo -dof 6 -searchcost mutualinfo -searchrx -180 180 -searchry -180 180 -searchrz -180 180
# Make directory store coregistration images
mkdir -p $elecReconPath/PICS/COREG/

# Make images of CT/MRI coregistration
slices $elecReconPath/mri2CT.nii.gz $elecReconPath/T1.nii
slices $elecReconPath/T1.nii  $elecReconPath/mri2CT.nii.gz
# Make gifs of those images
slices $elecReconPath/mri2CT.nii.gz $elecReconPath/T1.nii -o $elecReconPath/PICS/COREG/mri2CT_1.gif
slices $elecReconPath/T1.nii  $elecReconPath/mri2CT.nii.gz -o $elecReconPath/PICS/COREG/mri2CT_2.gif

#convert to .nii to for the rest of the pipeline
mri_convert $elecReconPath/mri2CT.nii.gz $elecReconPath/rCT.nii

# open freeview to inspect images
freeview -v $elecReconPath/T1.nii $elecReconPath/rCT.nii:colormap=heat:opacity=0.4
