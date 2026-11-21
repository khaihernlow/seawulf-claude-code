#!/bin/bash
# Many independent runs (parameter sweep): one array task per input. Max array size here is 1001.
#SBATCH --job-name=my-sweep
#SBATCH --partition=short-40core-shared
#SBATCH --array=0-9%4                     # tasks 0..9, at most 4 running at once
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=00:30:00
#SBATCH --output=%x-%A_%a.out             # %A = array job id, %a = task index

set -euo pipefail
module purge
cd "$SLURM_SUBMIT_DIR"
INPUTS=(a b c d e f g h i j)              # or: mapfile -t INPUTS < inputs.txt
echo "task $SLURM_ARRAY_TASK_ID -> ${INPUTS[$SLURM_ARRAY_TASK_ID]}"
