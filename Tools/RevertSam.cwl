#!/usr/bin/env cwl-runner

class: CommandLineTool
id: SubsetCramToChrM
label: SubsetCramToChrM
cwlVersion: v1.1

$namespaces:
  edam: http://edamontology.org/

hints:
  - class: DockerRequirement
    dockerPull: us.gcr.io/broad-gotc-prod/genomes-in-the-cloud:2.4.2-1552931386

requirements:
  ShellCommandRequirement: {}

baseCommand: [ java, -jar, /usr/gitc/picard.jar ]

inputs:
  java_options:
    type: string?
    inputBinding:
      position: 1
      shellQuote: false
    default: -Xmx1000m
  bam:
    type: File
    format: edam:format_2572
    secondaryFiles:
      - .bai
    inputBinding:
      position: 3
      prefix: INPUT=
      separate: false
  outprefix:
    type: string

outputs:
  unmapped_bam:
    type: File
    outputBinding:
      glob: $(inputs.outprefix).chrM.unmapped.bam
  log:
    type: stderr

arguments:
  - position: 2
    valueFrom: RevertSam
  - position: 4
    prefix: OUTPUT_BY_READGROUP=
    separate: false
    valueFrom: "false"
  - position: 5
    prefix: OUTPUT=
    separate: false
    valueFrom: $(inputs.outprefix).chrM.unmapped.bam
  - position: 6
    prefix: VALIDATION_STRINGENCY=
    separate: false
    valueFrom: LENIENT
  - position: 7
    prefix: ATTRIBUTE_TO_CLEAR=
    separate: false
    valueFrom: FT
  - position: 8
    prefix: ATTRIBUTE_TO_CLEAR=
    separate: false
    valueFrom: CO
  - position: 9
    prefix: SORT_ORDER=
    separate: false
    valueFrom: queryname
  - position: 10
    prefix: RESTORE_ORIGINAL_QUALITIES=
    separate: false
    valueFrom: "false"

stderr: $(inputs.outprefix).chrM.unmapped.log
