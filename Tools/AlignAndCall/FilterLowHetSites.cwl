#!/usr/bin/env cwl-runner

class: CommandLineTool
id: FilterLowHetSites
label: FilterLowHetSites
cwlVersion: v1.1

$namespaces:
  edam: http://edamontology.org/

hints:
  - class: DockerRequirement
    dockerPull: broadinstitute/gatk:4.2.4.0

baseCommand: [gatk]

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
  in_vcf:
    type: File
    format: edam:format_3016
    inputBinding:
      position: 3
      prefix: -V
  max_low_het_sites:
    type: int?

outputs:
  out_vcf:
    type: File
    format: edam:format_1929
    outputBinding:
      glob: $(inputs.in_vcf.nameroot).low_het_filtered.vcf
  log:
    type: stderr

stderr: $(inputs.in_vcf.nameroot).low_het_filtered.log

arguments:
  - position: 1
    valueFrom: MTLowHeteroplasmyFilterTool
  - position: 4
    prefix: -O
    valueFrom: $(inputs.in_vcf.nameroot).low_het_filtered.vcf
