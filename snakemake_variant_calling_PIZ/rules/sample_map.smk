rule sample_map:
    input:
        expand(
            "results/06_gvcf/{sample}.g.vcf.gz",
            sample=SAMPLES
        )
    output:
        "results/08_sample_map/sample_map.txt"
    run:
        with open(output[0], "w") as out:
            for s in SAMPLES:
                out.write(
                    f"{s}\tresults/06_gvcf/{s}.g.vcf.gz\n"
                )
