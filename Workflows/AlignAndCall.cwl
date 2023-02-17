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
    secondaryFiles:
      - .bai
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
  blacklisted_sites:
    doc: blacklist sites in BED format
    type: File
    format: edam:format_3003
    secondaryFiles:
      - .idx

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
    run: Alignment.cwl
    in:
      reference: mt_reference
      unmapped_bam: unmapped_bam
      outprefix:
        valueFrom: $(self.unmapped_bam.nameroot).alignedToMt
    out: [bam, metrics, bwa_log, bam_log]
  AlignToShiftedMt:
    label: Alignment.cwl
    run: ../Tools/Alignment/AlignAndMarkDuplicates.cwl
    in:
      reference: mt_shifted_reference
      unmapped_bam: unmapped_bam
      outprefix:
        valueFrom: $(self.unmapped_bam.nameroot).alignedToShiftedMt
    out: [bam, metrics, bwa_log, bam_log]

outputs:
  alignToMt_metrics:
    type: File
    outputSource: AlignToMt/metrics
  alignToMt_bwa_log:
    type: File
    outputSource: AlignToMt/bwa_log
  alignToMt_bam_log:
    type: File
    outputSource: AlignToMt/bam_log
  alignToShiftedMt_metrics:
    type: File
    outputSource: AlignToShiftedMt/metrics
  alignToShiftedMt_bwa_log:
    type: File
    outputSource: AlignToShiftedMt/bwa_log
  alignToShiftedMt_bam_log:
    type: File
    outputSource: AlignToShiftedMt/bam_log
