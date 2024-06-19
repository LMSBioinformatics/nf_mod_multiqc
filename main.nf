process multiqc {
    cpus 1
    memory 512.MB
    time 5.m

    publishDir 'qc', mode: "copy"

    beforeScript "module reset"
    module params.multiqc._module

    input:
    path(qc_and_logs)

    output:
    path 'qc_report.html'

    stub:
    "touch qc_report.html"

    script:
    if (params._submodules) {
        software_versions =
            "software_versions:\n" +
            params._submodules
                .collect {
                    "    ${it}: \"${params[it]._version}\""
                }
                .join("\n")
    } else {
        software_versions = "skip_versions_section: True"
    }

    """
    cat > multiqc_config.yaml << EOF
    title: test_title
    subtitle: ${workflow.manifest.name} (${workflow.commitId})
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
    fn_clean_exts:
        - type: regex
          pattern: "\..*"
    ${software_versions}
    EOF

    multiqc \
        -ip \
        --no-data-dir \
        -n qc_report.html \
        .
    """
}