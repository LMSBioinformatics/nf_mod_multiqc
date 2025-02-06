import java.text.DecimalFormat
df = new DecimalFormat("###,###,###,###,###")

process multiqc {
    cpus 1
    memory 4.GB
    time 15.m

    publishDir "${params.outdir}/qc",
        mode: "copy"

    beforeScript "module reset &> /dev/null"
    module params.multiqc._module

    input:
    path(qc_and_logs)
    val(run_info)

    output:
    path "${run_info.id}_multiqc.html", emit: files

    stub:
    "touch ${run_info.id}_multiqc.html"

    script:
    software_versions =
        params._submodules
            .collect { "    ${it}: \"${params[it]._version}\"" }
            .join("\n") +
        "\n" +
        run_info
            .findAll { it.key in ["illumina", "rta"] }
            .collect { "    ${it.key}: \"${it.value}\"" }
            .join("\n")
    report_header_info =
        run_info
            .findAll { !(it.key in ["id", "experiment_name", "illumina", "rta"]) }
            .collect { k, v ->
                try { v = df.format(v.toInteger()) } catch(Exception e) { ; }
                "    - ${k}: \"${v}\"" }
            .join("\n")

    """
cat > multiqc_config.yaml << EOF
title: ${run_info.id}
subtitle: ${run_info.experiment_name}
intro_text: False
custom_logo: ${workflow.projectDir}/modules/multiqc/assets/mrc_lms.png
custom_logo_url: "https://lms.mrc.ac.uk"
custom_logo_title: "MRC Laboratory of Medical Sciences"
no_version_check: True
show_analysis_paths: False
show_analysis_time: False
remove_sections:
    - fastqc_per_sequence_quality_scores
    - fastqc_per_base_n_content
    - fastqc_status_checks
    - fastqc_overrepresented_sequences
extra_fn_clean_exts:
    - ".sourmash"
    - ".bowtie2"
    - ".hisat2"
    - ".bwa"
    - ".star"
table_columns_name:
    Sourmash:
        "% Top 5": "% Classified"
custom_table_header_config:
    general_stats_table:
        total_sequences:
            format: "{:,.0f}"
decimalPoint_format: "."
thousandsSep_format: ","
read_count_multiplier: 1
read_count_prefix: ""
read_count_desc: ""
software_versions:
    ${workflow.manifest.name}: "${workflow.manifest.version}"
${software_versions}
${report_header_info ? "report_header_info:" : ""}
${report_header_info}
EOF

multiqc \
-ip \
--no-data-dir \
-n ${run_info.id}_multiqc.html \
.
"""
}