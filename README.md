# nf-repairome

Nextflow implementation of the REPAIRome pipeline [https://zenodo.org/records/15095299]

## Table of Contents
- [Installation](#installation)
- [Usage](#usage)
  - [FASTQ files](#fastq-files)
  - [Samplesheet](#samplesheet)
  - [Run](#run)
  - [Output](#output)
- [References](#references)

---

## Installation

### Clone and install the nf-repairome workflow

```bash
# Navigate to your workspace directory (e.g., $HOME)
cd $HOME

# Clone the repository via HTTPS
git clone https://github.com/tsunpo/nf-repairome.git

# Enter the workflow directory
cd nf-repairome

# Setup $NF_REPAIROME_CODE
echo 'export NF_REPAIROME_CODE="$HOME/nf-repairome"' >> ~/.bashrc
source ~/.bashrc
```

### Create and activate the Conda environment

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

How to run the example datasets shipped with the workflow.

### FASTQ files

The example FASTQ files (R1 and R2) can be found under this directory:

```
projects/fastq/
├── Data1_1.fastq.gz
├── Data1_2.fastq.gz
```

### Samplesheet

The structure of the samplesheet metadata is <CELL_LINE_NAME> <CUT_POSITION> <EXPERIMENTAL_REPLICATE> <FASTQ_FILE_NAME>. Therefore, the required samplesheet to run our RPE1 datasets will be:

```text
| RPE1 | Cut1 | Rep1 | SRR29304328 |
| RPE1 | Cut1 | Rep2 | SRR29304327 |
| RPE1 | Cut2 | Rep1 | SRR29304326 |
| RPE1 | Cut2 | Rep2 | SRR29304325 |
| RPE1 | Cut3 | Rep1 | SRR29304324 |
| RPE1 | Cut3 | Rep2 | SRR29304323 |
```

For this manual, the example samplesheet Data1.tsv can be found here:

```
projects/
├── Data1.tsv
```

These two coulmns <CUT_POSITION> and <EXPERIMENTAL_REPLICATE> in the samplesheet can be NA.

```
| Data1 | NA | NA | Data1 |
```

### Run

```bash
# Enter the projects directory
cd projects

# Launch Nextflow
nextflow run "$NF_REPAIROME_CODE/main.nf" \
    --samplesheet Data1.tsv \
    --fastq_dir "$NF_REPAIROME_CODE/fastq" \
    --outdir "$NF_REPAIROME_CODE/data" \
    -profile slurm \
    -resume

```

### Output

nf-repairome will automatically generate the directories according to the input samplesheet. For example, for our RPE1 datasets:

```
projects/data/RPE1/Cut1
├── RPE1_Cut1_Rep1_guides.txt
├── RPE1_Cut1_Rep1_indel
├── RPE1_Cut1_Rep1_proc
├── RPE1_Cut1_Rep2_guides.txt
├── RPE1_Cut1_Rep2_indel
├── RPE1_Cut1_Rep2_proc
├── ...
projects/data/RPE1/Cut2
├── RPE1_Cut2_Rep1_guides.txt
├── RPE1_Cut2_Rep1_indel
├── RPE1_Cut2_Rep1_proc
├── RPE1_Cut2_Rep2_guides.txt
├── RPE1_Cut2_Rep2_indel
├── RPE1_Cut2_Rep2_proc
├── ...
...
```

For this manual, after running the example samplesheet Data1.tsv:

```
projects/data/Data1
├── Data1_guides.txt
├── Data1_indel
├── Data1_proc
├── ...
```

## Reference

REPAIRome pulication [https://pubmed.ncbi.nlm.nih.gov/41037600/]

REPAIRome website [https://repairome.bioinfo.cnio.es]

REPAIRome pipeline [https://zenodo.org/records/15095299]

REPAIRome SRA depository [https://www.ncbi.nlm.nih.gov/sra?linkname=bioproject_sra_all&from_uid=1120653]