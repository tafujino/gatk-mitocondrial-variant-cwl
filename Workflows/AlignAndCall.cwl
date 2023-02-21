#!/usr/bin/env cwl-runner

class: Workflow
id: AlignAndCall
label: AlignAndCall
cwlVersion: v1.1

$namespaces:
  edam: http://edamontology.org/

requirements:
  SubworkflowFeatureRequirement: {}

inputs:
  unmapped_bam:
    type: File
    format: edam:format_2572
  autosomal_coverage:
    type: float?
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

# WDL inputs
#
#    File shift_back_chain
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
  # out_vcf
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
  # The followings are not listed in the original WDL
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
