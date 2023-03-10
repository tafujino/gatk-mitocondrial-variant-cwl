#!/bin/bash

set -o pipefail
set -e

BWA_COMMANDLINE="bwa mem -K 100000000 -p -v 3 -t 2 -Y reference.fa"
java -Xms5000m -jar /usr/gitc/picard.jar \
  SamToFastq \
  INPUT=unmapped.bam \
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
  UNMAPPED_BAM=unmapped.bam \
  OUTPUT=mba.bam \
  REFERENCE_SEQUENCE=reference.fa \
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
  PROGRAM_GROUP_VERSION="0.7.15-r1140" \
  PROGRAM_GROUP_COMMAND_LINE="${BWA_COMMANDLINE}" \
  PROGRAM_GROUP_NAME="bwamem" \
  UNMAPPED_READ_STRATEGY=COPY_TO_TAG \
  ALIGNER_PROPER_PAIR_FLAGS=true \
  UNMAP_CONTAMINANT_READS=true \
  ADD_PG_TAG_TO_READS=false
