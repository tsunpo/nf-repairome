nextflow.enable.dsl = 2

/*
========================================================================================
    Pipeline Parameters
========================================================================================
*/
params.samplesheet = params.samplesheet ?: "${launchDir}/${params.cell ?: 'Data1'}.tsv"
params.fastq_dir   = params.fastq_dir   ?: "${launchDir}/fastq"
params.outdir      = params.outdir      ?: "${launchDir}/data"
params.code_dir    = params.code_dir    ?: "${projectDir}"
params.bt2_index   = params.bt2_index   ?: "${params.code_dir}/index/guides_ext"
params.scripts_dir = params.scripts_dir ?: "${params.code_dir}/scripts"

/*
========================================================================================
    Processes
========================================================================================
*/

// Step 1: Align R1 guide reads (from 01_align_guides_R1.sh)
process ALIGN_GUIDES_R1 {
    tag "${meta.id}"
    publishDir path: { "${params.outdir}/${meta.target_subpath}" }, mode: 'copy', pattern: "*_guides.txt"

    input:
    tuple val(meta), path(r1_fastq), path(r2_fastq)
    path bt2_index_files

    output:
    tuple val(meta), path("${meta.name_exp}_guides.txt"), emit: guides

    script:
    def bt2_base = "${bt2_index_files[0]}".replaceAll(/(\.rev)?\.[0-9]+\.bt2$/, '')
    """
    set -euo pipefail

    # 1. Trim 5' flanking vector sequence
    trimmomatic SE -threads 4 -phred33 \
        "${r1_fastq}" \
        "${meta.name_exp}_trimmed.fastq.gz" \
        HEADCROP:0

    # 2. Align to guide pseudo-genome
    bowtie2 -x "${bt2_base}" \
        -U "${meta.name_exp}_trimmed.fastq.gz" \
        -p 6 --no-unal -t \
        -S "${meta.name_exp}.sam"

    rm -f "${meta.name_exp}_trimmed.fastq.gz"

    # 3. Extract read ID and matched sgRNA (skipping SAM header)
    tail -n +71093 "${meta.name_exp}.sam" | cut -f 1,3 > "${meta.name_exp}_guides.txt"
    rm -f "${meta.name_exp}.sam"
    """
}

// Step 2: Indel analysis on R2 reads (from 02_analysis_indels_R2.sh)
process ANALYSIS_INDELS_R2 {
    tag "${meta.id}"
    publishDir path: { "${params.outdir}/${meta.target_subpath}" }, mode: 'copy', pattern: "*_{proc,indel}"

    input:
    tuple val(meta), path(r1_fastq), path(r2_fastq)

    output:
    tuple val(meta), path("${meta.name_exp}_proc"), path("${meta.name_exp}_indel"), emit: indels

    script:
    """
    set -euo pipefail
    mkdir -p tmp_chunks
    rm -f tmp_chunks/*

    # Split FASTQ into 1,000,000-line chunks (~250k reads) to keep Python memory usage low
    zcat "${r2_fastq}" | split -l 1000000 - tmp_chunks/chunk_

    # Run indel extraction across chunks with controlled concurrency (6 parallel workers)
    ls -1 tmp_chunks/chunk_* | xargs -n 1 -P 6 -I {} python "${params.scripts_dir}/analysis_INDELS.py" {} "${meta.cut_pos}"

    # Concatenate chunk results
    cat tmp_chunks/*_proc > "${meta.name_exp}_proc"
    cat tmp_chunks/*_indel > "${meta.name_exp}_indel"

    rm -rf tmp_chunks
    """
}

// Step 3: Combine outputs to build matrix (from 03_create_matrix.sh)
process CREATE_MATRIX {
    tag "${meta.id}"
    publishDir path: { "${params.outdir}/${meta.target_subpath}" }, mode: 'copy'

    input:
    tuple val(meta), path(guides_file), path(proc_file), path(indel_file)

    output:
    tuple val(meta), path("${meta.name_exp}_*.{txt,tsv,csv,matrix}*"), emit: results, optional: true

    script:
    """
    set -euo pipefail

    python "${params.scripts_dir}/create_matrix.py" \
        "${meta.name_exp}" \
        "${meta.name_exp}" \
        "${meta.name_exp}" \
        "${meta.name_exp}"
    """
}

/*
========================================================================================
    Workflow Execution
========================================================================================
*/

workflow {

    // Bowtie2 index files collect channel
    ch_bt2_index = Channel.fromPath("${params.bt2_index}.*.bt2").collect()

    // Step 0: Parse samplesheet table (Data1.tsv / Data1.txt)
    ch_samples = Channel
        .fromPath(params.samplesheet)
        .splitCsv(header: false, sep: '\t')
        .map { row ->
            def cell = (row[0] ?: "").trim().replaceAll(/\r/, "")
            def cut  = (row.size() > 1 && row[1] ? row[1].trim() : "").replaceAll(/\r/, "")
            def rep  = (row.size() > 2 && row[2] ? row[2].trim() : "").replaceAll(/\r/, "")
            def sra  = (row.size() > 3 && row[3] ? row[3].trim() : "").replaceAll(/\r/, "")

            // Ignore header or blank rows
            if (!cell || cell.startsWith('#')) return null

            // Treat NA or dash as empty
            cut = (cut in ["NA", "-", ""]) ? "" : cut
            rep = (rep in ["NA", "-", ""]) ? "" : rep
            sra = (sra in ["NA", "-", ""]) ? "" : sra

            // Target directory structure and experiment prefix
            def target_subpath = cut ? "${cell}/${cut}" : "${cell}"
            def name_exp = cell
            if (cut) name_exp += "_${cut}"
            if (rep) name_exp += "_${rep}"

            // Determine cut position based on cut site
            def cut_pos = 140
            if (cut == "Cut2" || cut == "U2OS") {
                cut_pos = 115
            } else if (cut == "Cut3") {
                cut_pos = 101
            }

            // Direct file targeting for ${sample_id}_1.fastq.gz and _2.fastq.gz
            def prefix = sra ?: name_exp
            def r1_path = file("${params.fastq_dir}/${prefix}_1.fastq.gz")
            def r2_path = file("${params.fastq_dir}/${prefix}_2.fastq.gz")

            // Check if R1 exists
            if (!r1_path.exists()) {
                error "Missing R1 FASTQ file: ${r1_path}"
            }

            def meta = [
                id: name_exp,
                cell: cell,
                cut: cut,
                rep: rep,
                name_exp: name_exp,
                cut_pos: cut_pos,
                target_subpath: target_subpath
            ]

            tuple(meta, r1_path, r2_path)
        }
        .filter { it != null }

    // Step 1 & Step 2 execute in parallel
    ch_guides = ALIGN_GUIDES_R1(ch_samples, ch_bt2_index)
    ch_indels = ANALYSIS_INDELS_R2(ch_samples)

    // Join outputs by sample meta
    ch_step3_inputs = ch_guides.guides
        .join(ch_indels.indels)
        .map { meta, guides, proc, indel ->
            tuple(meta, guides, proc, indel)
        }

    // Step 3 executes when both Step 1 & 2 are complete for that sample
    CREATE_MATRIX(ch_step3_inputs)
}