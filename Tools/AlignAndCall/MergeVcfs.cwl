#!/usr/bin/env cwl-runner

class: CommandLineTool
id: MergeVcfs
label: MergeVcfs
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
  shifted_back_vcf:
    type: File
    format: edam:format_3016
    inputBinding:
      position: 3
      prefix: I=
      separate: false
  vcf:
    type: File
    format: edam:format_3016
    inputBinding:
      position: 4
      prefix: I=
      separate: false

outputs:
  merged_vcf:
    type: File
    outputBinding:
      glob: S(inputs.vcf.nameroot).merged.vcf
  log:
    type: stderr

stderr: $(inputs.vcf.nameroot).merged.log

arguments:
  - position: 2
    valueFrom: MergeVcfs
  - position: 4
    prefix: O=
    separate: false
    valueFrom: S(inputs.vcf.nameroot).merged.vcf
