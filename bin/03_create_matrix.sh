#!/bin/bash
#SBATCH --job-name=03_create_matrix
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=01:00:00

# 1. Initialize Conda environment
source "$HOME/miniforge3/etc/profile.d/conda.sh"
conda activate repairome

# 2. Directory and sample variables
CODE_DIR="$HOME/tdb/repairome/code"
SCRATCH_BASE="/storage/scratch01/users/tpyang/tdb/repairome/data"

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

GUIDES_FILE="${DATA_DIR}/${name_exp}_guides.txt"
PROC_FILE="${DATA_DIR}/${name_exp}_proc"
INDEL_FILE="${DATA_DIR}/${name_exp}_indel"
OUT_PREFIX="${DATA_DIR}/${name_exp}"

echo "=== Running Matrix Generation: $SLURM_JOB_ID ==="
echo "Cell line:     ${CELL}"
echo "Cut:           ${CUT:-(none)}"
echo "Replicate:     ${REP:-(none)}"
echo "Experiment:    ${name_exp}"
echo "Data dir:      ${DATA_DIR}"
echo "Guides file:   ${GUIDES_FILE}"
echo "Proc file:     ${PROC_FILE}"
echo "Indel file:    ${INDEL_FILE}"
echo "Output prefix: ${OUT_PREFIX}"
echo "==============================================="

# Verify all input files exist
for f in "${GUIDES_FILE}" "${PROC_FILE}" "${INDEL_FILE}"; do
    if [ ! -f "$f" ]; then
        echo "ERROR: Missing required input file: $f" >&2
        exit 1
    fi
done

# 3. Execute matrix creation
python "${CODE_DIR}/scripts/create_matrix.py" \
  "${name_exp}" \
  "${name_exp}" \
  "${name_exp}" \
  "${OUT_PREFIX}"

echo "=== Step 3 Completed Successfully ==="