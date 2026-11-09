rule fastqc_raw:
    input:
        r1="results/01_merged/{sample}_R1.fq.gz",
        r2="results/01_merged/{sample}_R2.fq.gz"
    output:
        html1="results/00_fastqc_raw/{sample}_R1_fastqc.html",
        html2="results/00_fastqc_raw/{sample}_R2_fastqc.html"
    threads:
        config["resources"]["fastqc"]["threads"]
    resources:
        mem_mb=config["resources"]["fastqc"]["mem"] * 1000,
        runtime=config["resources"]["fastqc"]["runtime"]
    shell:
        """
	ml FastQC/0.12.1-Java-17

        mkdir -p results/00_fastqc_raw

        fastqc \
            -t {threads} \
            -o results/00_fastqc_raw \
            {input.r1} \
            {input.r2}
        """

rule multiqc_raw:
    input:
        expand(
            "results/00_fastqc_raw/{sample}_R1_fastqc.html",
            sample=SAMPLES
        ),
        expand(
            "results/00_fastqc_raw/{sample}_R2_fastqc.html",
            sample=SAMPLES
        )
    output:
        "results/00_fastqc_raw/multiqc_report.html"
    resources:
        mem_mb=4000,
        runtime=60
    shell:
        """
	ml MultiQC/1.28-gfbf-2024a
        multiqc \
            results/00_fastqc_raw \
            -o results/00_fastqc_raw
        """
