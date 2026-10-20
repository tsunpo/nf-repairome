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

## Usage

How to run the example data shipped with the workflow.

### FASTQ files

The example FASTQ files (R1 and R2) can be found under this directory:

```
projects/fastq/
├── Data1_1.fastq.gz
├── Data1_2.fastq.gz
```

### Metadata

The structure of the metadata is <CELL_LINE_NAME> <CUT_POSITION> <REPLICATE> <FASTQ_FILE_NAME>. Therefore, the metadata to run our RPE1 data will be:

```
| RPE1 | Cut1 | Rep1 | SRR29304328 |
| RPE1 | Cut1 | Rep2 | SRR29304327 |
| RPE1 | Cut2 | Rep1 | SRR29304326 |
| RPE1 | Cut2 | Rep2 | SRR29304325 |
| RPE1 | Cut3 | Rep1 | SRR29304324 |
| RPE1 | Cut3 | Rep2 | SRR29304323 |
```

And the example metadata Data1.tsv for this manual can be found here:

```
projects/
├── Data1.tsv
```

These two coulmns <CUT_POSITION> <REPLICATE> can be NA

```
| Data1 | NA | NA | Data1 |
```

### Run

### nf-repairome will generate the directories according to the metadata
