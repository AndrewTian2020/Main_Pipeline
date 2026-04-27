#!/usr/bin/bash

#SBATCH --nodes=1
#SBATCH --gpus-per-node=h100:1
#SBATCH --mem=8G
#SBATCH --time=01:30:00
#SBATCH --job-name=CropImg
#SBATCH --output=%j_%x.out
#SBATCH --error=%j_%x.err
#SBATCH --mail-user=Andrew.Tian@UHN.ca
#SBATCH --mail-type=ALL

# ---------------------------------------------------------------------------------------------
echo "Prepare environment"
# ---------------------------------------------------------------------------------------------

# Load required modules
module load python/3.11 opencv

# Create and activate virtual environment
virtualenv --no-download $SLURM_TMPDIR/env
source $SLURM_TMPDIR/env/bin/activate
pip install --no-index --upgrade pip

# Install required packages
pip install --no-index pillow
pip install --no-index numpy
pip install --no-index opencv-python

# ---------------------------------------------------------------------------------------------
echo "Start main process"
# ---------------------------------------------------------------------------------------------

# Run the main python script.
# The arguments should be
#       the folder for the input images (png, tif)
#       the coordinates for cropping in the order of left, top, right, lower
#       
# Example:
#       >>> python image_cropping.sh /home/scratch/test 0 0 1400 950

echo "Processing folder: $1"
echo "Output folder: $2"
echo "Crop coordinates: Left=$3, Top=$4, Right=$5, Bottom=$6"

python $HOME/MicroNuclei_work/python/script/image_cropping.py $1 $2 $3 $4 $5 $6

echo $1
echo $2

# Deactivate virtual environment
deactivate



# ---------------------------------------------------------------------------------------------
echo "Processing completed for $1"
# ---------------------------------------------------------------------------------------------
