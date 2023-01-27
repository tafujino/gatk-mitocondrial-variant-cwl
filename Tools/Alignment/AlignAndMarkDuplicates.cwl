#!/usr/bin/env cwl-runner

class: CommandLineTool
id: AlignAndMarkDuplicates
label: AlignAndMarkDuplicates
doc: Uses BWA to align unmapped bam and marks duplicates.
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
      INPUT_BAM: $(inputs.bam)
      BWA_COMMANDLINE: $("bwa mem -K 100000000 -p -v 3 -t 2 -Y " + $(inputs.ref_fasta)) # need InlineJavascriptRequirement ?
      OUTPUT_BAM_BASENAME: $(inputs.outprefix)
      METRICS_FILENAME: $(inputs.bam.nameroot) + ".metrics"
      READ_NAME_REGEX: $(inputs.read_name_regex)
  InitialWorkDirRequirement:
    listing:
      - entryname: AlignAndMarkDuplicates.sh
        entry: |
          set -o pipefail
          set -e

          java -Xms5000m -jar /usr/gitc/picard.jar \
            SamToFastq \
            INPUT=${INPUT_BAM} \
            FASTQ=/dev/stdout \
            INTERLEAVE=true \
            NON_PF=true | \
          /usr/gitc/${BWA_COMMANDLINE} /dev/stdin - 2> >(tee ${OUTPUT_BAM_BASENAME}.bwa.stderr.log >&2) | \
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

          java -Xms4000m -jar /usr/gitc/picard.jar \
            MarkDuplicates \
            INPUT=mba.bam \
            OUTPUT=md.bam \
            METRICS_FILE=${METRICS_FILENAME} \
            VALIDATION_STRINGENCY=SILENT \
            READ_NAME_REGEX=${READ_NAME_REGEX} \
            OPTICAL_DUPLICATE_PIXEL_DISTANCE=2500 \
            ASSUME_SORT_ORDER="queryname" \
            CLEAR_DT="false" \
            ADD_PG_TAG_TO_READS=false

          java -Xms4000m -jar /usr/gitc/picard.jar \
            SortSam \
            INPUT=md.bam \
            OUTPUT=${OUTPUT_BAM_BASENAME}.bam \
            SORT_ORDER="coordinate" \
            CREATE_INDEX=true \
            MAX_RECORDS_IN_RAM=300000

baseCommand: [ /bin/bash, AlignAndMarkDuplicates.sh ]

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
    inputBinding:
      position: 3
      prefix: -R
  bam:
    type: File
    format: edam:format_2572
    secondaryFiles:
      - .bai
  read_name_regex:
    type: string?
    default: ""
  outprefix:
    type: string

outputs:
  bam:
    type: File
    outputBinding:
      glob: $(inputs.outprefix).bam
    secondaryFiles:
      - .bai
  log:
    type: stderr

stderr: $(inputs.outprefix).log
