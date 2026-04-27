#!/usr/bin/env python3
import os
import argparse
import shutil

# Parse command line arguments
parser = argparse.ArgumentParser(description='Fix image filenames')
parser.add_argument('-s', '--src', required=True, help='Source directory containing image files.')
parser.add_argument('-d', '--dst', required=True, help='Destination directory for fixed image filenames.')
args = parser.parse_args()

source_dir = args.src
destination_dir = args.dst

for filename in os.listdir(source_dir):
    if filename.endswith(".jpg") or filename.endswith(".jpeg") or filename.endswith(".png") or filename.endswith(".gif") or filename.endswith(".bmp") or filename.endswith(".tiff") or filename.endswith(".tif"):
        # change the 00d00h00m to 01d00h00m, 01d00h00m to 02d00h00m, etc. so that the day is incremented by 1
      
        matched = False
        
        # Define pattern replacements
        patterns = {
            "00d00h00m": "01d00h00m",
            "01d00h00m": "02d00h00m",
            "02d00h00m": "03d00h00m",
            "03d00h00m": "04d00h00m",
            "04d00h00m": "05d00h00m",
            "05d00h00m": "06d00h00m",
            "06d00h00m": "07d00h00m",
            "07d00h00m": "08d00h00m",
            "00d12h00m": "01d12h00m",
            "01d12h00m": "02d12h00m",
            "02d12h00m": "03d12h00m",
            "03d12h00m": "04d12h00m",
            "04d12h00m": "05d12h00m",
            "05d12h00m": "06d12h00m",
            "06d12h00m": "07d12h00m",
            "07d12h00m": "08d12h00m"
        }
        
        # Check each pattern and replace only once
        for pattern, replacement in patterns.items():
            if pattern in filename:
                newname = filename.replace(pattern, replacement)
                print(f"Matched pattern {pattern} in {filename}")
                matched = True
                break  # Exit after first match
        
        if matched:
            shutil.copy(os.path.join(source_dir, filename), os.path.join(destination_dir, newname))
            print("Copied: {} to {}".format(filename, newname))
        else:
            # If no pattern matched, just copy the file as is
            shutil.copy(os.path.join(source_dir, filename), os.path.join(destination_dir, filename))
            print("No pattern matched. Copied without changes: {}".format(filename))
        
print("Image filenames fixed successfully")