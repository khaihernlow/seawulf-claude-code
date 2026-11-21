---
name: using-seawulf
description: Works on Stony Brook University's HPC clusters (SeaWulf, and NVwulf for large GPU work) from Claude Code. Connects through Duo without locking the account, picks queues, writes and submits Slurm jobs (CPU, A100 GPU, arrays), diagnoses failed or stuck jobs, sets up conda/Python envs and modules in the right places, and handles storage, quotas and data transfer. Use whenever the user mentions SeaWulf, NVwulf, SBU or Stony Brook HPC, "the cluster", milan, Slurm/sbatch/squeue on SBU systems, or wants to run code, training or models on university GPUs or compute, even without HPC vocabulary.
---

# Stony Brook HPC (SeaWulf / NVwulf)

SeaWulf is SBU's main cluster:
- a shared login node, `milan.seawulf.stonybrook.edu`, for editing, installing and submitting;
- compute nodes run by Slurm, which RCI and this skill call **queues** (Slurm's "partitions");
- storage: home is small (20 GB, backed up), scratch is big but purged (20 TB, files untouched for 45 days are deleted), and groups can get project space.

NVwulf is a separate GPU cluster (H200 / Blackwell). Many users are new to HPC: explain each choice in a plain sentence ("a shared queue, since you need 4 cores; it starts sooner than a whole node").

## Numbers used most (details and sources in the references)

| | |
| --- | --- |
| Small CPU jobs | `short-40core-shared` / `short-96core-shared`: up to 4 h, part of a node. **Set `--mem`**: the default is only ~2.4 GB per core |
| Whole nodes | `short-*` 4 h · `medium-*` 12 h (6+ nodes) · `long-*` 2 days · `extended-*` 7 days. 40-core nodes 192 GB, 96-core nodes 256 GB |
| SeaWulf GPUs (A100 only; older types retired) | `a100` (8 h) / `a100-long` (2 days): `--gres=gpu:N`, N ≤ 4. Per GPU ask ≤ 16 cores and ~60 GB `--mem` (default ~4 GB per core). 2 running jobs per user |
| NVwulf GPUs | `debug-b40x4` (2 h, usually free) · `b40x4` Blackwell 96 GB · `h200x4` / `h200x8` H200 141 GB (busy). Default **1 CPU per GPU**: set `-c` and `--mem`. **Over its 20 GB quota (home + scratch together), every job pends with `QOSMaxJobsPerUserLimit`**: check `lfs quota -h -u $USER /lustre` |
| Login node | 3 CPUs and 15 GB per user (both clusters) |
| Storage | home 20 GB (backed up) · scratch 20 TB, purged after 45 days · project space up to 10 TB (PI requests) |
| Conda in a job | `module load anaconda/3` then `conda activate /path/to/env`, inside the script. This works in batch jobs (verified). Don't swap it for a `PATH` hack: activation also sets library paths that packages like CUDA libraries rely on |

## Rules that protect the user

1. **Every new ssh connection asks for Duo, even with SSH keys**, and **10 unanswered requests in a row lock the account.** So never loop or retry a connection. A command that fails after ~60 s with no output was probably an unanswered push: stop and tell the user.
2. **Say before anything that sends a push**, so the user can approve it.
3. **Never ask for, type, store or log the password**, and never try to answer Duo. **Never submit RCI tickets or log in to the helpdesk**: draft them for the user to send.
4. **Login nodes:** each user is capped at **3 CPUs and 15 GB**. Editing, `git`, small installs and submitting are fine. Training, loading a model "to test it", big compiles or long loops go in a job.
5. **Never put envs or installed software in scratch** (the purge breaks them). Copy results worth keeping out of scratch.
6. **`sbatch` and other run-once actions never run twice.** After an unclear failure, check `squeue --me` first.
7. **Poll gently.** Wait inside one remote command, e.g. `while squeue -h -j $ID | grep -q .; do sleep 30; done`, not with repeated calls.
8. **Confirm before destructive actions:** `scancel` (only jobs started for this task), bulk `rm`, overwriting results.
9. **Close the session when the work is done** (`sw stop`). RCI asks users to log out and not leave idle programs on login nodes. Submitted jobs keep running without it.

## 1. Find out how this user works

**Already on SeaWulf?** If `hostname` is a SeaWulf login node (`milan1`/`milan2`/`xeonmax`), Claude is running on the cluster (Claude Code module): commands are local. Skip to step 2. The login-node limits apply to Claude itself too.

Otherwise, ask which way suits the user; none is best for everyone:

| Way | How Claude runs commands | Suits |
| --- | --- | --- |
| **One session from the laptop** | The user logs in once in their own terminal; Claude runs `scripts/sw start` (one push), then `sw run`/`put`/`get` with no more pushes | Code and tools on the laptop; Windows needs WSL |
| **SBU VPN** | Duo was approved at VPN connect: plain `ssh seawulf '<command>'` | Users on the VPN anyway |
| **Claude Code on SeaWulf** | The user runs `module load claude-code` (in `tmux`) and `claude auth login` there, and installs this plugin there | Work that lives only on the cluster |
| **Open OnDemand shell** | The user pastes one-line commands into [sn-ood.seawulf.stonybrook.edu](https://sn-ood.seawulf.stonybrook.edu) and the output back | No setup possible |

For the laptop ways, run `scripts/preflight.sh` first. It checks the ssh entry, WSL and an open session without connecting, and says what the user must do next.

```bash
SW=<this skill's directory>/scripts/sw
"$SW" status
"$SW" start                 # sends ONE Duo push: tell the user first
"$SW" run 600 <<'EOF'       # runs as its own login-shell bash on the login node; exit status is the script's
squeue --me
EOF
"$SW" put ./my-project /gpfs/scratch/$NETID/   # files or folders, up to 50 MB, no extra push
"$SW" get /gpfs/scratch/$NETID/run1/results ./  # and back
"$SW" stop                  # when done
```

The session runs one command at a time, and `sw run` stops a command on the cluster after SECS (exit 124), so nothing blocks the session for long. So keep `sw run` for quick work: long installs, training and anything waiting on the queue go in `sbatch` (or a blocking `srun` given a short SECS). Exit 3 means the session ended: ask before starting another. Setup details, keys, Windows and troubleshooting: [references/connecting.md](references/connecting.md).

## 2. Get current facts

Once connected, run `"$SW" run 300 < scripts/cluster-facts.sh`. It prints the queues and limits, down or draining nodes, the user's Slurm accounts, quotas, project space, key modules and current jobs. Prefer it over remembered numbers: the cluster changes.

## 3. Do the work

| Task | Read |
| --- | --- |
| Choosing a queue, batch or interactive jobs, GPUs, arrays, dependencies, monitoring, failed or waiting jobs | [references/slurm.md](references/slurm.md), with job templates in [templates/](templates/) |
| Modules, conda/pip, CUDA/PyTorch/vLLM, containers, Jupyter | [references/software.md](references/software.md) |
| Where files go, quotas, moving data | [references/storage-and-data.md](references/storage-and-data.md) |
| H200/Blackwell GPUs on NVwulf, including its quota that silently blocks jobs | [references/nvwulf.md](references/nvwulf.md) |
| Something only RCI can fix (a block, access, storage, repeated failures): draft a ticket for the user to send | [references/getting-help.md](references/getting-help.md) |
| Whether a fact is current, and its source | [references/verified-facts.md](references/verified-facts.md) |

A first job, done well:

```
- [ ] Code on the cluster via git (clone into /gpfs/scratch/$USER/<project>), or `sw put` for a folder with no remote
- [ ] Env outside scratch (home, or project space if big); caches in scratch
- [ ] Copy a template, fill it in: -shared queue + --mem for small jobs, or a100 + --gres=gpu:1
- [ ] sbatch --test-only, then sbatch --parsable; note the job id
- [ ] Wait inside one remote command; read the .out/.err file and sacct -j <id>
- [ ] If it failed: slurm.md section 9, fix, resubmit
- [ ] Copy results worth keeping out of scratch (`sw get` for small ones)
- [ ] `sw stop`
```
