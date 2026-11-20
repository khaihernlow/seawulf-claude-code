#!/bin/bash
# One A100 80GB GPU. A100 nodes have 4 GPUs, 64 cores and ~256 GB RAM, shared between jobs:
# ask for a proportional slice (per GPU: up to 16 cores, ~60 GB).
#SBATCH --job-name=my-gpu-job
#SBATCH --partition=a100                  # 8 h max; a100-long: 2 days (1 node); a100-large: up to 4 nodes
#SBATCH --gres=gpu:1                      # number of GPUs on the node (1-4)
#SBATCH --cpus-per-task=8
#SBATCH --mem=60G
#SBATCH --time=02:00:00
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

set -eo pipefail                         # (no -u: conda's activate scripts reference unset variables)
module purge
module load anaconda/3                   # or miniforge/3
conda activate /gpfs/home/$USER/envs/myenv   # the env's real path; works in batch jobs as is
# module load cuda120/toolkit/12.0     # only if you compile CUDA code; pip PyTorch wheels bring their own CUDA
cd "$SLURM_SUBMIT_DIR"
nvidia-smi                               # proves the job got a GPU
python train.py
