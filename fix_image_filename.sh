#!/bin/bash

# Script to fix image filenames
# Author: Shuye Pu
# Date: May 7, 2025

# check the number of arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <source_directory> <destination_directory>"
    exit 1
fi

# Parameters
SOURCE_DIR=$1
DEST_DIR=$2

echo "Starting image filename fixing"
echo "Source directory: $SOURCE_DIR"
echo "Destination directory: $DEST_DIR"

# Check if the source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Source directory does not exist"
    exit 1
fi

# Check if the destination directory exists
if [ ! -d "$DEST_DIR" ]; then
    echo "Destination directory does not exist"
    mkdir -p "$DEST_DIR"
fi

# Run the Python script

python $HOME/MicroNuclei_work/python/script/fix_image_filename.py --src "$SOURCE_DIR" --dst "$DEST_DIR"

# Check if the script ran successfully
if [ $? -eq 0 ]; then
    echo "Successfully fixed image filenames"
else
    echo "ERROR: Failed to fix image filenames"
    exit 1
fi

echo "Image filename fixing completed"
