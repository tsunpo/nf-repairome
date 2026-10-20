# nf-repairome

Nextflow implementation of the REPAIRome pipeline [[https://zenodo.org/records/15095299](https://zenodo.org/records/15095299)]

## Table of Contents
- [Installation](#installation)
- [References](#references)

---

## Installation

### Clone and install the nf-repairome repository

```bash
# Navigate to your workspace directory (e.g., $HOME)
cd $HOME

# Clone the repository via HTTPS
git clone https://github.com/tsunpo/nf-repairome.git

# Enter the pipeline directory
cd nf-repairome

# Setup $REPAIROME_CODE
echo 'export REPAIROME_CODE="$HOME/nf-repairome"' >> ~/.bashrc
source ~/.bashrc
```

### Create and activate the `repairome` Conda environment

```bash
conda create -n repairome \
  -c conda-forge \
  -c bioconda \
  --override-channels \
  openjdk=17 trimmomatic bowtie2 samtools python=3.10 swalign pandas numpy matplotlib seaborn dask pyarrow kingfisher "sra-tools>=3.0.8" nextflow -y

conda activate repairome
```