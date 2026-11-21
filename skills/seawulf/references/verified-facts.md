# What was checked, how, and when

Clusters change. Status: **verified** = seen by running it on SeaWulf; **docs** = RCI documentation (fetched
2026-11-20); **reported** = from users' notes, not re-checked. Where the docs and the cluster disagree, the
cluster's own answer is used and the disagreement is noted. Refresh with `scripts/cluster-facts.sh`.

| Fact | Status |
| --- | --- |
| Login host `milan.seawulf.stonybrook.edu` (milan1/milan2); `/etc/hosts` also lists login1/login2 | Verified 2026-11-20 |
| `login.seawulf` (login1/login2), Haswell and K80/P100/V100 retired November 2026 | Docs |
| OS Rocky Linux 9.8; Slurm 21.08; Environment Modules 4.5.3 (no `module spider`) | Verified 2026-11-20 |
| `squeue`/`sbatch`/`module` are on the PATH in a login shell; otherwise `module load slurm` | Verified 2026-11-20 (non-login shell lacked squeue) |
| Every login needs Duo; 10 unanswered requests in a row lock the account | Docs |
| Over a reused ssh connection (ControlMaster), each new session still prompted Duo on milan from a Windows/WSL client | Verified 2026-11-20 (the docs say reuse avoids repeat prompts: client-dependent?) |
| On the SBU VPN, Duo is approved once at VPN connect | Docs |
| SSH key login (no password, no connection reuse) still sends a Duo push | Verified 2026-11-20 (milan) |
| Claude Code on the cluster: unsigned `claude -p` says `Not logged in`; `claude auth login` (`--claudeai` default, `--console`, `--sso`) and `claude setup-token` exist | Verified 2026-11-20; sign-in itself untested |
| scp/sftp over a reused connection failed; `tar \| ssh` streaming worked | Verified 2026-11-20 (Windows/WSL client) |
| Queue time limits, node counts, min/max nodes, default memory per CPU (CPU-shared 2400 MB, A100 4016 MB) | Verified with `scontrol show partition` 2026-11-20 (docs give `debug-40core` max 8 nodes; scontrol says 6) |
| Per-user QOS limits (running jobs, submitted 100, shared-queue cpu/mem caps) | Verified with `sacctmgr show qos` 2026-11-20 |
| A100 nodes: 11 (`a100-[01-11]`), 4 x A100 each, 64 cores, ~257 GB; shared; the three a100 queues use the same nodes | Verified (`sinfo`, `scontrol show node`); 80 GB per GPU from docs |
| On 2026-11-20, 7/11 A100 nodes and 25+ HBM nodes were `draining` ("Reboot ASAP"); the GPU queue estimate was ~3-4 days | Verified 2026-11-20 |
| CPU nodes: dn* 40 cores / 192 GB; dg* 96 cores / 256 GB; xm* (HBM) 96 cores / ~380 GB | Verified (`scontrol show node`) |
| `sbatch --test-only`, arrays (`%A_%a`, `%4` throttle), `seff`, `myquota` | Verified 2026-11-20 (templates submitted and ran) |
| MaxArraySize 1001; backfill scheduler; multifactor priority | Verified (`scontrol show config`) |
| Home 20 GB / 200k files; scratch 20 TB / 10M files | Verified (`myquota`) |
| Scratch purge after 45 days (older pages: 30); project space up to 10 TB, not backed up | Docs |
| Never build envs/software in scratch; never install into conda base | Docs |
| Modules: CUDA up to `cuda133/toolkit/13.3`, cudnn 9.12, `anaconda/3` (default 3-new), `miniforge/3`, `python/3.14.6`, gcc to 13.2, `jupyter`, `globus`, `claude-code` | Verified (`module -t avail`, milan) |
| SingularityCE 4.5.1; no apptainer | Verified |
| `singularity pull` of a large Docker image SIGKILLed on extraction (likely the 15 GB login limit) | Reported |
| Login node reaches GitHub; compute nodes reach github.com, huggingface.co and pypi.org | Verified 2026-11-20 |
| Login node per-user limits: 3 CPUs (`cpu.max 300000 100000`) and 15 GiB memory (`memory.max`), enforced by cgroup; the node has 128 cores / 503 GB shared | Verified 2026-11-20 (`/sys/fs/cgroup/user.slice/user-$UID.slice`) |
| Claude Code available as a module (`claude-code/2.1.42`, `2.1.49`, `2.1.207`; loads `node.js/24.4.1`) | Verified 2026-11-20 (`claude --version`); signing in on the cluster untested |
| `srun ... <command>` runs non-interactively and blocks until done | Verified 2026-11-20 |
| `conda activate <prefix>` works in a batch job after `module load anaconda/3`, without sourcing conda.sh, with or without `set -u` | Verified 2026-11-20 |
| A blocking `srun` on `short-40core-shared` waited 20+ minutes for resources in the afternoon (it started in ~1 s that morning) | Verified 2026-11-20 |
| `miniforge/3` provides conda 26.1.1 and mamba | Verified 2026-11-20 |
| Small `singularity pull` works on the login node | Verified 2026-11-20 (alpine, 6 s) |
| `sbatch` can print "Socket timed out" and still create the job | Reported |
| OnDemand at sn-ood.seawulf.stonybrook.edu (Jupyter on CPU nodes, RStudio, MATLAB, code-server, vLLM/Ollama apps) | Docs |
| NVwulf queues, hardware, defaults (1 CPU per GPU), per-user limits, billing weights (H200 100, Blackwell 50), modules (pytorch, vllm), Lustre paths | Verified 2026-11-20 on login1 (Slurm 23.02) |
| NVwulf: one 20 GB user quota over all of /lustre (home + scratch); over quota puts the account on `reducequotablock-qos` and jobs pend with `QOSMaxJobsPerUserLimit`; `sbatch --test-only` doesn't show it | Verified 2026-11-20 |
| NVwulf debug queues allow 2 h (the docs say 1 h) | Verified with `scontrol` 2026-11-20 |
| `scripts/sw start` (0.4.0 code) opens a session; works against NVwulf with `SW_HOST=nvwulf` | Verified 2026-11-20 |
| Globus via `module load globus/3.15.0` on milan, personal endpoint | Docs |
| The login banner restricts using SBU computing to train AI models for entities headquartered in listed countries | Seen on login 2026-11-20 |
