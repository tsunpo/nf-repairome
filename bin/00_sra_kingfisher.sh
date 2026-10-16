#!/bin/bash
#SBATCH --job-name=sra_kingfisher
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=12:00:00

set -eo pipefail

mkdir -p logs

if [ -f "$HOME/miniforge3/etc/profile.d/conda.sh" ]; then
    source "$HOME/miniforge3/etc/profile.d/conda.sh"
    conda activate repairome
fi

if [ -z "${ACC}" ]; then
    echo "Error: Variable ACC is not set. Use --export=ALL,ACC=<accession>" >&2
    exit 1
fi

echo "Starting download for ${ACC} on $(hostname)"

kingfisher get \
  -r "${ACC}" \
  -m aws-http ena-ftp prefetch \
  -f fastq.gz \
  --download-threads "${SLURM_CPUS_PER_TASK:-4}"

echo "Finished ${ACC} with exit code $?"