#!/usr/bin/env cwl-runner

class: CommandLineTool
id: SubsetCramToChrM
label: SubsetCramToChrM
cwlVersion: v1.1

$namespaces:
  edam: http://edamontology.org/

hints:
  - class: DockerRequirement
    dockerPull: us.gcr.io/broad-gatk/gatk:4.1.7.0

baseCommand: [ gatk ]

inputs:
  reference:
    type: File
    format: edam:format_1929
    secondaryFiles:
      - .fai
      - ^.dict
    inputBinding:
      position: 2
      prefix: -R
  cram:
    type: File
    format: edam:format_3462
    secondaryFiles:
      - .crai
    inputBinding:
      position: 6
      prefix: -I
  contig_name:
    type: string?
    default: chrM
    inputBinding:
      position: 3
      prefix: -L
  outprefix:
    type: string

outputs:
  chrM_bam:
    type: File
    outputBinding:
      glob: $(inputs.outprefix).chrM.bam
    secondaryFiles:
      - .bai
  log:
    type: stderr

arguments:
  - position: 1
    valueFrom: PrintReads
  - position: 4
    prefix: --read-filter
    valueFrom: MateOnSameContigOrNoMappedMateReadFilter
  - position: 5
    prefix: --read-filter
    valueFrom: MateUnmappedAndUnmappedReadFilter
  - position: 7
    prefix: -O
    valueFrom: $(inputs.outprefix).chrM.bam

stderr: $(inputs.outprefix).chrM.log
