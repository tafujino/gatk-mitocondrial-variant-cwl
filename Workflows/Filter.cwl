#!/usr/bin/env cwl-runner

class: Workflow
id: Filter
label: Filter
cwlVersion: v1.1

$namespaces:
  edam: http://edamontology.org/

requirements:
  InlineJavascriptRequirement: {}

inputs:
  reference:
    type: File
    format: edam:format_1929
    secondaryFiles:
      - .fai
      - ^.dict
  raw_vcf:
    type: File
    format: edam:format_3016
    secondaryFiles:
      - .idx
  raw_vcf_stats:
    type: File
  m2_extra_filtering_args:
    type: string?
  max_alt_allele_count:
    type: int
  autosomal_coverage:
    type: float?
  vaf_filter_threshold:
    type: float?
  f_score_beta:
    type: float?
  run_contamination:
    type: boolean
  hasContamination:
    type: string?
  # In the original WDL implementation, contamination_major and contamination_minor are optional.
  # However, we changed them to mandatory parameters since undefined values may cause incorrect calculation.
  # (Actually the values are always given from the upstream part of the workflow and there is no possibility
  # that these inputs are undefined.)
  contamination_major:
    type: float
  contamination_minor:
    type: float
  verifyBamID:
    type: float?
  blacklisted_sites:
    doc: blacklist sites in BED format
    type: File
    format: edam:format_3003
    secondaryFiles:
      - .idx
  outprefix:
    type: string

steps:
  CalcContamination:
    label: CalcContamination
    run: ../Tools/Filter/CalcContamination.cwl
    in:
      run_contamination: run_contamination
      hasContamination: hasContamination
      contamination_major: contamination_major
      contamination_minor: contamination_minor
      verifyBamID: verifyBamID
    out: [hc_contamination, max_contamination]
  FilterMutectCalls:
    label: FilterMutectCalls
    run: ../Tools/Filter/FilterMutectCalls.cwl
    in:
      raw_vcf: raw_vcf
      raw_vcf_stats: raw_vcf_stats
      reference: reference
      m2_extra_filtering_args: m2_extra_filtering_args
      max_alt_allele_count: max_alt_allele_count
      vaf_filter_threshold: vaf_filter_threshold
      f_score_beta: f_score_beta
      max_contamination: CalcContamination/max_contamination
    out: [filtered_vcf, log]
  VariantFiltration:
    label: VariantFiltration
    run: ../Tools/Filter/VariantFiltration.cwl
    in:
      in_vcf: FilterMutectCalls/filtered_vcf
      blacklisted_sites: blacklisted_sites
      outprefix: outprefix
    out: [out_vcf, log]

outputs:
  filtered_vcf:
    type: File
    outputSource: VariantFiltration/out_vcf
  contamination:
    type: float
    outputSource: CalcContamination/hc_contamination
  # The followings are not listed in the original WDL
  FilterMutectCalls_log:
    type: File
    outputSource: FilterMutectCalls/log
  VariantFiltration_log:
    type: File
    outputSource: VariantFiltration/log
