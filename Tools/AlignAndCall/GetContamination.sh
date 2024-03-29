#!/bin/bash

set -e
java -jar /usr/mtdnaserver/haplocheckCLI.jar .

sed 's/\"//g' output > output-noquotes

grep "SampleID" output-noquotes > headers
FORMAT_ERROR="Bad contamination file format"
if [ `awk '{print $2}' headers` != "Contamination" ]; then
  echo $FORMAT_ERROR; exit 1
fi
if [ `awk '{print $6}' headers` != "HgMajor" ]; then
  echo $FORMAT_ERROR; exit 1
fi
if [ `awk '{print $8}' headers` != "HgMinor" ]; then
  echo $FORMAT_ERROR; exit 1
fi
if [ `awk '{print $14}' headers` != "MeanHetLevelMajor" ]; then
  echo $FORMAT_ERROR; exit 1
fi
if [ `awk '{print $15}' headers` != "MeanHetLevelMinor" ]; then
  echo $FORMAT_ERROR; exit 1
fi

grep -v "SampleID" output-noquotes > output-data
awk '{print $2}' output-data > contamination.txt
awk '{print $6}' output-data > major_hg.txt
awk '{print $8}' output-data > minor_hg.txt
awk '{print $14}' output-data > mean_het_major.txt
awk '{print $15}' output-data > mean_het_minor.txt
