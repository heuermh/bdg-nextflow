#!/usr/bin/env nextflow

params.dir = "${baseDir}/example"
params.snps = "${baseDir}/example/snps.vcf"

bamFiles = "${params.dir}/**.bam"
bams = Channel.fromPath(bamFiles).map { path -> tuple(path.baseName, path.toRealPath().getParent(), path) }

vcfSnps = Channel.value(params.snps)

// convert input BAM to ADAM
process convertBamToAdam {
  tag { sample }
  publishDir "$parent", mode: 'copy'

  input:
    set sample, parent, file(bam) from bams
  output:
    set sample, parent, file("${sample}.adam") into alignedReads

  """
  adam-submit ${params.sparkOpts} -- transform $bam ${sample}.adam
  """
}

// convert known sites VCF to ADAM
process convertSnpsToAdam {
  input:
    file(snps) from vcfSnps
  output:
    file("snps.adam") into adamSnps

  """
  adam-submit ${params.sparkOpts} -- vcf2adam -only_variants $snps snps.adam
  """
}

process markDuplicateReads {
  tag { sample }
  publishDir "$parent", mode: 'copy'

  input:
    set sample, parent, file(reads) from alignedReads
  output:
    set sample, parent, file("${sample}.adam.mkdup") into mkdups

  """
  adam-submit ${params.sparkOpts} -- transform $reads ${sample}.adam.mkdup" -aligned_read_predicate -limit_projection -mark_duplicate_reads
  """
}

process realignIndels {
  tag { sample }
  publishDir "$parent", mode: 'copy'

  input:
    set sample, parent, file(mkdup) from mkdups
  output:
    set sample, parent, file("${sample}.adam.ri") into ris

  """
  adam-submit ${params.sparkOpts} -- transform $mkdup ${sample}.adam.ri -realign_indels
  """
}

process recalibrateBaseQualityScores {
  tag { sample }
  publishDir "$parent", mode: 'copy'

  input:
    set sample, parent, file(ri) from ris
    file(snps) from adamSnps
  output:
    set sample, parent, file("${sample}.adam.bqsr") into bqsrs

  """
  adam-submit ${params.sparkOpts} -- transform $ri ${sample}.adam.bqsr -recalibrate_base_qualities -known_snps $snps
  """
}

// sort and convert to BAM
process convertToBam {
  tag { sample }
  publishDir "$parent", mode: 'copy'

  input:
    set sample, parent, file(bqsr) from bqsrs
  output:
    set sample, parent, file("${sample}.bqsr.bam") into bqsrBams

  """
  adam-submit ${params.sparkOpts} -- transform $bqsr ${sample}.bqsr.bam -sort_reads -single
  """
}
