#!/usr/bin/env cwl-runner

class: CommandLineTool
id: MeanCoverage
label: MeanCoverage
cwlVersion: v1.1

$namespaces:
  edam: http://edamontology.org/

hints:
  - class: DockerRequirement
    dockerPull: us.gcr.io/broad-gotc-prod/genomes-in-the-cloud:2.4.2-1552931386

requirements:
  InitialWorkDirRequirement:
    listing:
      - entryname: metrics.txt
        entry: $(inputs.coverage_metrics)
      - class: File
        location: MeanCoverage.R

baseCommand: [R, --vanillia, MeanCoverage.R]

inputs:
  coverage_metrics:
    type: File

outputs:
  mean_coverage:
    type: int
    outputBinding:
      glob: mean_coverage.txt
      loadContents: true
      outputEval: $(parseInt(self[0].contents))
  log:
    type: stderr

stderr: $(inputs.coverage_metrics.nameroot).mean_coverage.log
