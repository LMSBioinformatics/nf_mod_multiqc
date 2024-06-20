process multiqc {
    cpus 1
    memory 512.MB
    time 5.m

    publishDir 'qc', mode: "copy"

    beforeScript "module reset"
    module params.multiqc._module

    input:
    path(qc_and_logs)
    val(run_info)

    output:
    path 'qc_report.html'

    stub:
    "touch qc_report.html"

    script:
    software_versions =
        params._submodules
            .collect { "    ${it}: \"${params[it]._version}\"" }
            .join("\n")
    id = run_info.id
    experiment_name = run_info.experiment_name
    run_info = run_info.findAll { !(it.key in ["id", "experiment_name"]) }
    report_header_info =
        run_info
            .collect { "    - ${it.key}: \"${it.value}\"" }
            .join("\n")

    """
cat > multiqc_config.yaml << EOF
title: ${id}
subtitle: ${experiment_name}
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
    - fastqc_sequence_length_distribution
    - fastqc_status_checks
    - fastqc_overrepresented_sequences
software_versions:
    ${workflow.manifest.name}: "${workflow.manifest.version}"
${software_versions}
${run_info ? "report_header_info:" : ""}
${report_header_info}
EOF

multiqc \
    -ip \
    --no-data-dir \
    -n qc_report.html \
    .
"""
}