#!/usr/bin/env cwl-runner

class: CommandLineTool
id: VariantFiltration
label: VariantFiltration
cwlVersion: v1.1

$namespaces:
  edam: http://edamontology.org/

hints:
  - class: DockerRequirement
    dockerPull: broadinstitute/gatk:4.2.4.0

requirements:
  ShellCommandRequirement: {}

baseCommand: [gatk]

inputs:
  in_vcf:
    type: File
    format: edam:format_3016
    secondaryFiles:
      - .idx
    inputBinding:
      position: 3
      prefix: -V
  blacklisted_sites:
    doc: blacklist sites in BED format
    type: File
    format: edam:format_3003
    secondaryFiles:
      - .idx
    inputBinding:
      position: 6
      prefix: --mask
  outprefix:
    type: string

outputs:
  out_vcf:
    type: File
    outputBinding:
      glob: $(inputs.outprefix).vcf
    secondaryFiles:
      - .idx
  log:
    type: stderr

stderr: $(inputs.outprefix).vcf.log

arguments:
  - position: 2
    valueFrom: VariantFiltration
  - position: 4
    prefix: -O
    valueFrom: $(inputs.outprefix).vcf
  - position: 5
    valueFrom: --apply-allele-specific-filters
  - position: 7
    prefix: --mask-name
    valueFrom: blacklisted_site
