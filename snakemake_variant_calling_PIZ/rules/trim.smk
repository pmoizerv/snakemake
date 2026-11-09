rule bbduk:
    input:
        r1="results/01_merged/{sample}_R1.fq.gz",
        r2="results/01_merged/{sample}_R2.fq.gz"
    output:
        r1="results/02_trimmed/{sample}_R1.trim.fq.gz",
        r2="results/02_trimmed/{sample}_R2.trim.fq.gz"
    threads:
        config["resources"]["bbduk"]["threads"]
    job_name: "trim_{wildcards.sample}"
    resources:
        mem_mb=config["resources"]["bbduk"]["mem"] * 1000,
        runtime=config["resources"]["bbduk"]["runtime"]
    shell:
         """
          mkdir -p results/02_trimmed

         /home/panazerv/BBMap/bbduk.sh \
             -Xmx20g \
              in1={input.r1} \
              in2={input.r2} \
              ref={config[adapters]} \
              out1={output.r1} \
              out2={output.r2} \
              k=21 \
              rcomp=t \
              mink=11 \
              ktrim=r \
              minlen=50 \
              trimq=20 \
              qtrim=rl \
              ftm=5 \
              hdist=1 \
              tbo \
              tpe
          """
