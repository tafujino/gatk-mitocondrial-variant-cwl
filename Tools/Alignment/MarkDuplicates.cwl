#!/usr/bin/env cwl-runner

class: CommandLineTool
id: MarkDuplicates
label: MarkDuplicates
cwlVersion: v1.1

$namespaces:
  edam: http://edamontology.org/

hints:
  - class: DockerRequirement
    dockerPull: us.gcr.io/broad-gotc-prod/genomes-in-the-cloud:2.4.2-1552931386

baseCommand: [ java, -jar, /usr/gitc/picard.jar ]

inputs:
  java_options:
    type: string?
    inputBinding:
      position: 1
      shellQuote: false
    default: -Xms4000m
  in_bam:
    type: File
    format: edam:format_2572
    secondaryFiles:
      - .bai
    inputBinding:
      position: 3
      prefix: INPUT=
      separate: false
  read_name_regex:
    type: string?
    inputBinding:
      position: 7
      prefix: READ_NAME_REGEX=
      separate: false
  outprefix:
    type: string

outputs:
  out_bam:
    type: File
    format: edam:format_2572
    outputBinding:
      glob: md.bam
    secondaryFiles:
      - .bai
  metrics:
    type: File
    outputBinding:
      glob: $(outprefix).metrics
  log:
    type: stderr

arguments:
  - position: 2
    valueFrom: MarkDuplicates
  - position: 4
    prefix: OUTPUT=
    separate: false
    valueFrom: md.bam
  - position: 5
    prefix: METRICS_FILE=
    separate: false
    valueFrom: $(outprefix).metrics
  - position: 6
    prefix: VALIDATION_STRINGENCY=
    separate: false
    valueFrom: SILENT
  - position: 8
    prefix: OPTICAL_DUPLICATE_PIXEL_DISTANCE=
    separate: false
    valueFrom: "2500"
  - position: 9
    prefix: ASSUME_SORT_ORDER=
    separate: false
    valueFrom: queryname
  - position: 10
    prefix: CLEAR_DT
    separate: false
    valueFrom: "false"
  - position: 11
    prefix: ADD_PG_TAG_TO_READS
    separate: false
    valueFrom: "false"

stderr: $(inputs.outprefix).MarkDuplicates.log
