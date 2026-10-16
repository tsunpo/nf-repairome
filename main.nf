nextflow.enable.dsl = 2

/*
 * Default parameters (can be overridden via CLI or nextflow.config)
 */
params.samplesheet = "Data1.tsv"
params.fastq_dir   = "./fastq"
params.outdir      = "./data"
params.code_dir    = "${projectDir}"
params.bt2_index   = "${params.code_dir}/index/guides_ext"
params.scripts_dir = "${params.code_dir}/scripts"

/*
 * Process 1: Align R1 Guides
 */
process ALIGN_GUIDES_R1 {
    tag "${meta_id}"
    publishDir "${params.outdir}/${cell_dir}", mode: 'copy', pattern: "*_guides.txt"

    input:
    tuple val(meta_id), val(cell), val(cut), val(rep), val(cell_dir), path(r1_fastq)
    path bt2_files

    output:
    tuple val(meta_id), val(cell), val(cut), val(rep), val(cell_dir), path("${meta_id}_guides.txt"), emit: guides

    script:
    // Extract Bowtie2 index prefix from the staged files
    def bt2_base = bt2_files[0].name.replaceAll(/\.[0-9]+\.bt2$|\.rev\.[0-9]+\.bt2$/, '')
    """
    # 1. Trim 5' flanking vector sequence
    trimmomatic SE -threads ${task.cpus} -phred33 \\
        ${r1_fastq} \\
        ${meta_id}_trimmed.fastq.gz \\
        HEADCROP:26

    # 2. Align to TKOv3 guide pseudo-genome
    bowtie2 -x ${bt2_base} \\
        -U ${meta_id}_trimmed.fastq.gz \\
        -p ${task.cpus} --no-unal -t \\
        -S ${meta_id}.sam

    rm -f ${meta_id}_trimmed.fastq.gz

    # 3. Extract read ID and matched sgRNA (skipping Bowtie2 SAM headers)
    tail -n +71093 ${meta_id}.sam | cut -f 1,3 > ${meta_id}_guides.txt
    rm -f ${meta_id}.sam
    """
}

/*
 * Process 2: Analyze R2 Indels
 */
process ANALYSIS_INDELS_R2 {
    tag "${meta_id}"
    publishDir "${params.outdir}/${cell_dir}", mode: 'copy', pattern: "*_{proc,indel}"

    input:
    tuple val(meta_id), val(cell), val(cut), val(rep), val(cell_dir), path(r2_fastq)
    path script_file

    output:
    tuple val(meta_id), path("${meta_id}_proc"), path("${meta_id}_indel"), emit: indels

    script:
    // Determine cut site anchor offset dynamically based on Cut or Cell
    def cut_pos = 140
    if (cut == 'Cut2' || cell == 'U2OS' || cut == 'U2OS') {
        cut_pos = 115
    } else if (cut == 'Cut3') {
        cut_pos = 101
    }

    """
    mkdir -p tmp_chunks

    # 1. Split FASTQ into 3,000,000-line chunks
    zcat ${r2_fastq} | split -l 3000000 - tmp_chunks/chunk_

    # 2. Process chunks in parallel across allocated cores
    ls -1 tmp_chunks/chunk_* | xargs -n 1 -P ${task.cpus} -I {} python ${script_file} {} "${cut_pos}"

    # 3. Concatenate chunk results
    cat tmp_chunks/*_proc > ${meta_id}_proc
    cat tmp_chunks/*_indel > ${meta_id}_indel

    rm -rf tmp_chunks
    """
}

/*
 * Process 3: Create Matrix
 */
process CREATE_MATRIX {
    tag "${meta_id}"
    publishDir "${params.outdir}/${cell_dir}", mode: 'copy'

    input:
    tuple val(meta_id), val(cell), val(cut), val(rep), val(cell_dir), path(guides), path(proc), path(indel)
    path script_file

    output:
    tuple val(meta_id), path("${meta_id}*"), emit: results

    script:
    """
    python ${script_file} \\
        "${meta_id}" \\
        "${meta_id}" \\
        "${meta_id}" \\
        "${meta_id}"
    """
}

