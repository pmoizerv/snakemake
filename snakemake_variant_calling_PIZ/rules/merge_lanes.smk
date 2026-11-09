rule merge_lanes:
    input:
        r1=lambda wc: LANES[wc.sample]["R1"],
        r2=lambda wc: LANES[wc.sample]["R2"]
    output:
        r1=temp("results/01_merged/{sample}_R1.fq.gz"),
        r2=temp("results/01_merged/{sample}_R2.fq.gz")
    job_name: "merge_{wildcards.sample}"
    threads:
        config["resources"]["merging"]["threads"]
    resources:
        mem_mb=config["resources"]["merging"]["mem"] * 1000,
        runtime=config["resources"]["merging"]["runtime"]
    shell:
        """
        mkdir -p results/01_merged

        cat {input.r1} > {output.r1}
        cat {input.r2} > {output.r2}
        """
