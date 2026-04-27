#!/usr/bin/env python3
"""
Image File Partitioning Script

This script partitions image files from a source directory into multiple 
folders based on filename patterns like "_A10_" (text between underscores).
"""

import os
import shutil
import argparse
import re
from pathlib import Path


def extract_pattern(filename):
    """
    Extract pattern from filename based on patterns like "_A10_".
    For example, "sample_A10_cell.jpg" would extract "A"
    """
    # Find patterns like _A10_ (text between underscores)
    matches = re.findall(r'_([A-Za-z0-9])_', filename)
    
    # only use the letter part of the matches as pattern
    if not matches:
        return "Unclassified"
    
    # Extract only the capital letter part from the match
    match = matches[0]
    capital_letters = re.findall(r'[A-Z]', match)
    
    if not capital_letters:
        return "Unclassified"
    
    # Join all capital letters found in the match
    return ''.join(capital_letters)


def partition_images(source_dir, dest_dir, copy_files=False):
    """
    Partition image files from source_dir into subdirectories in dest_dir
    based on patterns like "_A10_" in filenames.
    
    Args:
        source_dir (str): Source directory containing image files
        dest_dir (str): Destination directory for partitioned folders
        copy_files (bool): If True, copy files instead of linking them
    """
    # Create destination directory if it doesn't exist
    os.makedirs(dest_dir, exist_ok=True)
    
    # Common image file extensions
    image_extensions = {'.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.tif'}
    
    # Dictionary to keep track of patterns and their corresponding files
    pattern_files = {}
    
    # Scan source directory for image files
    for filename in os.listdir(source_dir):
        file_path = os.path.join(source_dir, filename)
        
        # Skip directories and non-image files
        if os.path.isdir(file_path) or os.path.splitext(filename)[1].lower() not in image_extensions:
            continue
        
        # Extract pattern from filename
        pattern = extract_pattern(filename)
        
        # Add file to pattern dictionary
        if pattern not in pattern_files:
            pattern_files[pattern] = []
        
        pattern_files[pattern].append(filename)
    
    # Create subdirectories and link/copy files
    for pattern, files in pattern_files.items():
        # addd the last directory name of source_dir to the pattern
        pattern = os.path.basename(os.path.dirname(source_dir)) + "_" + pattern
        # Create pattern directory
        pattern_dir = os.path.join(dest_dir, pattern)
        os.makedirs(pattern_dir, exist_ok=True)
        
        print(f"Linking {len(files)} files to {pattern} directory")
        
        # Link or copy each file
        for filename in files:
            source_path = os.path.join(source_dir, filename)
            dest_path = os.path.join(pattern_dir, filename)
            
            if copy_files:
                shutil.copy2(source_path, dest_path)
            else:
                os.symlink(os.path.abspath(source_path), dest_path)


def main():
    """Main function to parse arguments and run the partitioning"""
    parser = argparse.ArgumentParser(
        description='Partition image files based on patterns like _A10_ in filenames'
    )
    
    parser.add_argument(
        '--source', '-s',
        required=True,
        help='Source directory containing image files'
    )
    
    parser.add_argument(
        '--destination', '-d',
        required=True,
        help='Destination directory for partitioned folders'
    )
    
    parser.add_argument(
        '--copy', '-c',
        action='store_true',
        help='Copy files instead of linking them'
    )
    
    args = parser.parse_args()
    
    # Validate source directory
    if not os.path.isdir(args.source):
        print(f"Error: Source directory '{args.source}' does not exist")
        return
    
    # Run partitioning
    partition_images(args.source, args.destination, args.copy)
    print("Partitioning complete!")


if __name__ == "__main__":
    main()
