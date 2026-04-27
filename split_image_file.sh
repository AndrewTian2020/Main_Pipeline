#!/bin/bash
#SBATCH --gpus-per-node=h100:1
#SBATCH --mem=8G 
#SBATCH --time=2:00:00
#SBATCH --job-name=SplitImg
#SBATCH --output=%j-%x.out
#SBATCH --error=%j-%x.err
#SBATCH --mail-user=Andrew.Tian@UHN.ca
#SBATCH --mail-type=ALL

# Script to split image files based on filename patterns
# Author: Shuye Pu
# Date: March 28, 2025

# Load required modules
module load python/3.11

# Create and activate virtual environment
virtualenv --no-download $SLURM_TMPDIR/env
source $SLURM_TMPDIR/env/bin/activate
pip install --no-index --upgrade pip

# Install required packages
pip install --no-index pillow
pip install --no-index shutil
pip install --no-index argparse
pip install --no-index re
pip install --no-index os

# Parameters
SOURCE_DIR=$1
DEST_DIR=$2
COPY_FLAG=$3

echo "Starting image file splitting"
echo "Source directory: $SOURCE_DIR"
echo "Destination directory: $DEST_DIR"
echo "Copy flag: $COPY_FLAG"

# Run the Python script

python $HOME/MicroNuclei_work/python/script/split_image_file.py --source "$SOURCE_DIR" --destination "$DEST_DIR" $COPY_FLAG

# Check if the script ran successfully
if [ $? -eq 0 ]; then
    echo "Successfully split images"
else
    echo "ERROR: Failed to split images"
    exit 1
fi

# Deactivate virtual environment
deactivate

echo "Image splitting completed"
