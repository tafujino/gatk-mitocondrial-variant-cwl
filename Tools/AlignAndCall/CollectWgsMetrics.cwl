#!/usr/bin/env cwl-runner

class: CommandLineTool
id: CollectWgsMetrics
label: CollectWgsMetrics
cwlVersion: v1.1

$namespaces:
  edam: http://edamontology.org/

hints:
  - class: DockerRequirement
    dockerPull: us.gcr.io/broad-gotc-prod/genomes-in-the-cloud:2.4.2-1552931386

baseCommand: [java, -jar, /usr/gitc/picard.jar]

inputs:
  java_options:
    type: string?
    inputBinding:
      position: 1
      shellQuote: false
    default: -Xmx2000m
  bam:
    type: File
    format: edam:format_2572
    secondaryFiles:
      - .bai
    inputBinding:
      position: 3
      prefix: INPUT=
      shellQuote: false
  reference:
    type: File
    format: edam:format_1929
    secondaryFiles:
      - .fai
    inputBinding:
      position: 5
      prefix: REFERENCE_SEQUENCE=
      shellQuote: false
  read_length:
    type: int?
    inputBinding:
      position: 8
      prefix: READ_LENGTH=
      shellQuote: false
    default: 151
  coverage_cap:
    type: int?
    inputBinding:
      position: 9
      prefix: COVERAGE_CAP=
      shellQuote: false

outputs:
  coverage_metrics:
    type: File
    outputBinding:
      glob: $(inputs.bam.nameroot).metrics
  theoretical_sensitivity:
    type: File
    outputBinding:
      glob: $(inputs.bam.nameroot).theoretical_sensitivity
  log:
    type: stderr

stderr: $(inputs.bam.nameroot).metrics.log

arguments:
  - position: 2
    valueFrom: CollectWgsMetrics
  - position: 4
    prefix: VALIDATION_STRINGENCY=
    separate: false
    valueFrom: SILENT
  - position: 6
    prefix: OUTPUT=
    separate: false
    valueFrom: $(inputs.bam.nameroot).metrics
  - position: 7
    prefix: USE_FAST_ALGORITHM=
    separate: false
    valueFrom: "true"
  - position: 10
    prefix: INCLUDE_BQ_HISTOGRAM=
    separate: false
    valueFrom: "true"
  - position: 11
    prefix: THEORETICAL_SENSITIVITY_OUTPUT
    separate: false
    valueFrom: $(inputs.bam.nameroot).theoretical_sensitivity
