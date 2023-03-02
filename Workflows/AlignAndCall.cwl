#!/usr/bin/env cwl-runner

class: Workflow
id: AlignAndCall
label: AlignAndCall
cwlVersion: v1.1

$namespaces:
  edam: http://edamontology.org/

requirements:
  SubworkflowFeatureRequirement: {}
  InlineJavascriptRequirement: {}

inputs:
  unmapped_bam:
    type: File
    format: edam:format_2572
  # In the original WDL implementation, input parameter `autosomal_coverage` is optional.
  # If it is defined, task `FilterNuMTs` is run (otherwise not run).
  # In this CWL implementation, the parameter is mandatory and step `FilterNuMTs` is always executed.
  autosomal_coverage:
    type: float
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
  max_read_length:
    type: int?
  shift_back_chain:
    type: File
  m2_extra_args:
    type: string?
  m2_filter_extra_args:
    type: string?
  vaf_filter_threshold:
    type: float?
  f_score_beta:
    type: float?
  verifyBamID:
    type: float?

# WDL inputs
#
#    File? gatk_override
#    String? gatk_docker_override
#    String? m2_extra_args
#    String? m2_filter_extra_args
#    Float? vaf_filter_threshold
#    Float? f_score_beta
#    Boolean compress_output_vcf
#    Float? verifyBamID
#    Int? max_low_het_sites
#
#    # Read length used for optimization only. If this is too small CollectWgsMetrics might fail, but the results are not
#    # affected by this number. Default is 151.
#    Int? max_read_length
#
#    #Optional runtime arguments
#    Int? preemptible_tries

steps:
  AlignToMt:
    label: AlignToMt
    run: AlignAndMarkDuplicates.cwl
    in:
      reference: mt_reference
      unmapped_bam: unmapped_bam
      outprefix:
        valueFrom: $(self.unmapped_bam.nameroot).alignedToMt
    out: [bam, duplicate_metrics, bwa_log, Align_log, MarkDuplicates_log, SortSam_log]
  AlignToShiftedMt:
    label: AlignToShiftedMt
    run: AlignAndMarkDuplicates.cwl
    in:
      reference: mt_shifted_reference
      unmapped_bam: unmapped_bam
      outprefix:
        valueFrom: $(self.unmapped_bam.nameroot).alignedToShiftedMt
    out: [bam, duplicate_metrics, bwa_log, Align_log, MarkDuplicates_log, SortSam_log]
  CollectWgsMetrics:
    label: CollectWgsMetrics
    run: ../Tools/AlignAndCall/CollectWgsMetrics.cwl
    in:
      bam: AlignToMt/bam
      reference: mt_reference
      read_length: max_read_length
      coverage_cap:
        default: 100000
    out: [coverage_metrics, theoretical_sensitivity, log]
  MeanCoverage:
    label: MeanCoverage
    run: ../Tools/AlignAndCall/MeanCoverage.cwl
    in:
      coverage_metrics: CollectWgsMetrics/coverage_metrics
    out: [mean_coverage, log]
  CallMt:
    label: CallMt
    run: ../Tools/AlignAndCall/M2.cwl
    in:
      # NOTE: may need to set `java_options`
      reference: mt_reference
      bam: AlignToMt/bam
      m2_extra_args:
        source: m2_extra_args
        valueFrom: $([self.m2_extra_args, "-L chrM:576-16024"].filter(Boolean).join(" "))
    out: [raw_vcf, stats, log]
  CallShiftedMt:
    label: CallShiftedMt
    run: ../Tools/AlignAndCall/M2.cwl
    in:
      # NOTE: may need to set `java_options`
      reference: mt_shifted_reference
      bam: AlignToShiftedMt/bam
      m2_extra_args:
        source: m2_extra_args
        valueFrom: $([self.m2_extra_args, "-L chrM:8025-9144"].filter(Boolean).join(" "))
    out: [raw_vcf, stats, log]
  LiftoverVcf:
    label: LiftoverVcf
    run: ../Tools/AlignAndCall/LiftoverVcf.cwl
    in:
      shifted_vcf: CallShiftedMt/raw_vcf
      reference: mt_reference
      shift_back_chain: shift_back_chain
    out: [shifted_back_vcf, rejected_vcf, log]
  MergeVcfs:
    label: MergeVcfs
    run: ../Tools/AlignAndCall/MergeVcfs.cwl
    in:
      shifted_back_vcf: LiftoverVcf/shifted_back_vcf
      vcf: CallMt/raw_vcf
      outprefix:
        source: unmapped_bam
        valueFrom: $(self.unmapped_bam.nameroot)
    out: [merged_vcf, log]
  MergeStats:
    label: MergeStats
    run: ../Tools/AlignAndCall/MergeStats.cwl
    in:
      shifted_stats: CallShiftedMt/stats
      non_shifted_stats: CallMt/stats
      outprefix:
        source: unmapped_bam
        valueFrom: $(self.unmapped_bam.nameroot)
    out:
      [stats, log]
  InitialFilter:
    label: InitialFilter
    run: ../Workflows/Filter.cwl
    in:
      reference: mt_reference
      raw_vcf: MergeVcfs/merged_vcf
      raw_vcf_stats: MergeStats/stats
      m2_extra_filtering_args: m2_filter_extra_args
      max_alt_allele_count:
        default: 4
      vaf_filter_threshold:
        default: 0
      f_score_beta: f_score_beta
      run_contamination:
        default: false
      blacklisted_sites: blacklisted_sites
      outprefix:
        source: unmapped_bam
        valueFrom: $(self.unmapped_bam.nameroot).initialFilter
    out: [filtered_vcf, FilterMutectCalls_log, VariantFiltration_log]
  SplitMultiAllelicSites:
    label: SplitMultiAllelicSites
    run: ../Tools/SplitMultiAllelicSites.cwl
    in:
      reference: mt_reference
      in_vcf: InitialFilter/filtered_vcf
    out: [split_vcf, log]
  SelectVariants:
    label: SelectVariants
    run: ../Tools/AlignAndCall/SelectVariants.cwl
    in:
      in_vcf: SplitMultiAllelicSites/split_vcf
    out: [out_vcf, log]
  GetContamination:
    label: GetContamination
    run: ../Tools/AlignAndCall/GetContamination.cwl
    in:
      vcf: SelectVariants/out_vcf
    out:
      - contamination
      - hasContamination
      - minor_hg
      - major_hg
      - minor_level
      - major_level
      - log
  FilterContamination:
    label: InitialFilter
    run: ../Workflows/Filter.cwl
    in:
      reference: mt_reference
      raw_vcf: InitialFilter/filtered_vcf
      raw_vcf_stats: MergeStats/stats
      m2_extra_filtering_args: m2_filter_extra_args
      max_alt_allele_count:
        default: 4
      vaf_filter_threshold: vaf_filter_threshold
      f_score_beta: f_score_beta
      run_contamination:
        default: true
      hasContamination: GetContamination/hasContamination
      contamination_major: GetContamination/major_level
      contamination_minor: GetContamination/minor_level
      verifyBamID: verifyBamID
      blacklisted_sites: blacklisted_sites
      outprefix:
        source: unmapped_bam
        valueFrom: $(self.unmapped_bam.nameroot).filterContamination
    out: [filtered_vcf, contamination, FilterMutectCalls_log, VariantFiltration_log]
  FilterNuMTs:
    label: FilterNuMTs
    run: ../Tools/AlignAndCall/FilterNuMTs.cwl
    in:
      reference: mt_reference
      in_vcf: FilterContamination/filtered_vcf
      autosomal_coverage: autosomal_coverage
      outprefix:
        source: unmapped_bam
        valueFrom: $(self.unmapped_bam.nameroot).filterNuMTs
    out: [out_vcf, log]
  FilterLowHetSites:
    label: FilterLowHetSites
    run: ../Tools/AlignAndCall/FilterLowHetSites.cwl
    in:
      reference: mt_reference
      in_vcf: FilterNuMTs/out_vcf
      outprefix:
        source: unmapped_bam
        valueFrom: $(self.unmapped_bam.nameroot).final
    out: [out_vcf, log]


