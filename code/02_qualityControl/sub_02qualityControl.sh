#!/bin/bash
#SBATCH --job-name=qc
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --array=1-6

module load conda_R/4.3.x

Rscript 02_qualityControl.R
