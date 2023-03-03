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
    doc: Full WGS hg38 CRAM
    type: File
    format: edam:format_3462
    secondaryFiles:
      - .crai
  contig_name:
    doc: >-
      Name of mitochondria contig in reference that `wgs_aligned_input_bam_or_cram`
      is aligned to
    type: string
    default: chrM
  autosomal_coverage:
    doc: Median coverage of full input CRAM
    type: float
    default: 30
  max_read_length:
    doc: >-
      Read length used for optimization only. If this is too small
      CollectWgsMetrics might fail, but the results are not affected by
      this number. Default is 151.
    type: int?
  full_reference:
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
    doc: >-
      Shifted reference is used for calling the control region (edge of mitochondria
      reference). This solves the problem that BWA doesn't support alignment to
      circular contigs.
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
  shift_back_chain:
    type: File
  control_region_shifted_reference_interval_list:
    type: File
  File non_control_region_interval_list:
    type: File
  m2_extra_args:
    type: string?
  m2_filter_extra_args:
    type: string?
  vaf_filter_threshold:
    doc: Hard threshold for filtering low VAF sites
    type: float?
  f_score_beta:
    doc: >-
      F-Score beta balances the filtering strategy between recall and precision.
      The relative weight of recall to precision.
    type: float?
  verifyBamID:
    type: float?
  max_low_het_sites:
    type: int?
  outprefix:
    type: string

steps:
  SubsetCramToChrM:
    label: SubsetCramToChrM
    run: ../Tools/SubsetCramToChrM.cwl
    in:
      contig_name: contig_name
      full_reference: full_reference
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
  CoverageAtEveryBase:
    label: CoverageAtEveryBase
    run: CoverageAtEveryBase.cwl
    in:
      input_bam_regular_ref: AlignAndCall/mt_aligned_bam
      input_bam_shifted_ref: AlignAndCall/mt_aligned_shifted_bam
      shift_back_chain: shift_back_chain
      control_region_shifted_reference_interval_list: control_region_shifted_reference_interval_list
      non_control_region_interval_list: non_control_region_interval_list
      mt_reference: mt_reference
      mt_shifted_reference: mt_shifted_reference
      outprefix: outprefix
    out:
      - per_base_coverage
      - CollectHsMetricsNonControlRegion_log
      - CollectHsMetricsControlRegionShifted_log
      - CombineTable_log
  SplitMultiAllelicSites:
    label: SplitMultiAllelicSites
    run: SplitMultiAllelicSites.cwl
    in:
      reference: mt_reference
      in_vcf: AlignAndCall/out_vcf
    out: [split_vcf, log]


outputs:
  # In the original WDL implementation, a user can choose uncompressed or compressed VCFs as output format.
  # In out CWL implementation, output VCFs are always uncompressed.
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
