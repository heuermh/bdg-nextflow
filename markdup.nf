#!/usr/bin/env nextflow

params.dir = "${baseDir}/example"

bamFiles = "${params.dir}/**.bam"
bams = Channel.fromPath(bamFiles).map { path -> tuple(path.baseName, path) }

process markdup {
  tag { sample }
  container "quay.io/biocontainers/adam:0.34.0--0"

  input:
    set sample, file(bam) from bams
  output:
    set sample, file("${sample}.mkdup.bam") into markdups

  """
  adam-submit \
    ${params.sparkOpts} \
    -- \
    transformAlignments \
    -single \
    -mark_duplicate_reads \
    ${bam} \
    ${sample}.mkdup.bam
  """
}

markdups.subscribe {
  println "Marked duplicates for sample ${it.get(0)} into ${it.get(1)}."
}
