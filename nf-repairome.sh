#!/bin/bash
#SBATCH --job-name=nf_repairome
#SBATCH --output=logs/nf_%j.log
#SBATCH --error=logs/nf_%j.err
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=24:00:00

# 1. Activate conda environment containing nextflow
source "$HOME/miniforge3/etc/profile.d/conda.sh"
conda activate repairome

# Fallback for CELL if completely unset
CELL="${CELL:-Data1}"

# 2. Run Nextflow
cd /storage/scratch01/users/tpyang/tdb/repairome

nextflow run /storage/scratch01/users/tpyang/dev/nf-repairome/main.nf \
    --samplesheet ${CELL}.tsv \
    --fastq_dir /storage/scratch01/users/tpyang/tdb/repairome/fastq \
    --outdir /storage/scratch01/users/tpyang/tdb/repairome/data \
    -profile slurm