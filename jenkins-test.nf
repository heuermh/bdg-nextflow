#!/usr/bin/env nextflow

params.sample = "mouse_chrM"
params.baseUrl = "https://s3.amazonaws.com/bdgenomics-test"
params.outputDir = "${baseDir}/${params.sample}"
params.publishMode = "symlink" // or copy, link

outputDir = "${params.outputDir}"
publishMode = "${params.publishMode}"

// extend here to run across several samples
samples = Channel.just(params.sample)

process downloadSample {
  tag { sample }
  publishDir outputDir, mode: publishMode

  input:
    set sample from samples
  output:
    set sample, file("${sample}.bam") into bams

  """
  curl ${params.baseUrl}/${sample}.bam -o ${sample}.bam
  """
}

process transformToReads {
  tag { sample }
  publishDir outputDir, mode: publishMode

  input:
    set sample, file(bam) from bams
  output:
    set sample, file("${sample}.reads.adam") into convertedReads

  """
  adam-submit transform -force_load_bam $bam ${sample}.reads.adam
  """
}

// tee converted reads channel, since we need to read from it several times
(toSort, toConvert, toPrint, toFlagstat) = convertedReads.into(4)
//(toSort, toConvert, toPileup, toPrint, toFlagstat) = convertedReads.into(5)

process sortReads {
  tag { sample }
  publishDir outputDir, mode: publishMode

  input:
    set sample, file(reads) from toSort
  output:
    set sample, file("${sample}.reads.sorted.adam") into sortedReads

  """
  adam-submit transform -sort_reads $reads ${sample}.reads.sorted.adam
  """
}

/*

  ? reads2ref is not a valid ADAM command

process convertReadsToPileup {
  tag { sample }
  publishDir outputDir, mode: publishMode

  input:
    set sample, file(reads) from toPileup
  output:
    set sample, file("${sample}.pileup") into pileups

  """
  adam-submit reads2ref $reads ${sample}.pileup
  """
}
*/

process printReads {
  tag { sample }
  publishDir outputDir, mode: publishMode

  input:
    set sample, file(reads) from toPrint
  output:
    set sample, file("${sample}.out") into prints

  """
  adam-submit print $reads > ${sample}.out
  """
}

process flagstat {
  tag { sample }
  publishDir outputDir, mode: publishMode

  input:
    set sample, file(reads) from toFlagstat
  output:
    set sample, file("${sample}.flagstat") into flagstats

  """
  adam-submit flagstat $reads > ${sample}.flagstat
  """
}
