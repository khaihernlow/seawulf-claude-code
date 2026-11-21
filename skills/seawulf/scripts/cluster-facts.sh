#!/bin/bash
# Run ON SeaWulf or NVwulf (e.g. `sw run < cluster-facts.sh`): a compact, current picture of what this user can use.
# Use it instead of trusting dated notes: queues, limits, node states, quotas and key modules change.
command -v sinfo > /dev/null || module load slurm 2> /dev/null

if [ -d /lustre/nvwulf ]; then CLUSTER=NVwulf; else CLUSTER=SeaWulf; fi
echo "== $CLUSTER, $(date -Is) on $(hostname) as $USER"

echo; echo "== queues: name | time limit | nodes | cores/node | MB/node | GPUs"
sinfo -h -o "%P|%l|%D|%c|%m|%G" | sort -u | column -t -s '|'

echo; echo "== load and node states per queue (draining/drained/down nodes take no new jobs)"
for p in $(sinfo -h -o "%P" | tr -d '*' | sort -u); do
  printf '%-24s running=%-4s pending=%-4s nodes: %s\n' "$p" \
    "$(squeue -h -p "$p" -t R 2> /dev/null | wc -l)" "$(squeue -h -p "$p" -t PD 2> /dev/null | wc -l)" \
    "$(sinfo -h -p "$p" -o "%T %D" | tr '\n' ' ')"
done
sinfo -h -N -o "%N %T %E" | sort -u | grep -iE "drain|down|fail|maint" | sed 's/^/  unavailable: /'

echo; echo "== per-user limits (QOS): name | max wall | max running | max submitted | max resources"
sacctmgr -n -P show qos format=Name,MaxWall,MaxJobsPU,MaxSubmitPU,MaxTRESPU 2> /dev/null \
  | grep -vE '^(normal|block_default|dave100)?\|' | column -t -s '|'

echo; echo "== your Slurm accounts and QOS"
assoc=$(sacctmgr -n -P show assoc user="$USER" format=Account,Partition,QOS 2> /dev/null | sort -u)
echo "$assoc"
if echo "$assoc" | grep -qi "block"; then
  echo "  WARNING: a blocking QOS is attached: jobs will pend with QOSMaxJobsPerUserLimit."
  echo "  On NVwulf this follows going over the storage quota. Check the quota below; if it's under, ask RCI (references/getting-help.md)."
fi

echo; echo "== your storage"
if [ "$CLUSTER" = NVwulf ]; then
  echo "(one quota over all of /lustre: home and scratch together; '*' after 'used' = over quota)"
  lfs quota -h -u "$USER" /lustre 2> /dev/null | sed -n '2,3p'
  du -sh "/lustre/nvwulf/home/$USER" "/lustre/nvwulf/scratch/$USER" 2> /dev/null
  projects=/lustre/nvwulf/projects
else
  myquota 2> /dev/null || df -h "$HOME" "/gpfs/scratch/$USER"
  projects=/gpfs/projects
fi
for d in "$projects"/*; do [ -d "$d" ] && [ -w "$d" ] && echo "writable project space: $d"; done

echo; echo "== key modules"
module -t avail 2>&1 | grep -E '^(anaconda|miniforge|mamba|python|pytorch|tensorflow|vllm|gcc|openmpi|cuda[0-9.]*/toolkit|cudnn|nccl|singularity|jupyter|git|claude-code)' \
  | tr '\n' ' '; echo

echo; echo "== your jobs"
squeue --me -o "%.10i %.20j %.12P %.8T %.10M %.20S %R" 2> /dev/null
