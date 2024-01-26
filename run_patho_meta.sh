#!/bin/bash -l

#$ -P pathoscope

#$ -l h_rt=36:00:00

#$ -m a

#$ -N vitA_metagenomic

#$ -pe omp 8

#$ -j y

#$ -o vitA_meta.qlog

#$ -t 1-8   

#$ -l scratch=100G

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

### pathoscope
module load bowtie2/2.3.4.1
module load python2/2.7.16
pathoscope="/restricted/projectnb/pathoscope/code/PathoScope/pathoscope/pathoscope2.py"
indDir="/restricted/projectnb/pathoscope/reflib/2020_index_bowtie"
targLibs="bacteria,fungi,phix174,viral"
filterLibs="human_mouse"

$pathoscope MAP -1 $TMPDIR/$workingDir/combined.R1.paired.fastq.gz -2 $TMPDIR/$workingDir/combined.R2.paired.fastq.gz -indexDir $indDir -targetIndexPrefixes $targLibs -filterIndexPrefixes $filterLibs -expTag $sampleName -outDir $TMPDIR/$workingDir

$pathoscope ID -expTag $sampleName -alignFile $TMPDIR/$workingDir"/outalign.sam" --noUpdatedAlignFile -outDir $dataDir/microbiome/

rm -rf $TMPDIR/$workingDir

