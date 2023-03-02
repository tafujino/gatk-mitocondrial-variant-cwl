#!/usr/bin/env cwl-runner

class: CommandLineTool
id: SplitMultiAllelicSites
label: SplitMultiAllelicSites
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
  outprefix:
    type: string

outputs:
  split_vcf:
    type: File
    format: edam:format_1929
    outputBinding:
      glob: $(inputs.outprefix).vcf
    secondaryFiles:
      - .idx
  log:
    type: stderr

stderr: $(inputs.outprefix).log

arguments:
  - position: 1
    valueFrom: LeftAlignAndTrimVariants
  - position: 4
    prefix: -O
    valueFrom: $(inputs.outprefix).vcf
  - position: 5
    valueFrom: --split-multi-allelics
  - position: 6
    valueFrom: --dont-trim-alleles
  - position: 7
    valueFrom: --keep-original-ac