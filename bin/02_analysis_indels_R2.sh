#!/bin/bash
#SBATCH --job-name=02_analysis_indels_R2
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=04:00:00

# 1. Initialize Conda
source "$HOME/miniforge3/etc/profile.d/conda.sh"
conda activate repairome

set -eo pipefail

# 2. Paths and Parameters
CODE_DIR="$HOME/tdb/repairome/code"
SCRATCH_BASE="/storage/scratch01/users/tpyang/tdb/repairome/data"

CELL="${CELL:-Data1}"

# Treat NA or empty as absent
if [ "${CUT:-}" = "NA" ]; then CUT=""; fi
if [ "${REP:-}" = "NA" ]; then REP=""; fi

# Determine directory based on whether CUT is provided
if [ -n "${CUT}" ]; then
  DATA_DIR="${SCRATCH_BASE}/${CELL}/${CUT}"
else
  DATA_DIR="${SCRATCH_BASE}/${CELL}"
fi

# Assign cut position according to cut site
case "${CUT}" in
    Cut1) CUT_POS=140 ;;
    Cut2|U2OS) CUT_POS=115 ;;
    Cut3) CUT_POS=101 ;;
    *) CUT_POS=140 ;;
esac

# Dynamically construct experiment prefix
name_exp="${CELL}"
if [ -n "${CUT}" ]; then
  name_exp="${name_exp}_${CUT}"
fi
if [ -n "${REP}" ]; then
  name_exp="${name_exp}_${REP}"
fi

FASTQ_R2="${DATA_DIR}/${name_exp}_R2.fastq.gz"

# Dynamic tmp directory name (defaults to 'tmp_files' if REP is empty)
if [ -n "${REP}" ]; then
  TMP_DIR="${DATA_DIR}/tmp_files_${REP}"
else
  TMP_DIR="${DATA_DIR}/tmp_files"
fi

mkdir -p "${TMP_DIR}"
rm -f "${TMP_DIR}"/*   # Clear any leftover chunk files from previous aborted runs

echo "=== Running Job ID: $SLURM_JOB_ID ==="
echo "Node:            $(hostname)"
echo "Cell line:       ${CELL}"
echo "Cut:             ${CUT:-(none)}"
echo "Replicate:       ${REP:-(none)}"
echo "Experiment:      ${name_exp}"
echo "Input R2 FASTQ:  ${FASTQ_R2}"
echo "Cut Site Offset: ${CUT_POS}"
echo "Temp Chunks:     ${TMP_DIR}"
echo "Threads:         8 cores (parallel xargs)"
echo "====================================="

if [ ! -f "${FASTQ_R2}" ]; then
    echo "ERROR: Input FASTQ file not found: ${FASTQ_R2}" >&2
    exit 1
fi

# 3. Split FASTQ into 3,000,000-line chunks (~750k reads/chunk)
echo "Splitting R2 FASTQ..."
zcat "${FASTQ_R2}" | split -l 3000000 - "${TMP_DIR}/chunk_"

# 4. Extract indels on all chunks concurrently using 8 cores
echo "Processing chunks in parallel across 8 CPUs..."
ls -1 "${TMP_DIR}"/chunk_* | xargs -n 1 -P 8 -I {} python "${CODE_DIR}/scripts/analysis_INDELS.py" {} "${CUT_POS}"

# 5. Concatenate chunk results
echo "Concatenating results..."
cat "${TMP_DIR}"/*_proc > "${DATA_DIR}/${name_exp}_proc"
cat "${TMP_DIR}"/*_indel > "${DATA_DIR}/${name_exp}_indel"

# 6. Clean up temporary chunks
rm -rf "${TMP_DIR}"

echo "=== Completed ==="
echo "Processed: ${DATA_DIR}/${name_exp}_proc"
echo "Indels:    ${DATA_DIR}/${name_exp}_indel"