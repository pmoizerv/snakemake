# Variant calling snakemake pipeline

## Goal
To get an unfiltered vcf by providing a list of samples of raw reads

## What do I need
- The pipeline
- A genome renamed as "genome.fa" in the *resources* folder
- Genome indices: .fai and .dict and bwa-mem2 indices. Maybe these can be skipped but not sure
- Adapters provided by bbmap ("adapters.fa") in the *resources* folder
- A config.yaml in the *config* folder, describing where to find the necessary files and batch details (memory, threads etc.)
- The various commands are found in the *rules* dir, in different .smk files
- The read files in the *raw* directory, typically as softlinks ending in _R?.fq.gz
- The Snakefile describing what to run, where the config is, which rules to be considered and, importantly, the desired output. For example, put ["results/11_joint_vcf/cohort.vcf.gz","results/11_joint_vcf/cohort.vcf.gz.tbi"] if you want to go all the way. Or [expand ("results/04_bam/final/{sample}.bam", sample=SAMPLES), "results/00_fastqc_raw/multiqc_report.html"] If you want to end at the .bam stage and create a multiqc file from the raw reads.
- For the merging rule to work, it needs a 5-character sample name prefix to the name of the .fq file. For example: PA001_whateverhere_R1.fq.gz You can change the number of characters in the Snakefile
- A list of samples keeping only the first five characters, **without** the _R?.fq.gz suffix. This file is named "samples.tsv" and is in the *root* of the snakemake folder

## How to run
From a screen, like:
snakemake --executor slurm --jobs 100 --default-resources slurm_account=uppmax2026-1-228 --rerun-triggers mtime --keep-going --rerun-incomplete # (-n for a dry run)
