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
    path '*_fastqc.{zip,html}'

    stub:
    "touch qc_report.html"

    script:
    """
    cat > multiqc_config.yaml << EOF
    show_analysis_paths: False
    show_analysis_time: False
    custom_logo: ${workflow.projectDir}/modules/multiqc/assets/mrc_lms.png
    EOF

    multiqc \
        -ip \
        --no-data-dir \
        -n qc_report.html \
        .
    """
}