# WDL
#
#   output {
#     File mt_aligned_bam = AlignToMt.mt_aligned_bam
#     File mt_aligned_bai = AlignToMt.mt_aligned_bai
#     File mt_aligned_shifted_bam = AlignToShiftedMt.mt_aligned_bam
#     File mt_aligned_shifted_bai = AlignToShiftedMt.mt_aligned_bai
#     File out_vcf = FilterLowHetSites.final_filtered_vcf
#     File out_vcf_index = FilterLowHetSites.final_filtered_vcf_idx
#     File input_vcf_for_haplochecker = SplitMultiAllelicsAndRemoveNonPassSites.vcf_for_haplochecker
#     File duplicate_metrics = AlignToMt.duplicate_metrics
#     File coverage_metrics = CollectWgsMetrics.metrics
#     File theoretical_sensitivity_metrics = CollectWgsMetrics.theoretical_sensitivity
#     File contamination_metrics = GetContamination.contamination_file
#     Int mean_coverage = CollectWgsMetrics.mean_coverage
#     String major_haplogroup = GetContamination.major_hg
#     Float contamination = FilterContamination.contamination
#   }

outputs:
  mt_aligned_bam:
    type: File
    outputSource: AlignToMt/bam
  mt_aligned_shifted_bam:
    type: File
    outputSource: AlignToShiftedMt/bam
  out_vcf:
    type: File
    outputSource:

  # input_vcf_for_haplochecker
  duplicate_metrics:
    type: File
    outputSource: AlignToMt/duplicate_metrics
  coverage_metrics:
    type: File
    outputSource: CollectWgsMetrics/coverage_metrics
  theoretical_sensitivity_metrics:
    type: File
    outputSource: CollectWgsMetrics/theoretical_sensitivity
  # contamination_metrics
  mean_coverage:
    type: File
    outputSource: MeanCoverage/mean_coverage
  #
  # The followings are not listed in the original WDL
  #
  AlignToMt_BWA_log:
    type: File
    outputSource: AlignToMt/bwa_log
  AlignToMt_Align_log:
    type: File
    outputSource: AlignToMt/Align_log
  AlignToMt_MarkDuplicates_log:
    type: File
    outputSource: AlignToMt/MarkDuplicates_log
  AlignToMt_SortSam_log:
    type: File
    outputSource: AlignToMt/SortSam_log
  AlignToShiftedMt_BWA_log:
    type: File
    outputSource: AlignToShiftedMt/bwa_log
  AlignToShiftedMt_Align_log:
    type: File
    outputSource: AlignToShiftedMt/Align_log
  AlignToShiftedMt_MarkDuplicates_log:
    type: File
    outputSource: AlignToShiftedMt/MarkDuplicates_log
  AlignToShiftedMt_SortSam_log:
    type: File
    outputSource: AlignToShiftedMt/SortSam_log
  CollecWgsMetrics_log:
    type: File
    outputSource: CollectWgsMetrics/log
  CallMt_log:
    type: File
    outputSource: CallMt/log
  CallShiftedMt_log:
    type: File
    outputSource: CallShiftedMt/log
