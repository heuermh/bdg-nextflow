#!/usr/bin/env nextflow

params.dir = "${baseDir}/example"

bamFiles = "${params.dir}/**.bam"
bams = Channel.fromPath(bamFiles).map { path -> tuple(path.baseName, path) }

process transform {
  tag { sample }
  container "quay.io/biocontainers/adam:0.32.0--0"

  input:
    set sample, file(bam) from bams
  output:
    set sample, file("${sample}.adam") into alignments

  """
  adam-submit \
    ${params.sparkOpts} \
    -- \
    transformAlignments \
    $bam \
    ${sample}.adam
  """
}

alignments.subscribe {
  println "Transformed sample ${it.get(0)} into alignments ${it.get(1)}."
}
