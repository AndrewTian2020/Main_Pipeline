#!/usr/bin/bash
# Micronuclei Analysis Pipeline
# March 28, 2025
# Author: Shuye Pu
# 
# This script integrates three steps of the micronuclei analysis pipeline:
# 1. Split images into folders based on filename patterns
# 2. Crop images to focus on relevant areas
# 3. Process images for micronuclei detection
#
# Usage: ./micronuclei_pipeline.sh <base_directory> <work_directory> [--copy|-c]
#   <base_directory>: Path to the base directory containing input data
#   <work_directory>: Path to the work directory
#   --copy, -c: Optional flag to copy files instead of moving them during splitting

# Function to display usage information
usage() {
    echo "Usage: $0 <base_directory> <work_directory> [--copy|-c]"
    echo "  <base_directory>: Path to the base directory containing input data"
    echo "  <work_directory>: Path to the work directory"
    echo "  --copy, -c: Optional flag to copy files instead of moving them during splitting"
    exit 1
}

# Check if base directory is provided
if [ $# -lt 2 ]; then
    echo "Error: Base directory and work directory not provided"
    usage
fi

# Define the base directories
BASE_DIR="$1"
# Define the work directory, which is a subdirectory of the base directory
wp="$2"

# Check if base directory exists
if [ ! -d "$BASE_DIR" ]; then
    echo "Error: Base directory '$BASE_DIR' does not exist or is not accessible"
    usage
fi

# Check if work directory exists
if [ ! -d "$BASE_DIR/$wp" ]; then
    echo "Error: Work directory '$BASE_DIR/$wp' does not exist or is not accessible"
    usage
fi

# Define cropping parameters
LEFT=0
TOP=0
RIGHT=1400
BOTTOM=950

# Define processing mode
MODE="ALL"  # ALL for both nuclei and micronuclei detection

# Check if we should copy files instead of moving them
COPY_FLAG=""
if [ "$3" == "--copy" ] || [ "$3" == "-c" ]; then
    COPY_FLAG="--copy"
    echo "Files will be copied instead of moved during splitting"
else
    echo "Files will be moved during splitting (use -c or --copy to copy instead)"
fi

# Create log directory
LOG_DIR="${BASE_DIR}/pipeline_logs"
mkdir -p $LOG_DIR
LOG_FILE="${LOG_DIR}/pipeline_$(date +%Y%m%d_%H%M%S).log"

# Function to log messages
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a $LOG_FILE
}

# Function to wait for jobs to complete
wait_for_jobs() {
    local job_ids=("$@")
    log "Waiting for ${#job_ids[@]} jobs to complete..."
    
    # Wait for all jobs to complete
    for job_id in "${job_ids[@]}"; do
        while squeue -j "$job_id" | grep -q "$job_id"; do
            log "Job $job_id is still running. Waiting..."
            sleep 60  # Check every minute
        done
        log "Job $job_id has completed."
    done
    
    log "All jobs have completed."
}

log "Starting Micronuclei Analysis Pipeline"
log "======================================="

# STEP 1: Split images into folders based on filename patterns
log "STEP 1: Splitting images based on filename patterns"
log "---------------------------------------------------"

# Array to store job IDs
split_job_ids=()

    
INPUT_DIR="${BASE_DIR}/${wp}"
OUTPUT_DIR="${BASE_DIR}/${wp}-split"

log "Processing ${wp} for splitting"
log "Input directory: ${INPUT_DIR}"
log "Output directory: ${OUTPUT_DIR}"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Check if output directory is empty
if [ -z "$(ls -A "$OUTPUT_DIR")" ]; then
    # Submit the splitting job
    JOB_ID=$(sbatch split_image_file.sh "$INPUT_DIR" "$OUTPUT_DIR" "$COPY_FLAG" | awk '{print $4}')
    
    log "Submitted split job for ${wp} (Job ID: ${JOB_ID})"
    split_job_ids+=("$JOB_ID")
