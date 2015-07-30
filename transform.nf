#!/usr/bin/env nextflow

params.dir = "${baseDir}/example"

bamFiles = "${params.dir}/**.bam"
bams = Channel.fromPath(bamFiles).map { path -> tuple(path.baseName, path, path) }

process transform {
  tag { sample }

  input:
    set sample, ref, file(bam) from bams
  output:
    set sample, ref, file("${sample}.adam") into adams

  """
  # replace mkdir with adam command here, e.g.
  # adam-submit transform $bam
  mkdir ${sample}.adam
  """
}

adams.subscribe { sample, source, adam -> copy(sample, source, adam) }

def copy (sample, source, adam) {
  dest = source.toRealPath().getParent();
  log.info "Copying $adam.name to $dest for sample $sample"
  adam.copyTo(dest)
}
