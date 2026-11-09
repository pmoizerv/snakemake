rule merge_lanes:
    input:
        r1=lambda wc: LANES[wc.sample]["R1"],
        r2=lambda wc: LANES[wc.sample]["R2"]
    output:
        r1="results/01_merged/{sample}_R1.fq.gz",
        r2="results/01_merged/{sample}_R2.fq.gz"
    run:
        import os

        os.makedirs("results/01_merged", exist_ok=True)

        if len(input.r1) == 1:
            shell("ln -sf $(realpath {input.r1}) {output.r1}")
        else:
            shell("cat {input.r1} > {output.r1}")

        if len(input.r2) == 1:
            shell("ln -sf $(realpath {input.r2}) {output.r2}")
        else:
            shell("cat {input.r2} > {output.r2}")
