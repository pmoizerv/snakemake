#!/bin/bash
#SBATCH -A uppmax2026-1-228
#SBATCH -J SnakeTest
#SBATCH -c 16
#SBATCH --mem=64G
#SBATCH -t 0-02:00:00
#SBATCH -M pelle

# OBS! Better to start a screen with for example screen -S snakemake_run and then run:
# snakemake --executor slurm --jobs 100 --default-resources slurm_account=uppmax2026-1-228 --rerun-triggers mtime --keep-going --rerun-incomplete
# I have made the pipeline so it should be submitted like that and not like you see below. I leave the rest here for legacy reasons and because it's easy to track module versions

ml purge

ml FastQC/0.12.1-Java-17
ml bwa-mem2/2.3-GCC-13.3.0
ml SAMtools/1.22.1-GCC-13.3.0
ml picard/3.4.0-Java-17
ml GATK/4.6.2.0-GCCcore-13.3.0-Java-17
ml BEDTools/2.31.1-GCC-13.3.0
ml BCFtools/1.22.1-GCC-13.3.0
ml HTSlib/1.22.1-GCC-13.3.0
ml snakemake/8.27.0

cd /gorilla/proj/fruitdiv/private/Fruits/scripts/snakemake_attempt

snakemake \
    --cores 16
#     results/04_bam/final/ES_001.bam

