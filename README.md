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
  - [Unexpectedly short 25-nt read length in SRA download](#unexpectedly-short-25-nt-read-length-in-sra-download)
- [References](#references)

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
    --fastq_dir fastq \
    --outdir data \
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

After running Step 1 (`ALIGN_GUIDES_R1`) to align Read 1 reads (sgRNA) against the Toronto KnockOut (TKOv3) guides library, `RPE1_Cut1_Rep1_guides.txt` was generated as a 0-byte file:

```diff
-   0 RPE1_Cut1_Rep1_guides.txt
 3.4G RPE1_Cut1_Rep1_indel
 2.7G RPE1_Cut1_Rep1_proc
  10G RPE1_Cut1_Rep2_guides.txt
 5.7G RPE1_Cut1_Rep2_indel
 4.0G RPE1_Cut1_Rep2_proc
- 19K RPE1_Cut2_Rep1_guides.txt
 3.6G RPE1_Cut2_Rep1_indel
 2.4G RPE1_Cut2_Rep1_proc
  11G RPE1_Cut2_Rep2_guides.txt
 6.2G RPE1_Cut2_Rep2_indel
 3.8G RPE1_Cut2_Rep2_proc
  13G RPE1_Cut3_Rep1_guides.txt
 6.8G RPE1_Cut3_Rep1_indel
 4.5G RPE1_Cut3_Rep1_proc
-   0 RPE1_Cut3_Rep2_guides.txt
 2.9G RPE1_Cut3_Rep2_indel
 2.4G RPE1_Cut3_Rep2_proc
```

To investigate why `ALIGN_GUIDES_R1` failed on this read, check the execution sandbox logs in the Nextflow work directory:

```bash
# Search .nextflow.log for the ALIGN_GUIDES_R1 task work directory
cd /storage/scratch01/groups/tdb/repairome
grep "ALIGN_GUIDES_R1" .nextflow.log

# Navigate directly to the task work directory for RPE1_Cut1_Rep1
cd /storage/scratch01/groups/tdb/repairome/work/e0/705d1a93a5411fd1b5feff27f0ed1e

# Verify the file size
ls -lh RPE1_Cut1_Rep1_guides.txt

# Inspect stdout and stderr log files
cat .command.out
cat .command.err
```

Standard error log file (`.command.err`)

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

To confirm that Read 1 is longer than 26 nt and spans the expected 5' vector sequence before trimming.

```bash
# Enter the FASTQ directory
cd /storage/scratch01/groups/tdb/repairome/fastq

# Run Trimmomatic on Read 1
trimmomatic SE -threads 4 -phred33 \
  SRR29304328_1.fastq.gz \
  SRR29304328_1_trimmed.fastq.gz \
  HEADCROP:26
```

The output confirms that Trimmomatic dropped 100% of the input reads (`Surviving: 0 (0.00%)`) during the 5' vector trimming step:

```bash
TrimmomaticSE: Started with arguments:
 -threads 4 -phred33 SRR29304328_1.fastq.gz SRR29304328_1_trimmed.fastq.gz HEADCROP:26
Input Reads: 136270153 Surviving: 0 (0.00%) Dropped: 136270153 (100.00%)
TrimmomaticSE: Completed successfully
```

### Unexpectedly short 25-nt read length in SRA download

It appears that the format of `SRR29304328_1.fastq.gz` (Cut1 / Rep1 / R1) differs from the others, and its reads are only 25 nt long:

```txt
@SRR29304328.2 NB552185:234:H2HYJAFX5:1:11101:6878:1028/1
NTATGAAGTGCATGTCAGCGGGTTT
+
AAAAAEEEEEEEEEEEEEEEEEEE/
...
```

For comparison, the format of `SRR29304327_1.fastq.gz` (Cut1 / Rep2 / R1) is:

```txt
@SRR29304327.4 A01188:61:HMLGCDRX2:1:2101:19190:1000 length=28
GNATGATTCACAGATTCCAGGTTTTAGA
+SRR29304327.4 A01188:61:HMLGCDRX2:1:2101:19190:1000 length=28
F#:FFFFFF:FFFFFFFFFFFFFFF:FF
...
```

Similarly, `SRR29304323_1.fastq.gz` (Cut3 / Rep2 / R1), which generates another 0-byte output guides file, contains also 25-nt reads:

```txt
@SRR29304323.1 NB552185:270:HCCJYAFX5:1:11101:18181:1015 length=25
TACCGNATTGCCAGGCACCTCGCCC
+SRR29304323.1 NB552185:270:HCCJYAFX5:1:11101:18181:1015 length=25
AAAAA#EEEEEEEEEEEEEEEEEEE
...
```

Although the output guides file from `SRR29304326_1.fastq.gz` (Cut2 / Rep1 / R1) is not empty, its file size is only 19K (see above):

```txt
@SRR29304326.1 NB552185:167:H5HMWAFX2:1:11102:5889:1040 length=48
ACAGTTCCAGACCTCACAGGGAATTAGAGATAGATATAGCAAGAGACA
+SRR29304326.1 NB552185:167:H5HMWAFX2:1:11102:5889:1040 length=48
/AAAAEEEEEEEEEEEEEAEA/A/<///6//////////////6///6
...
```

## References
- REPAIRome publication: [https://pubmed.ncbi.nlm.nih.gov/41037600/](https://pubmed.ncbi.nlm.nih.gov/41037600/)
- REPAIRome website: [https://repairome.bioinfo.cnio.es](https://repairome.bioinfo.cnio.es)
- REPAIRome pipeline: [https://zenodo.org/records/15095299](https://zenodo.org/records/15095299)
- SRA depository: [https://www.ncbi.nlm.nih.gov/sra?linkname=bioproject_sra_all&from_uid=1120653](https://www.ncbi.nlm.nih.gov/sra?linkname=bioproject_sra_all&from_uid=1120653)