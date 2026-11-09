rule haplotypecaller:
    input:
        bam="results/04_bam/final/{sample}/{sample}.bam",
        bai="results/04_bam/final/{sample}/{sample}.bai",
        ref=config["reference"]
    output:
        gvcf="results/06_gvcf/{sample}.g.vcf.gz",
        tbi="results/06_gvcf/{sample}.g.vcf.gz.tbi"
    threads:
        config["resources"]["haplotypecaller"]["threads"]
    params:
        mem=config["resources"]["haplotypecaller"]["mem"]
    shell:
        """
        mkdir -p results/06_gvcf

        gatk \
            --java-options "-Xmx{params.mem}G" \
            HaplotypeCaller \
            -R {input.ref} \
            -I {input.bam} \
            -ERC GVCF \
            -O {output.gvcf}

        gatk IndexFeatureFile \
            -I {output.gvcf}
        """
