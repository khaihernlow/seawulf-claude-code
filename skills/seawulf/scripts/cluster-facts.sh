#!/bin/bash
# Run ON SeaWulf (e.g. `sw run < cluster-facts.sh`): a compact, current picture of what this user can use.
# Use it instead of trusting dated notes: queues, limits, node states, quotas and key modules change.
command -v sinfo > /dev/null || module load slurm 2> /dev/null

echo "== $(date -Is) on $(hostname) as $USER"

echo; echo "== queues: name | time limit | nodes | cores/node | MB/node | GPUs"
sinfo -h -o "%P|%l|%D|%c|%m|%G" | sort -u | column -t -s '|'

echo; echo "== node states per queue family (draining/drained nodes take no new jobs)"
for p in a100 short-40core short-96core hbm-short-96core; do
  printf '%-18s ' "$p"; sinfo -h -p "$p" -o "%T %D" | tr '\n' ' '; echo
done
sinfo -h -p a100 -N -o "%N %T %E" | grep -viE " (idle|mixed|allocated) none$" | sed 's/^/  a100 node: /'

echo; echo "== per-user limits (QOS): name | max wall | max running | max submitted | max resources"
sacctmgr -n -P show qos format=Name,MaxWall,MaxJobsPU,MaxSubmitPU,MaxTRESPU 2> /dev/null \
  | grep -E '^(debug|short|medium|long|extended|large|a100|hbm)' | column -t -s '|'

echo; echo "== your Slurm accounts"
sacctmgr -n -P show assoc user="$USER" format=Account,Partition,QOS 2> /dev/null | sort -u

echo; echo "== your storage"
myquota 2> /dev/null || df -h "$HOME" "/gpfs/scratch/$USER"
ls -d /gpfs/projects/* 2> /dev/null | while read -r d; do [ -w "$d" ] && echo "writable project space: $d"; done

echo; echo "== key modules"
module -t avail 2>&1 | grep -E '^(anaconda|miniforge|mamba|python|gcc|openmpi|cuda[0-9]*/toolkit|cudnn|singularity|jupyter|git)' | tr '\n' ' '; echo

echo; echo "== your jobs"
squeue --me -o "%.10i %.20j %.12P %.8T %.10M %.20S %R" 2> /dev/null
