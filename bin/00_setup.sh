#!/bin/bash
set -euo pipefail

# Usage: bash 00_setup.sh Data1.txt [/path/to/downloaded_fastqs]

INPUT_FILE="${1:-Data1.txt}"
SRC_FASTQ_DIR="${2:-/storage/scratch01/users/tpyang/tdb/repairome/fastq}"
BASE_OUT_DIR="/storage/scratch01/users/tpyang/tdb/repairome/data"

if [ ! -f "${INPUT_FILE}" ]; then
  echo "Error: Input metadata file '${INPUT_FILE}' not found." >&2
  exit 1
fi

while read -r CELL CUT REP SRA _rest || [ -n "${CELL:-}" ]; do
  # Skip comments or empty lines
  [[ -z "${CELL:-}" || "${CELL}" =~ ^# ]] && continue

  # Clean whitespace, placeholder dashes, and Windows line endings (\r)
  CELL="$(echo "${CELL}" | tr -d '\r' | xargs)"
  CUT="$(echo "${CUT:-}" | tr -d '\r' | xargs)"
  REP="$(echo "${REP:-}" | tr -d '\r' | xargs)"
  SRA="$(echo "${SRA:-}" | tr -d '\r' | xargs)"

  # Normalize NA and - to empty strings
  [[ "${CUT}" == "NA" || "${CUT}" == "-" ]] && CUT=""
  [[ "${REP}" == "NA" || "${REP}" == "-" ]] && REP=""
  [[ "${SRA}" == "NA" || "${SRA}" == "-" ]] && SRA=""

  # 1. Determine Target Directory (avoid CUT folder if empty or NA)
  if [ -n "${CUT}" ]; then
    TARGET_DIR="${BASE_OUT_DIR}/${CELL}/${CUT}"
  else
    TARGET_DIR="${BASE_OUT_DIR}/${CELL}"
  fi
  mkdir -p "${TARGET_DIR}"

  # 2. Build experiment prefix: e.g. Data1_Cut1_Rep1, Data1_Cut1, or Data1
  name_exp="${CELL}"
  [ -n "${CUT}" ] && name_exp="${name_exp}_${CUT}"
  [ -n "${REP}" ] && name_exp="${name_exp}_${REP}"

  echo "----------------------------------------"
  echo "Setting up:"
  echo "  CELL:        ${CELL}"
  echo "  CUT:         ${CUT:-(none)}"
  echo "  REP:         ${REP:-(none)}"
  echo "  SRA:         ${SRA:-(none)}"
  echo "  Directory:   ${TARGET_DIR}"
  echo "  Target Exp:  ${name_exp}"

  # 3. Handle FASTQ linking / relocation
  for read in R1 R2; do
    target_fastq="${TARGET_DIR}/${name_exp}_${read}.fastq.gz"

    src_file=""
    if [ -n "${SRA}" ] && [ -f "${SRC_FASTQ_DIR}/${SRA}_${read}.fastq.gz" ]; then
      src_file="${SRC_FASTQ_DIR}/${SRA}_${read}.fastq.gz"
    elif [ -f "${SRC_FASTQ_DIR}/${name_exp}_${read}.fastq.gz" ]; then
      src_file="${SRC_FASTQ_DIR}/${name_exp}_${read}.fastq.gz"
    elif [ "$read" == "R1" ] && [ -n "${SRA}" ] && [ -f "${SRC_FASTQ_DIR}/${SRA}_1.fastq.gz" ]; then
      src_file="${SRC_FASTQ_DIR}/${SRA}_1.fastq.gz"
    elif [ "$read" == "R1" ] && [ -f "${SRC_FASTQ_DIR}/${name_exp}_1.fastq.gz" ]; then
      src_file="${SRC_FASTQ_DIR}/${name_exp}_1.fastq.gz"
    elif [ "$read" == "R2" ] && [ -n "${SRA}" ] && [ -f "${SRC_FASTQ_DIR}/${SRA}_2.fastq.gz" ]; then
      src_file="${SRC_FASTQ_DIR}/${SRA}_2.fastq.gz"
    elif [ "$read" == "R2" ] && [ -f "${SRC_FASTQ_DIR}/${name_exp}_2.fastq.gz" ]; then
      src_file="${SRC_FASTQ_DIR}/${name_exp}_2.fastq.gz"
    fi

    if [ -n "${src_file}" ]; then
      ln -sf "${src_file}" "${target_fastq}"
      echo "  Linked -> ${target_fastq}"
    else
      echo "  [Notice] Source FASTQ not found in ${SRC_FASTQ_DIR} for ${read}"
    fi
  done

done < "${INPUT_FILE}"

echo "----------------------------------------"
echo "Directory structure setup completed."