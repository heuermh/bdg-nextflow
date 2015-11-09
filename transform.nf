#!/usr/bin/env nextflow

params.dir = "${baseDir}/example"

bamFiles = "${params.dir}/**.bam"
bams = Channel.fromPath(bamFiles).map { path -> tuple(path.baseName, path.toRealPath().getParent(), path) }

process transform {
  tag { sample }
  publishDir "$parent", mode: 'copy'

  input:
    set sample, parent, file(bam) from bams
  output:
    set sample, parent, file("${sample}.adam") into reads

  """
  adam-submit transform -force_load_bam $bam ${sample}.adam
  """
}
