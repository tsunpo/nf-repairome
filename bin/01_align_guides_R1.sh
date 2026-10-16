#!/bin/bash
#SBATCH --job-name=01_align_guides_R1
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=02:00:00

# 1. Environment initialization
source "$HOME/miniforge3/etc/profile.d/conda.sh"
conda activate repairome

# 2. Base directory configuration
CODE_DIR="$HOME/tdb/repairome/code"
SCRATCH_BASE="/storage/scratch01/users/tpyang/tdb/repairome/data"

# Fallback for CELL if completely unset
CELL="${CELL:-Data1}"

# Treat NA or empty as absent
[ "${CUT:-}" = "NA" ] && CUT=""
[ "${REP:-}" = "NA" ] && REP=""

# Determine directory based on whether CUT is provided
if [ -n "${CUT}" ]; then
  DATA_DIR="${SCRATCH_BASE}/${CELL}/${CUT}"
else
  DATA_DIR="${SCRATCH_BASE}/${CELL}"
fi

# Dynamically construct experiment prefix
name_exp="${CELL}"
[ -n "${CUT}" ] && name_exp="${name_exp}_${CUT}"
[ -n "${REP}" ] && name_exp="${name_exp}_${REP}"

FASTQ_R1="${DATA_DIR}/${name_exp}_R1.fastq.gz"
TRIMMED_R1="${DATA_DIR}/${name_exp}_trimmed.fastq.gz"
SAM_OUT="${DATA_DIR}/${name_exp}.sam"
GUIDES_TXT="${DATA_DIR}/${name_exp}_guides.txt"
BT2_INDEX="${CODE_DIR}/index/guides_ext"

echo "=== Running Job ID: $SLURM_JOB_ID ==="
echo "Cell line:       ${CELL}"
echo "Cut:             ${CUT:-(none)}"
echo "Replicate:       ${REP:-(none)}"
echo "Experiment Name: ${name_exp}"
echo "Input R1 FASTQ:  ${FASTQ_R1}"
echo "Data Directory:  ${DATA_DIR}"
echo "====================================="

# 4. Step 1: Trim 5' flanking vector sequence
trimmomatic SE -threads 4 -phred33 \
  "${FASTQ_R1}" \
  "${TRIMMED_R1}" \
  HEADCROP:26

# 5. Step 2: Align to TKOv3 guide pseudo-genome
bowtie2 -x "${BT2_INDEX}" \
  -U "${TRIMMED_R1}" \
  -p 6 --no-unal -t \
  -S "${SAM_OUT}"

rm -f "${TRIMMED_R1}"

# 6. Step 3: Extract read ID and matched sgRNA (skipping SAM header)
tail -n +71093 "${SAM_OUT}" | cut -f 1,3 > "${GUIDES_TXT}"
rm -f "${SAM_OUT}"

echo "Done. Guide mapping saved to: ${GUIDES_TXT}"