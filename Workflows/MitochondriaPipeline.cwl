#!/usr/bin/env cwl-runner

class: Workflow
id: MitochondriaPipeline
label: MitochondriaPipeline
cwlVersion: v1.1

$namespaces:
  edam: http://edamontology.org/

requirements:
  SubworkflowFeatureRequirement: {}

inputs:
  wgs_aligned_cram:
    type: File
    format: edam:format_3462
    secondaryFiles:
      - .crai
  contig_name:
    type: string
    default: chrM
  autosomal_coverage:
    type: float
    default: 30
  max_read_length:
    type: int?
  reference:
    type: File
    format: edam:format_1929
    secondaryFiles:
      - .fai
      - ^.dict
  mt_reference:
    type: File
    format: edam:format_1929
    secondaryFiles:
      - .fai
      - .amb
      - .ann
      - .bwt
      - .pac
      - .sa
      - ^.dict
  blacklisted_sites:
    doc: blacklist sites in BED format
    type: File
    format: edam:format_3003
    secondaryFiles:
      - .idx
  mt_shifted_reference:
    type: File
    format: edam:format_1929
    secondaryFiles:
      - .fai
      - .amb
      - .ann
      - .bwt
      - .pac
      - .sa
      - ^.dict
  outprefix:
    type: string

steps:
  SubsetCramToChrM:
    label: SubsetCramToChrM
    run: ../Tools/SubsetCramToChrM.cwl
    in:
      contig_name: contig_name
      reference: reference
      cram: wgs_aligned_cram
      outprefix: outprefix
    out: [subset_bam, log]
  RevertSam:
    label: RevertSam
    run: ../Tools/RevertSam.cwl
    in:
      bam: SubsetCramToChrM/subset_bam
      outprefix: outprefix
    out: [unmapped_bam, log]
  AlignAndCall:
    label: AlignAndCall
    run: AlignAndCall.cwl
    in:
      unmapped_bam: RevertSam/unmapped_bam
      autosomal_coverage: autosomal_coverage
      mt_reference: mt_reference
      mt_shifted_reference: mt_shifted_reference
      blacklisted_sites: blacklisted_sites
    out:
      - mt_aligned_bam
      - mt_aligned_shifted_bam
      # - out_vcf
      # - input_vcf_for_haplochecker
      - duplicate_metrics
      - coverage_metrics
      - theoretical_sensitivity_metrics
      - mean_coverage

outputs:
  subset_bam:
    type: File
    outputSource: SubsetCramToChrM/subset_bam
  mt_aligned_bam:
    type: File
    outputSource: AlignAndCall/mt_aligned_bam
  mt_aligned_shifted_bam:
    type: File
    outputSource: AlignAndCall/mt_aligned_shifted_bam
  duplicate_metrics:
    type: File
    outputSource: AlignAndCall/duplicate_metrics
  coverage_metrics:
    type: File
    outputSource: AlignAndCall/coverage_metrics
  theoretical_sensitivity_metrics:
    type: File
    outputSource: AlignAndCall/theoretical_sensitivity_metrics
  mean_coverage:
    type: File
    outputSource: AlignAndCall/mean_coverage
