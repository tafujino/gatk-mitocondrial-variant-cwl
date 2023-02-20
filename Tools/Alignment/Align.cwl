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
      - entryname: Align.sh
        entry: |
          set -o pipefail
          set -e

          java -Xms5000m -jar /usr/gitc/picard.jar \
            SamToFastq \
            INPUT=${INPUT_BAM} \
            FASTQ=/dev/stdout \
            INTERLEAVE=true \
            NON_PF=true | \
          /usr/gitc/${BWA_COMMANDLINE} /dev/stdin - 2> >(tee ${OUTPUT_BAM_BASENAME}.bwa.log >&2) | \
          java -Xms3000m -jar /usr/gitc/picard.jar \
            MergeBamAlignment \
            VALIDATION_STRINGENCY=SILENT \
            EXPECTED_ORIENTATIONS=FR \
            ATTRIBUTES_TO_RETAIN=X0 \
            ATTRIBUTES_TO_REMOVE=NM \
            ATTRIBUTES_TO_REMOVE=MD \
            ALIGNED_BAM=/dev/stdin \
            UNMAPPED_BAM=${INPUT_BAM} \
            OUTPUT=mba.bam \
            REFERENCE_SEQUENCE=${REF_FASTA} \
            PAIRED_RUN=true \
            SORT_ORDER="unsorted" \
            IS_BISULFITE_SEQUENCE=false \
            ALIGNED_READS_ONLY=false \
            CLIP_ADAPTERS=false \
            MAX_RECORDS_IN_RAM=2000000 \
            ADD_MATE_CIGAR=true \
            MAX_INSERTIONS_OR_DELETIONS=-1 \
            PRIMARY_ALIGNMENT_STRATEGY=MostDistant \
            PROGRAM_RECORD_ID="bwamem" \
            PROGRAM_GROUP_VERSION="${BWA_VERSION}" \
            PROGRAM_GROUP_COMMAND_LINE="${BWA_COMMANDLINE}" \
            PROGRAM_GROUP_NAME="bwamem" \
            UNMAPPED_READ_STRATEGY=COPY_TO_TAG \
            ALIGNER_PROPER_PAIR_FLAGS=true \
            UNMAP_CONTAMINANT_READS=true \
            ADD_PG_TAG_TO_READS=false

baseCommand: [ /bin/bash, Align.sh ]

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
  bwa_log:
    type: File
    doc: the standard error of BWA command
    outputBinding:
      glob: $(inputs.outprefix).bwa.log
  log:
    doc: the entire standard error
    type: stderr

stderr: $(inputs.outprefix).Align.log
