#!/bin/bash
#SBATCH --job-name=nf_repairome
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=24:00:00

# 1. Activate conda environment
source "$HOME/miniforge3/etc/profile.d/conda.sh"
conda activate repairome

# 2. Get CELL parameter passed via --export (default to Data1 if not provided)
CELL="${CELL:-Data1}"

# 3. Execution directory & logs setup
RUN_DIR="/storage/scratch01/users/tpyang/tdb/repairome"
mkdir -p "${RUN_DIR}/logs"
cd "${RUN_DIR}"

echo "=========================================================="
echo "Running Nextflow REPAIRome for CELL: ${CELL}"
echo "Samplesheet: ${CELL}.tsv"
echo "Working dir: $(pwd)"
echo "=========================================================="

# 4. Launch Nextflow pipeline
nextflow run /storage/scratch01/users/tpyang/dev/nf-repairome/main.nf \
    --samplesheet "${CELL}.tsv" \
    --fastq_dir /storage/scratch01/users/tpyang/tdb/repairome/fastq \
    --outdir /storage/scratch01/users/tpyang/tdb/repairome/data \
    -profile slurm \
    -ansi-log false \
    -resume