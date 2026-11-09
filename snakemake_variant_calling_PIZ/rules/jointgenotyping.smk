rule make_intervals:
    input:
        config["reference"] + ".fai"
    output:
        expand(
            "results/07_intervals/interval_{i}.bed",
            i=INTERVALS
        )
    shell:
        r"""
        mkdir -p results/07_intervals

        cut -f1,2 {input} > genome_sizes.txt

        bedtools makewindows \
            -g genome_sizes.txt \
            -n {config[intervals][windows]} \
            > windows.bed

        awk '{{print > sprintf("results/07_intervals/interval_%04d.bed", NR)}}' windows.bed

        rm genome_sizes.txt windows.bed
        """


rule sample_map:
    input:
        expand(
            "results/06_gvcf/{sample}.g.vcf.gz",
            sample=SAMPLES
        )
    output:
        "results/08_sample_map/sample_map.txt"
    run:
        import os

        os.makedirs("results/08_sample_map", exist_ok=True)

        with open(output[0], "w") as out:
            for s in SAMPLES:
                out.write(
                    f"{s}\tresults/06_gvcf/{s}.g.vcf.gz\n"
                )


rule genomicsdbimport:
    input:
        bed="results/07_intervals/interval_{i}.bed",
        sample_map="results/08_sample_map/sample_map.txt"
    output:
        directory("results/09_genomicsdb/db_{i}")
    params:
        mem=config["resources"]["genomicsdbimport"]["mem"],
        batch=config["resources"]["genomicsdbimport"]["batch_size"],
        threads=config["resources"]["genomicsdbimport"]["threads"]
    shell:
        r"""
        INTERVAL=$(awk '{{print $1":"$2"-"$3}}' {input.bed})

        gatk \
            --java-options "-Xmx{params.mem}G" \
            GenomicsDBImport \
            --sample-name-map {input.sample_map} \
            --genomicsdb-workspace-path {output} \
            -L "$INTERVAL" \
            --batch-size {params.batch} \
            --reader-threads {params.threads}
        """

rule genotypegvcfs:
    input:
        db="results/09_genomicsdb/db_{i}"
    output:
        vcf="results/10_genotyped/window_{i}.vcf.gz",
        tbi="results/10_genotyped/window_{i}.vcf.gz.tbi"
    params:
        mem=config["resources"]["genotypegvcfs"]["mem"]
    shell:
        """
        mkdir -p results/10_genotyped

        gatk \
            --java-options "-Xmx{params.mem}G" \
            GenotypeGVCFs \
            -R {config[reference]} \
            -V gendb://{input.db} \
            -O {output.vcf}

        gatk IndexFeatureFile \
            -I {output.vcf}
        """

rule concatenate_vcfs:
    input:
        expand(
            "results/10_genotyped/window_{i}.vcf.gz",
            i=INTERVALS
        )
    output:
        vcf="results/11_joint_vcf/cohort.vcf.gz",
        tbi="results/11_joint_vcf/cohort.vcf.gz.tbi"
    params:
        cpucores=config["resources"]["concat"]["threads"]
    shell:
        """
        mkdir -p results/11_joint_vcf

        bcftools concat \
            --threads {params.cpucores} \
            -Oz \
            {input} \
            -o {output.vcf}

        tabix -p vcf {output.vcf}
        """
