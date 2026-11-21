#!/bin/bash
# A few cores on a shared node: the right default for most small jobs (starts sooner than a whole node).
#SBATCH --job-name=my-job
#SBATCH --partition=short-40core-shared   # 4 h max; long-40core-shared: 2 days
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G                         # required on -shared queues (default is ~2.4 GB per core)
#SBATCH --time=01:00:00                   # ask for what you need: shorter jobs start sooner
#SBATCH --output=%x-%j.out                # %x = job name, %j = job id
#SBATCH --error=%x-%j.err

set -euo pipefail
module purge
# module load anaconda/3 && conda activate /path/to/env   # see references/software.md
cd "$SLURM_SUBMIT_DIR"
echo "job $SLURM_JOB_ID on $(hostname), $SLURM_CPUS_PER_TASK cpus"
python3 -c "print('hello from', __import__('socket').gethostname())"
