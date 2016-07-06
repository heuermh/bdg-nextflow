#!/usr/bin/env nextflow

params.sample = "mouse_chrM"
params.baseUrl = "https://s3.amazonaws.com/bdgenomics-test"
params.outputDir = "${baseDir}/${params.sample}"
params.publishMode = "symlink" // or copy, link

outputDir = "${params.outputDir}"
publishMode = "${params.publishMode}"

// extend here to run across several samples
samples = Channel.value(params.sample)

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

process printReads {
  tag { sample }
  publishDir outputDir, mode: publishMode

  input:
    set sample, file(reads) from toPrint
  output:
    set sample, file("${sample}.json") into prints

  """
  adam-submit print $reads -pretty -o ${sample}.json
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