else
    log "Output directory ${OUTPUT_DIR} is not empty. Skipping split job for ${wp}."
fi


# Wait for all splitting jobs to complete (if any were submitted)
if [ ${#split_job_ids[@]} -gt 0 ]; then
    wait_for_jobs "${split_job_ids[@]}"
else
    log "No splitting jobs were submitted. Proceeding to next step."
fi

# STEP 2: Crop images
log "STEP 2: Cropping images"
log "----------------------"

# Array to store job IDs
crop_job_ids=()

SPLIT_DIR="${BASE_DIR}/${wp}-split"
OUT_DIR="${BASE_DIR}/${wp}-croptemp"

# Create output directory if it doesn't exist
mkdir -p "$OUT_DIR"

log "Processing ${wp}-split for cropping"
log "Directory: ${SPLIT_DIR}"
# Get subdirectories
SUBDIRS=$(ls -d ${SPLIT_DIR}/*)

for subdir in $SUBDIRS; do
    # Check if the croptemp directory already exists
    column_name=$(basename $subdir)
    croptemp_dir="${OUT_DIR}/${column_name}_croptemp"
    if [ -d "$croptemp_dir" ]; then
        log "Crop directory ${croptemp_dir} already exists. Skipping crop job for ${subdir}." 
    else
        # Submit cropping job
        JOB_ID=$(sbatch image_cropping.sh $subdir $croptemp_dir $LEFT $TOP $RIGHT $BOTTOM | awk '{print $4}')
        
        log "Submitted crop job for ${subdir} (Job ID: ${JOB_ID})"
        crop_job_ids+=("$JOB_ID")
    fi
done

# Wait for all cropping jobs to complete (if any were submitted)
if [ ${#crop_job_ids[@]} -gt 0 ]; then
    wait_for_jobs "${crop_job_ids[@]}"
else
    log "No cropping jobs were submitted. Proceeding to next step."
fi

# STEP 3: Process images for micronuclei detection
log "STEP 3: Processing images for micronuclei detection"
log "-------------------------------------------------"

# Array to store job IDs
process_job_ids=()

CROP_DIR="${BASE_DIR}/${wp}-croptemp"
OUTPUT_DIR="${BASE_DIR}/${wp}-json" 

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

log "Processing ${wp}-croptemp for micronuclei detection"
log "Directory: ${CROP_DIR}"
log "Output directory: ${OUTPUT_DIR}"

inputs=$(ls -d ${CROP_DIR}/*_croptemp 2>/dev/null || echo "")

# Function to convert time (in seconds) to hh:mm:ss format
convertsecs() {
    ((h=${1}/3600))
    ((m=(${1}%3600)/60))
    ((s=${1}%60))
    printf "%02d:%02d:%02d\n" $h $m $s
}

# Process cropped images
for input in $inputs; do
    output=$(basename $input "_croptemp").json
    output_path="${OUTPUT_DIR}/${output}"
    
    # Check if output JSON file already exists
    if [ -f "$output_path" ]; then
        log "Output file ${output_path} already exists. Skipping processing job for ${input}."
        continue
    fi
    
    # Calculate time allocation
    count=$(ls "$input" | wc -l)
    secs=$((count * 60))
    tot_time=$(convertsecs $secs)

    # Submit processing job
    JOB_ID=$(sbatch image_process.sh --time=$tot_time $input $output_path $MODE | awk '{print $4}')
    
    log "Submitted processing job for ${input} (Job ID: ${JOB_ID})"
    process_job_ids+=("$JOB_ID")
done

# Wait for all processing jobs to complete (if any were submitted)
if [ ${#process_job_ids[@]} -gt 0 ]; then
    echo "number of processing jobs: ${#process_job_ids[@]}"
else
    log "No processing jobs were submitted. Pipeline completed."
fi

log "All jobs submitted. Processing will continue on the compute cluster."
log "Check job status with 'squeue -u $USER'"
log "======================================="
log "Pipeline execution completed"
