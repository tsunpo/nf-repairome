# nf-repairome

Nextflow implementation of the REPAIRome pipeline [https://zenodo.org/records/15095299]

## Table of Contents
- [Installation](#installation)
- [Usage](#usage)
- [References](#references)

---

## Installation

Clone and install the nf-repairome workflow

```bash
# Navigate to your workspace directory (e.g., $HOME)
cd $HOME

# Clone the repository via HTTPS
git clone https://github.com/tsunpo/nf-repairome.git

# Enter the workflow directory
cd nf-repairome

# Setup $REPAIROME_CODE
echo 'export REPAIROME_CODE="$HOME/nf-repairome"' >> ~/.bashrc
source ~/.bashrc
```

Create and activate the Conda environment

```bash
# Create the `repairome` Conda enviroment and install required packages 
conda create -n repairome \
  -c conda-forge \
  -c bioconda \
  --override-channels \
  openjdk=17 trimmomatic bowtie2 samtools python=3.10 swalign pandas numpy matplotlib seaborn dask pyarrow kingfisher "sra-tools>=3.0.8" nextflow -y

# Activate the Conda enviroment
conda activate repairome
```

## Run the example data shipped with the workflow

### Run

### Prepare metadata

### Run

### nf-repairome will generate the directories according to the metadata
