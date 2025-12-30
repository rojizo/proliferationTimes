#!/bin/bash -l
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=7-00:00:00
#SBATCH --array=0-111
#SBATCH --mem-per-cpu=12GB
srun ./computer.sage $SLURM_ARRAY_TASK_ID


