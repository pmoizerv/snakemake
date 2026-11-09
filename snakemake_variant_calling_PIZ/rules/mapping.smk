REF = config["reference"]

rule reference_fai:
    input:
        REF
    output:
        REF + ".fai"
    resources:
        mem_mb=1000,
        runtime=10
    shell:
        """
	ml SAMtools/1.22.1-GCC-13.3.0
        samtools faidx -o {output} {input}
        """

rule reference_dict:
    input:
        REF
    output:
        REF.replace(".fa", ".dict")
    resources:
        mem_mb=1000,
        runtime=10
    shell:
        """
	ml GATK/4.6.2.0-GCCcore-13.3.0-Java-17
        gatk CreateSequenceDictionary \
            -R {input} \
            -O {output}
        """

rule bwa_mem2:
    input:
        r1="results/02_trimmed/{sample}_R1.trim.fq.gz",
        r2="results/02_trimmed/{sample}_R2.trim.fq.gz"
    output:
        temp("results/04_bam/aligned/{sample}.bam")
    threads:
        config["resources"]["bwa"]["threads"]
    job_name: "align_{wildcards.sample}"
    resources:
        mem_mb=config["resources"]["bwa"]["mem"] * 1000,
        runtime=config["resources"]["bwa"]["runtime"]
    shell:
        """
	ml bwa-mem2/2.3-GCC-13.3.0
	ml SAMtools/1.22.1-GCC-13.3.0

        mkdir -p results/04_bam

        bwa-mem2 mem \
            -t {threads} \
            {REF} \
            {input.r1} \
            {input.r2} |
        samtools sort \
            -@ {threads} \
            -n \
            -o {output}
        """

rule fixmate:
    input:
        "results/04_bam/aligned/{sample}.bam"
    output:
        temp("results/04_bam/fixmate/{sample}.bam")
    resources:
        mem=config["resources"]["fixmate"]["mem"] - 4,
        mem_mb=config["resources"]["fixmate"]["mem"] * 1000,
        runtime=config["resources"]["fixmate"]["runtime"]
    job_name: "fixmate_{wildcards.sample}"
    params:
        ref=config["reference"]
    shell:
        """
	ml picard/3.4.0-Java-17
        java -Xmx{resources.mem}g -jar $EBROOTPICARD/picard.jar \
            FixMateInformation \
            --INPUT {input} \
            --OUTPUT {output} \
            --VALIDATION_STRINGENCY STRICT \
            --ADD_MATE_CIGAR true \
            --SORT_ORDER coordinate \
            --REFERENCE_SEQUENCE {params.ref}
        """

rule add_readgroups:
    input:
        "results/04_bam/fixmate/{sample}.bam"
    output:
        temp("results/04_bam/readgroups/{sample}.bam")
    resources:
        mem=config["resources"]["fixmate"]["mem"] - 4,
        mem_mb=config["resources"]["add_readgroups"]["mem"] * 1000,
        runtime=config["resources"]["add_readgroups"]["runtime"]
    job_name: "readgroup_{wildcards.sample}"
    shell:
        """
	ml picard/3.4.0-Java-17
        java -Xmx{resources.mem}g -jar $EBROOTPICARD/picard.jar \
            AddOrReplaceReadGroups \
            --INPUT {input} \
            --RGID {wildcards.sample} \
            --RGLB {wildcards.sample}.lib \
            --RGPL Illumina \
            --RGSM {wildcards.sample} \
            --RGPU {wildcards.sample}.unit \
            --VALIDATION_STRINGENCY LENIENT \
            --OUTPUT {output}
        """

rule cleansam:
    input:
        "results/04_bam/readgroups/{sample}.bam"
    output:
        temp("results/04_bam/clean/{sample}.bam")
    params:
        ref=config["reference"]
    resources:
        mem=config["resources"]["fixmate"]["mem"] - 4,
        mem_mb=config["resources"]["cleansam"]["mem"] * 1000,
        runtime=config["resources"]["cleansam"]["runtime"]
    shell:
        """
	ml picard/3.4.0-Java-17

        java -Xmx{resources.mem}g -jar $EBROOTPICARD/picard.jar \
            CleanSam \
            --INPUT {input} \
            --OUTPUT {output} \
            --REFERENCE_SEQUENCE {params.ref} \
            --VALIDATION_STRINGENCY STRICT
        """

rule markduplicates:
    input:
        "results/04_bam/clean/{sample}.bam"
    output:
        cram="results/04_bam/final/{sample}/{sample}.cram",
        crai="results/04_bam/final/{sample}/{sample}.cram.crai"
    threads:
        config["resources"]["markduplicates"]["threads"]
    job_name: "mdup_{wildcards.sample}"
    params:
        metrics="results/04_bam/final/{sample}/{sample}.metrics_2.txt",
        ref=config["reference"]
    resources:
        mem=config["resources"]["markduplicates"]["mem"] - 4,
        mem_mb=config["resources"]["markduplicates"]["mem"] * 1000,
        runtime=config["resources"]["markduplicates"]["runtime"]
    shell:
        """
	ml picard/3.4.0-Java-17
        ml SAMtools/1.22.1-GCC-13.3.0

        java -Xmx{resources.mem}g -jar $EBROOTPICARD/picard.jar \
            MarkDuplicatesWithMateCigar \
            --INPUT {input} \
            --OUTPUT {output.cram} \
            --CREATE_INDEX false \
            --REFERENCE_SEQUENCE {params.ref} \
            --VALIDATION_STRINGENCY LENIENT \
            --METRICS_FILE {params.metrics} \
            --MINIMUM_DISTANCE 400

        samtools index \
            -@ {threads} \
            -o {output.crai} \
            {output.cram}
        """

rule flagstat:
    input:
        cram="results/04_bam/final/{sample}/{sample}.cram",
        ref=REF
    output:
        flag="results/05_mapping_stats/{sample}/{sample}.flagstat.txt",
        cov="results/05_mapping_stats/{sample}/{sample}.cov.txt"
    job_name: "mainstats_{wildcards.sample}"
    resources:
        mem_mb=2000,
        runtime=25
    shell:
        """
	ml SAMtools/1.22.1-GCC-13.3.0

        samtools flagstat {input.cram} > {output.flag}

        samtools coverage --reference {input.ref} {input.cram} | {{
            read -r header
            echo "$header"
            sort -k1,1V
            }} > {output.cov}
        """

rule idxstats:
    input:
        "results/04_bam/final/{sample}/{sample}.cram"
    output:
        "results/05_mapping_stats/{sample}/{sample}.idxstats.txt"
    resources:
        mem_mb=1000,
        runtime=15
    shell:
        """
	ml SAMtools/1.22.1-GCC-13.3.0

        samtools idxstats {input} > {output}
        """

rule samstats:
    input:
        cram="results/04_bam/final/{sample}/{sample}.cram",
        ref=REF
    output:
        "results/05_mapping_stats/{sample}/{sample}.samstats.txt"
    resources:
        mem_mb=1000,
        runtime=15
    shell:
        """
	ml SAMtools/1.22.1-GCC-13.3.0

        samtools stats --reference {input.ref} {input.cram} > {output}
        """
