#!/bin/bash

# Update the user and name variables, user is your K-State eID.
# Also use update the email id to get notification about the job.
user=eID
name=projectName
#$ -m abe -M eID@ksu.edu

# Update beocat resources request
#$ -l h_rt=13:00:00 -l mem=32G -l nokillable -cwd -j y


## #######################################
## NO NEED TO CHANGE ANYTHING FROM HERE ON
## #######################################

# Set JAVA VM Version to 1.8
eselect java-vm set user oracle-jdk-bin-1.8

keyFile=/homes/$user/gbs/jobs/${name}.txt

seqDir=/bulk/jpoland/sequence
dbPath=/bulk/nss470/genomes/CS_NRGene/pseudomolecules_v1.0/161010_Chinese_Spring_v1.0_pseudomolecules_parts
tasselPath=/homes/nss470/softwares/tassel5/run_pipeline.pl

mkdir /homes/$user/gbs/projects/${name}
mkdir /homes/$user/gbs/projects/${name}/keyFileSh
cd /homes/$user/gbs/projects/${name}

# Path for required software
export PATH=$PATH:/homes/nss470/usr/bin:/homes/nss470/usr/bin/bin

## GBSSeqToTagDBPlugin - RUN Tags to DB
$tasselPath -Xms64G -Xmx64G -fork1 -GBSSeqToTagDBPlugin -e PstI-MspI \
    -i $seqDir \
    -db ${name}.db \
    -k $keyFile \
    -kmerLength 64 -minKmerL 20 -mnQS 20 -mxKmerNum 250000000 \
    -endPlugin -runfork1 >> z_pipeline.out

## TagExportToFastqPlugin - export Tags
$tasselPath -fork1 -TagExportToFastqPlugin \
    -db ${name}.db \
    -o ${name}_tagsForAlign.fa.gz -c 10 \
    -endPlugin -runfork1 >> z_pipeline.out

## RUN BOWTIE
bowtie2 -p 20 --end-to-end \
    -x $dbPath \
    -U ${name}_tagsForAlign.fa.gz \
    -S ${name}.sam >> z_pipeline.out

## SAMToGBSdbPlugin - SAM to DB
$tasselPath -Xms64G -Xmx64G -fork1 -SAMToGBSdbPlugin \
    -i ${name}.sam \
    -db ${name}.db \
    -aProp 0.0 -aLen 0 \
    -endPlugin -runfork1 >> z_pipeline.out

## DiscoverySNPCallerPluginV2 - RUN DISCOVERY SNP CALLER
$tasselPath -Xms64G -Xmx64G -fork1 -DiscoverySNPCallerPluginV2 \
    -db ${name}.db \
    -mnLCov 0.1 -mnMAF 0.01 -deleteOldData true \
    -endPlugin -runfork1 >> z_pipeline.out

## SNPQualityProfilerPlugin - RUN QUALITY PROFILER
$tasselPath -Xms64G -Xmx64G -fork1 -SNPQualityProfilerPlugin \
    -db ${name}.db \
    -statFile ${name}_SNPqual_stats.txt \
    -endPlugin -runfork1 >> z_pipeline.out

## UpdateSNPPositionQualityPlugin - UPDATE DATABASE WITH QUALITY SCORE
$tasselPath -Xms64G -Xmx64G -fork1 -UpdateSNPPositionQualityPlugin \
    -db ${name}.db \
    -qsFile ${name}_SNPqual_stats.txt \
    -endPlugin -runfork1 >> z_pipeline.out

## ProductionSNPCallerPluginV2 - RUN PRODUCTION PIPELINE - output .vcf
$tasselPath -Xms64G -Xmx64G -fork1 -ProductionSNPCallerPluginV2 \
    -db ${name}.db \
    -i $seqDir \
    -k $keyFile \
    -o ${name}.vcf \
    -e PstI-MspI -kmerLength 64 \
    -endPlugin -runfork1 >> z_pipeline.out

## Convert to Hapmap format
$tasselPath -Xms64G -Xmx64G -fork1 -vcf ${name}.vcf \
    -export ${name} -exportType Hapmap

mv /homes/$user/gbs/jobs/${name}.* keyFileSh/