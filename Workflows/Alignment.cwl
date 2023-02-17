#!/usr/bin/env cwl-runner

class: Workflow
id: Alignment
label: Alignment
cwlVersion: v1.1

$namespaces:
  edam: http://edamontology.org/

inputs:
  reference:
    type: File
    format: edam:format_1929
    secondaryFiles:
      - .fai
      - ^.dict
      - .amb
      - .ann
      - .bwt
      - .pac
      - .sa
  unmapped_bam:
    type: File
    format: edam:format_2572
    secondaryFiles:
      - .bai
  read_name_regex:
    type: string?
    default: ""
  outprefix:
    type: string

steps:
  Align:
    label: Align
    run: ../Tools/Alignment/Align.cwl
    in:
      reference: reference
      unmapped_bam: unmapped_bam
      outprefix: outprefix
    out: [bam, bwa_log, log]
  MarkDuplicates:
    label: MarkDuplicates
    run: ../Tools/Alignment/MarkDuplicates.cwl
    in:
      in_bam: Align/bam
      outprefix: outprefix
    out: [out_bam, metrics, log]
  # TODO: implement SortSam step

outputs:
  bam:
    type: File
    outputSource: Align/bam
  metrics:
    type: File
    outputSource: MarkDuplicates/metrics
  bwa_log:
    type: File
    outputSource: Align/bwa_log
  Align_log:
    type: File
    outputSource: Align/log
  MarkDuplicates_log:
    type: File
    outputSource: MarkDuplicates/log
