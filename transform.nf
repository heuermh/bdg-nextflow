#!/usr/bin/env nextflow

params.dir = "${baseDir}/example"

bamFiles = "${params.dir}/**.bam"
bams = Channel.fromPath(bamFiles).map { path -> tuple(path.baseName, path) }

process transform {
  tag { sample }

  input:
    set sample, file(bam) from bams
  output:
    set sample, 'source', file("${sample}.adam") into adams

  """
  adam-submit transform -force_load_bam $bam ${sample}.adam

  # workaround for copying .adam files back to input directory, which isn't
  # the nextflow way of doing things (and may not work if wrapped in docker)
  ln -s \$(readlink $bam) source
  """
}

adams.subscribe { sample, source, adam -> copy(sample, source, adam) }

def copy (sample, source, adam) {
  dest = source.toRealPath().getParent();
  log.info "Copying $adam.name to $dest for sample $sample"
  adam.copyTo(dest)
}
