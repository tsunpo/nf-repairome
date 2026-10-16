nextflow.enable.dsl = 2

/*
========================================================================================
    Pipeline Parameters
========================================================================================
*/
params.samplesheet = null
params.fastq_dir   = null
params.outdir      = null
params.help        = false

def helpMessage() {
    log.info """
    ===================================================================
    REPAIRome Analysis Pipeline (Nextflow 26+ Compatible)
    ===================================================================
    Usage:
        nextflow run main.nf --samplesheet <file.tsv> --fastq_dir <path> --outdir <path> [options]

    Mandatory arguments:
        --samplesheet    Path to tab-delimited samplesheet (e.g., Data1.tsv)
        --fastq_dir      Directory containing raw FASTQ files
        --outdir         Path to save pipeline outputs

    Options:
        -profile         Execution profile (e.g., slurm, standard)
        -resume          Resume previous run execution
    ===================================================================
    """.stripIndent()
}

if (params.help) {
    helpMessage()
    exit 0
}

if (!params.samplesheet) {
    error "Missing required parameter: --samplesheet"
}
if (!params.fastq_dir) {
    error "Missing required parameter: --fastq_dir"
}
if (!params.outdir) {
    error "Missing required parameter: --outdir"
}

/*
========================================================================================
    Channel Creation & Input Pairing
    (Fixes Error main.nf:163: `for` loops are no longer supported)
========================================================================================
*/

ch_samples = Channel
    .fromPath(params.samplesheet)
    .splitCsv(header: true, sep: '\t')
    .map { row ->
        def sample_id = row.sample ?: row.sample_id ?: row.id

        // Candidate naming conventions for Read 1 and