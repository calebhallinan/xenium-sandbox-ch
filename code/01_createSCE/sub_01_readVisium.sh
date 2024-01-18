#!/bin/bash
#SBATCH --job-name=READ_VISIUM
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16


module load conda_R/4.3.x

Rscript readVisium.R