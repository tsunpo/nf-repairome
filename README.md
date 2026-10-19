# nf-repairome

Nextflow implementation of the REPAIRome pipeline [https://zenodo.org/records/15095299]

# Table of Contents
- [Clone and Install](#clone-and-install-the-nextflow-repairome-repository-onto-your-hpc-directory)
- [References](#references)

---

## Clone and install the NextFlow REPAIRome repository onto your HPC directory

```bash
# Navigate to your working directory
cd <your HPC directory>

# Clone the repository via HTTPS
git clone [https://github.com/tsunpo/nf-repairome.git](https://github.com/tsunpo/nf-repairome.git)

# Enter the pipeline directory
cd nf-repairome

# Setup $REPAIROME_CODE
echo 'export REPAIROME_CODE="<your HPC directory>/nf-repairome"' >> ~/.bashrc
source ~/.bashrc

# Create and activate the `repairome` Conda environment using the following command:
conda create -n repairome \
  -c conda-forge \
  -c bioconda \
  --override-channels \
  openjdk=17 trimmomatic bowtie2 samtools python=3.10 swalign pandas numpy matplotlib seaborn dask pyarrow kingfisher "sra-tools>=3.0.8" nextflow -y

conda activate repairome