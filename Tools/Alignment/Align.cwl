#!/usr/bin/env cwl-runner

class: CommandLineTool
id: Align
label: Align
cwlVersion: v1.1

$namespaces:
  edam: http://edamontology.org/

hints:
  - class: DockerRequirement
    dockerPull: us.gcr.io/broad-gotc-prod/genomes-in-the-cloud:2.4.2-1552931386

requirements:
  EnvVarRequirement:
    envDef:
      BWA_VERSION: 0.7.15-r1140
      REF_FASTA: $(inputs.reference)
      INPUT_BAM: $(inputs.unmapped_bam)
      BWA_COMMANDLINE: $("bwa mem -K 100000000 -p -v 3 -t 2 -Y " + $(inputs.reference)) # need InlineJavascriptRequirement ?
      OUTPUT_BAM_BASENAME: $(inputs.outprefix)
  InitialWorkDirRequirement:
    listing:
      - class: File
        location: Align.sh

baseCommand: [/bin/bash, Align.sh]

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
  outprefix:
    type: string

outputs:
  bam:
    type: File
    format: edam:format_2572
    outputBinding:
      glob: mba.bam
    secondaryFiles:
      - .bai
  BWA_log:
    type: File
    doc: the standard error of BWA command
    outputBinding:
      glob: $(inputs.outprefix).bwa.log
  log:
    doc: the entire standard error
    type: stderr

stderr: $(inputs.outprefix).Align.log
