#!/bin/bash -l
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=30-00:00:00
#SBATCH --mem-per-cpu=10GB
python3 client.py SERVER.NAME