/*
 * Workflow
 */
workflow {
    // Stage Bowtie2 index files as a collective value channel
    ch_bt2_index   = Channel.fromPath("${params.bt2_index}*.bt2").collect()
    
    // Stage Python scripts as reusable value channels so multiple tasks don't deplete them
    ch_indel_script  = Channel.value(file("${params.scripts_dir}/analysis_INDELS.py"))
    ch_matrix_script = Channel.value(file("${params.scripts_dir}/create_matrix.py"))

    // Parse samplesheet and locate corresponding FASTQ files
    ch_samples = Channel
        .fromPath(params.samplesheet)
        .splitCsv(sep: ' ', strip: true)
        .filter { row -> row[0] && !row[0].startsWith('#') }
        .map { row ->
            def cell = row[0].trim()
            def cut  = (row.size() > 1 && row[1] && row[1] != 'NA' && row[1] != '-') ? row[1].trim() : ''
            def rep  = (row.size() > 2 && row[2] && row[2] != 'NA' && row[2] != '-') ? row[2].trim() : ''
            def sra  = (row.size() > 3 && row[3] && row[3] != 'NA' && row[3] != '-') ? row[3].trim() : ''

            // Target output subdirectory hierarchy
            def cell_dir = cut ? "${cell}/${cut}" : "${cell}"

            // Construct sample identifier prefix
            def name_exp = cell
            if (cut) name_exp += "_${cut}"
            if (rep) name_exp += "_${rep}"

            // Look up R1 and R2 fastq files across naming variations
            def r1 = null
            def r2 = null

            def r1_candidates = [
                "${params.fastq_dir}/${sra}_R1.fastq.gz",
                "${params.fastq_dir}/${name_exp}_R1.fastq.gz",
                "${params.fastq_dir}/${sra}_1.fastq.gz",
                "${params.fastq_dir}/${name_exp}_1.fastq.gz",
                "${params.fastq_dir}/${sra}.fastq.gz"
            ]
            def r2_candidates = [
                "${params.fastq_dir}/${sra}_R2.fastq.gz",
                "${params.fastq_dir}/${name_exp}_R2.fastq.gz",
                "${params.fastq_dir}/${sra}_2.fastq.gz",
                "${params.fastq_dir}/${name_exp}_2.fastq.gz"
            ]

            for (p in r1_candidates) { if (file(p).exists()) { r1 = file(p); break } }
            for (p in r2_candidates) { if (file(p).exists()) { r2 = file(p); break } }

            if (!r1 || !r2) {
                error "FASTQ files for ${name_exp} (SRA: ${sra}) could not be found in ${params.fastq_dir}"
            }

            return tuple(name_exp, cell, cut, rep, cell_dir, r1, r2)
        }

    // Split input stream into R1 and R2 channels
    ch_r1 = ch_samples.map { name_exp, cell, cut, rep, cell_dir, r1, r2 ->
        tuple(name_exp, cell, cut, rep, cell_dir, r1)
    }

    ch_r2 = ch_samples.map { name_exp, cell, cut, rep, cell_dir, r1, r2 ->
        tuple(name_exp, cell, cut, rep, cell_dir, r2)
    }

    // Step 1: Align R1 reads
    ALIGN_GUIDES_R1(ch_r1, ch_bt2_index)

    // Step 2: Analyze R2 Indel scars
    ANALYSIS_INDELS_R2(ch_r2, ch_indel_script)

    // Step 3: Combine R1 guides and R2 indels by sample ID (meta_id)
    ch_matrix_input = ALIGN_GUIDES_R1.out.guides
        .map { meta_id, cell, cut, rep, cell_dir, guides -> 
            tuple(meta_id, [cell, cut, rep, cell_dir, guides]) 
        }
        .join(ANALYSIS_INDELS_R2.out.indels)
        .map { meta_id, meta_info, proc, indel ->
            tuple(meta_id, meta_info[0], meta_info[1], meta_info[2], meta_info[3], meta_info[4], proc, indel)
        }

    // Step 4: Create matrices
    CREATE_MATRIX(ch_matrix_input, ch_matrix_script)
}