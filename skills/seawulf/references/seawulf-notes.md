# SeaWulf notes

What has been observed, how, and when. Clusters change: re-check anything that matters on the cluster itself
before relying on it. **Verified** = seen directly by running the command; **reported** = from SBU or lab
notes, not re-checked here.

| Fact | Status |
| --- | --- |
| Every new ssh session asks for Duo, including sessions multiplexed over an open ControlMaster connection (login node `milan`) | Verified 2026-11-20 |
| An unapproved Duo push makes the command fail after ~60 s with exit 1 and no output | Verified 2026-11-20 |
| scp/sftp over the shared connection failed (`Connection closed` / `lost connection`); streaming through ssh worked | Verified 2026-11-20 (Windows/WSL client) |
| Slurm 21.08; `squeue`, `sbatch` and `module` are only on the PATH in a login shell (`bash -l`) | Verified 2026-11-20 |
| GPU partitions `a100`, `a100-long` (2-day limit), `a100-large` share the same 11 nodes `a100-[01-11]`, 4 x A100 80GB each | Verified with `sinfo` 2026-11-20 (GPU count per node reported) |
| Nodes can be `draining` ("Reboot ASAP") for days; on 2026-11-20, 7 of 11 A100 nodes were, and queue estimates were ~3 days | Verified 2026-11-20 |
| Many CPU partitions (`short-40core-shared`, `short-96core`, `hbm-*`, ...); a 1-CPU job on `short-40core-shared` started within a minute | Verified 2026-11-20 |
| Compute nodes reach huggingface.co and pypi.org; the login node reaches GitHub | Verified 2026-11-20 |
| `module load anaconda/3`, then `conda create -p /gpfs/scratch/$USER/...` works for envs | Verified 2026-11-12 |
| Home quota ~20 GB; use `/gpfs/scratch/$USER` (not backed up) | Reported |
| At most 2 running jobs per user on `a100` (QOS) | Reported; the queue showed `QOSMaxJobsPerUserLimit` reasons for `a100-long` |
| `sbatch` can print `Socket timed out` and still create the job | Reported |
| The OnDemand web shell mangles multi-line pastes | Reported |
| `singularity pull` from Docker Hub was SIGKILLed during extraction; `crane export` in a CPU job worked | Reported |
| The login banner restricts using SBU computing to train AI models for entities headquartered in listed countries | Seen on login 2026-11-20 |

Slurm accounts (`-A`) are per user or group: find yours with `sacctmgr show assoc user=$USER format=account,partition`.
