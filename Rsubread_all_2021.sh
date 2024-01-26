#!/bin/bash -l

#$ -P project_name

#$ -l h_rt=6:00:00

#$ -m a

#$ -N vitA_rnaseq

#$ -pe omp 8

#$ -j y

#$ -o vitA_rnaseq_2021.qlog

# #$ -l scratch=200G

#$ -t 1-8

# Keep track of information related to the current job
echo "=========================================================="
echo "Start date : $(date)"
echo "Job name : $JOB_NAME"
echo "Job ID : $SGE_TASK_ID"
echo "=========================================================="

dataDir=/restricted/projectnb/pathoscope/data/vitamin_a_mouse_Kiloni
inputDirs=($(ls -d $dataDir/2021.03.05_3WK_8WK_VA_24SAMPLES/Raw/*))
index=$(($SGE_TASK_ID-1))
sampleName=${inputDirs[$index]##*/}

### MAKE WORKING DIR
workingDir=${inputDirs[$index]##*/}_tmp
rm -rf $TMPDIR/$workingDir
mkdir $TMPDIR/$workingDir

### combine read files
cat ${inputDirs[$index]}/*_R1_*.fastq.gz > $TMPDIR/$workingDir/combined.R1.fastq.gz
cat ${inputDirs[$index]}/*_R2_*.fastq.gz > $TMPDIR/$workingDir/combined.R2.fastq.gz

### TRIM the reads
java -jar ~/pathoscope/code/other/Trimmomatic-0.36/trimmomatic-0.36.jar PE -phred33 -threads 8 $TMPDIR/$workingDir/combined.R1.fastq.gz  $TMPDIR/$workingDir/combined.R2.fastq.gz $TMPDIR/$workingDir/combined.R1.paired.fastq.gz $TMPDIR/$workingDir/combined.R1.unpaired.fastq.gz $TMPDIR/$workingDir/combined.R2.paired.fastq.gz $TMPDIR/$workingDir/combined.R2.unpaired.fastq.gz SLIDINGWINDOW:4:20 LEADING:3 TRAILING:3 MINLEN:36

## Rsubread
module load R
Rsubread_script=mouse_rnaseq/ProcessRnaSeqFeatureCounts.R
genome=/restricted/projectnb/pathsig/ref/rsubread_mm10/mm10
genes=mm10
threads=8

Rscript $dataDir/$Rsubread_script $genome $TMPDIR/$workingDir/combined.R1.paired.fastq.gz $TMPDIR/$workingDir/combined.R2.paired.fastq.gz $genes $dataDir/mouse_rnaseq/$sampleName $threads

rm -rf $TMPDIR/$workingDir

