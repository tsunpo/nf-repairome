#!/bin/bash
#SBATCH --job-name=nf_repairome
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=24:00:00

# 1. Source user environment and activate conda
source "$HOME/miniforge3/etc/profile.d/conda.sh"
conda activate repairome

# 2. Identify target CELL and base execution directory
CELL="${CELL:-Data1}"
RUN_DIR="$(pwd)"

mkdir -p "${RUN_DIR}/logs"
cd "${RUN_DIR}"

echo "=========================================================="
echo "Job ID:        ${SLURM_JOB_ID}"
echo "CELL / Run ID: ${CELL}"
echo "Base Directory:${RUN_DIR}"
echo "Samplesheet:   ${RUN_DIR}/${CELL}.tsv"
echo "FASTQ Dir:     ${RUN_DIR}/fastq"
echo "Output Dir:    ${RUN_DIR}/data"
echo "Pipeline Code: ${NF_REPAIROME_CODE}"
echo "=========================================================="

# 3. Launch Nextflow with paths anchored to the current directory
nextflow run "${NF_REPAIROME_CODE}/main.nf" \
    --samplesheet "${RUN_DIR}/${CELL}.tsv" \
    --fastq_dir   "${RUN_DIR}/fastq" \
    --outdir      "${RUN_DIR}/data" \
    -profile slurm \
    -resume