#!/bin/bash
#SBATCH --nodes=1
#SBATCH --gpus-per-node=h100:1
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --job-name=MN
#SBATCH --output=%j-%x.out
#SBATCH --error=%j-%x.err
#SBATCH --mail-user=Andrew.Tian@UHN.ca
#SBATCH --mail-type=ALL

# ---------------------------------------------------------------------------------------------
echo "Create a virtual env to run"
# ---------------------------------------------------------------------------------------------

module load python/3.11 gcc opencv
virtualenv --no-download $SLURM_TMPDIR/env
source $SLURM_TMPDIR/env/bin/activate
pip install --no-index --upgrade pip

pip install --no-index torch
pip install --no-index torchvision
pip install --no-index pillow
pip install --no-index matplotlib
pip install --no-index scikit-learn
pip install --no-index timm

# ---------------------------------------------------------------------------------------------
echo "Install SAM2"
# ---------------------------------------------------------------------------------------------

# install SAM2
cd $SLURM_TMPDIR
cp -r $HOME/MicroNuclei/sam2 .
cd sam2
pip install -e .

# ---------------------------------------------------------------------------------------------
echo "Install mn detection packge"
# ---------------------------------------------------------------------------------------------

# Install package
cd $SLURM_TMPDIR
cp -r $HOME/MicroNuclei/MicroNuclei_Detection . # Use the local copy (Jun 22, 2025) for reproducibility
cd MicroNuclei_Detection
pip install --no-index -e .

# ---------------------------------------------------------------------------------------------
echo "Prepare data"
# ---------------------------------------------------------------------------------------------

# mkdir work
# cd work
# tar -xf /home/y3229wan/scratch/MCF10A.tar
# Now do my computations here on the local disk using the contents of the extracted archive...

# ---------------------------------------------------------------------------------------------
echo "Start main process"
# ---------------------------------------------------------------------------------------------

# Run the main python script. 
# The arguments should be 
#       the folder for the input images (png, tif)
#       the final json file name
#       the process mode (ALL for both nuc and mn, NUC for only nuclei, MN for only micronuclei)
# Example:
#       >>> python image_process.sh /home/scratch/test test.json ALL

cd $SLURM_TMPDIR
python $HOME/MicroNuclei_work/python/script/image_process.py \
    --src $1 \
    --dst $2 \
    --mode $3 \
    --conf 0.7

       
# ---------------------------------------------------------------------------------------------
echo "Save output"
# ---------------------------------------------------------------------------------------------

deactivate

# The computations are done, so clean up the data set...
# cd $SLURM_TMPDIR
# tar -cf ~/scratch/rep3_10000_processed.tar work/

