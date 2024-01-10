#!/bin/bash -l

# Set SCC project
#$ -P pathoscope

# Specify hard time limit for the job. 
#   The job will be aborted if it runs longer than this time.
#   The default time is 12 hours
#$ -l h_rt=6:00:00

# Send an email when the job finishes or if it is aborted (by default no email is sent).
#$ -m a

# Give job a name
#$ -N vitA_rnaseq_2021

# Request eight cores
#$ -pe omp 8

# Combine output and error files into a single file
#$ -j y

# Specify the output file name
#$ -o vitA_rnaseq_2021.qlog

#   ask for scratch space
# #$ -l scratch=200G

# Submit an array job with 76 tasks #$ -t 1-76
#$ -t 1-8

# Use the SGE_TASK_ID environment variable to select the appropriate input file from bash array
# Bash array index starts from 0, so we need to subtract one from SGE_TASK_ID value

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

