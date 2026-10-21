# nf-repairome

Nextflow implementation of the REPAIRome pipeline [https://zenodo.org/records/15095299]

## Table of Contents
- [Installation](#installation)
- [Usage](#usage)
  - [FASTQ files](#fastq-files)
  - [Samplesheet](#samplesheet)
  - [Run](#run)
  - [Output](#output)
- [Troubleshooting](#troubleshooting)
  - [Empty 0-byte output guides file](#empty-0-byte-output-guides-file)
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
# Create the `repairome` Conda environment and install required packages 
conda create -n repairome \
  -c conda-forge \
  -c bioconda \
  --override-channels \
  openjdk=17 trimmomatic bowtie2 samtools python=3.10 swalign pandas numpy matplotlib seaborn dask pyarrow kingfisher "sra-tools>=3.0.8" nextflow -y

# Activate the Conda environment
conda activate repairome
```

## Usage

This section demonstrates how to run the example dataset provided with the workflow.

### FASTQ files

The example FASTQ files (`R1` and `R2`) are located in the following directory:

```
projects
└── fastq
    ├── Data1_1.fastq.gz
    └── Data1_2.fastq.gz
```

### Samplesheet

The samplesheet requires four tab-delimited columns: `<CELL_LINE_NAME>` `<CUT_POSITION>` `<EXPERIMENTAL_REPLICATE>` `<FASTQ_FILE_NAME>`.

For example, the samplesheet used to process our published RPE1 dataset (`projects/RPE1.tsv`) is structured as follows:

```text
RPE1	Cut1	Rep1	SRR29304328
RPE1	Cut1	Rep2	SRR29304327
RPE1	Cut2	Rep1	SRR29304326
RPE1	Cut2	Rep2	SRR29304325
RPE1	Cut3	Rep1	SRR29304324
RPE1	Cut3	Rep2	SRR29304323
```

For testing, an example samplesheet (`Data1.tsv`) is provided under:

```
projects
└── Data1.tsv
```

The `<CUT_POSITION>` and `<EXPERIMENTAL_REPLICATE>` columns can be set to `NA` if unavailable:

```text
Data1	NA	NA	Data1
```

### Run

Execute the test dataset using Nextflow:

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

`nf-repairome` automatically generates the output directories matching the samplesheet.

For the RPE1 dataset:

```
projects
└── data
    └── RPE1
        ├── Cut1
        │   ├── RPE1_Cut1_Rep1_guides.txt
        │   ├── RPE1_Cut1_Rep1_indel
        │   ├── RPE1_Cut1_Rep1_proc
        │   ├── RPE1_Cut1_Rep2_guides.txt
        │   ├── RPE1_Cut1_Rep2_indel
        │   └── RPE1_Cut1_Rep2_proc
        ├── Cut2
        │   ├── RPE1_Cut2_Rep1_guides.txt
        │   ├── RPE1_Cut2_Rep1_indel
        │   ├── RPE1_Cut2_Rep1_proc
        │   ├── RPE1_Cut2_Rep2_guides.txt
        │   ├── RPE1_Cut2_Rep2_indel
        │   └── RPE1_Cut2_Rep2_proc
        ...
```

For the example run using `Data1.tsv`:

```
projects
└── data
    └── Data1
        ├── Data1_guides.txt
        ├── Data1_indel
        └── Data1_proc
```

## Troubleshooting

### Empty 0-byte output guides file

After running Step 1 (`ALIGN_GUIDES_R1`) to align Read 1 reads (sgRNA) against the Toronto KnockOut (TKOv3) guides library, , `RPE1_Cut1_Rep1_guides.txt` was generated as a 0-byte file:

```text
   0 Oct 20 16:52 RPE1_Cut1_Rep1_guides.txt
3.4G Oct 20 21:38 RPE1_Cut1_Rep1_indel
2.7G Oct 20 21:38 RPE1_Cut1_Rep1_proc
 10G Oct 20 18:16 RPE1_Cut1_Rep2_guides.txt
5.7G Oct 21 00:32 RPE1_Cut1_Rep2_indel
4.0G Oct 21 00:32 RPE1_Cut1_Rep2_proc
```

To investigate why `ALIGN_GUIDES_R1` failed for this sample, check the execution sandbox logs in the Nextflow work directory:

```bash
# Search .nextflow.log for the ALIGN_GUIDES_R1 task work directory hash
grep "ALIGN_GUIDES_R1" .nextflow.log

# Navigate directly to the task work directory for RPE1_Cut1_Rep1
cd /storage/scratch01/groups/tdb/topology_and_estrogen_mol_cell/repairome/work/e0/705d1a93a5411fd1b5feff27f0ed1e

# Verify the file size
ls -lh RPE1_Cut1_Rep1_guides.txt

# Inspect stdout and stderr logs to diagnose early process termination
cat .command.out
cat .command.err
```

Standard error log (`.command.err`)

```bash
TrimmomaticSE: Started with arguments:
 -threads 4 -phred33 SRR29304328_1.fastq.gz RPE1_Cut1_Rep1_trimmed.fastq.gz HEADCROP:26
Input Reads: 136270153 Surviving: 0 (0.00%) Dropped: 136270153 (100.00%)
TrimmomaticSE: Completed successfully
[WARNING] Failed to launch x86-64-v3 version, staying with default
[WARNING] Failed to launch x86-64-v3 version, staying with default
Time loading reference: 00:00:00
Time loading forward index: 00:00:00
Time loading mirror index: 00:00:00
Multiseed full-index search: 00:00:00
0 reads
0.00% overall alignment rate
Time searching: 00:00:01
Overall time: 00:00:01
```

## References
- REPAIRome publication: [https://pubmed.ncbi.nlm.nih.gov/41037600/](https://pubmed.ncbi.nlm.nih.gov/41037600/)
- REPAIRome website: [https://repairome.bioinfo.cnio.es](https://repairome.bioinfo.cnio.es)
- REPAIRome pipeline: [https://zenodo.org/records/15095299](https://zenodo.org/records/15095299)
- SRA depository: [https://www.ncbi.nlm.nih.gov/sra?linkname=bioproject_sra_all&from_uid=1120653](https://www.ncbi.nlm.nih.gov/sra?linkname=bioproject_sra_all&from_uid=1120653)