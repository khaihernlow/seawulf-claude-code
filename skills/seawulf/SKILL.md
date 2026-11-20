---
name: seawulf
description: Works on Stony Brook University's HPC clusters (SeaWulf, and NVwulf for large GPU work) from Claude Code. Connects through Duo without locking the account, picks queues, writes and submits Slurm jobs (CPU, A100 GPU, arrays), diagnoses failed or stuck jobs, sets up conda/Python envs and modules in the right places, and handles storage, quotas and data transfer. Use whenever the user mentions SeaWulf, NVwulf, SBU or Stony Brook HPC, "the cluster", milan, Slurm/sbatch/squeue on SBU systems, or wants to run code, training or models on university GPUs or compute, even without HPC vocabulary.
---

# Stony Brook HPC (SeaWulf / NVwulf)

SeaWulf is SBU's main cluster:
- a shared login node, `milan.seawulf.stonybrook.edu`, for editing, installing and submitting;
- compute nodes run by Slurm, which RCI and this skill call **queues** (Slurm's "partitions");
- storage: home is small (20 GB, backed up), scratch is big but purged (20 TB, files untouched for 45 days are deleted), and groups can get project space.

NVwulf is a separate GPU cluster (H200 / Blackwell). Many users are new to HPC: explain each choice in a plain sentence ("a shared queue, since you need 4 cores; it starts sooner than a whole node").

## Rules that protect the user

1. **Every new ssh connection asks for Duo, even with SSH keys**, and **10 unanswered requests in a row lock the account.** So never loop or retry a connection. A command that fails after ~60 s with no output was probably an unanswered push: stop and tell the user.
2. **Say before anything that sends a push**, so the user can approve it.
3. **Never ask for, type, store or log the password**, and never try to answer Duo.
4. **Login nodes:** each user is capped at **3 CPUs and 15 GB**. Editing, `git`, small installs and submitting are fine. Training, loading a model "to test it", big compiles or long loops go in a job.
5. **Never put envs or installed software in scratch** (the purge breaks them). Copy results worth keeping out of scratch.
6. **`sbatch` and other run-once actions never run twice.** After an unclear failure, check `squeue --me` first.
7. **Poll gently.** Wait inside one remote command, e.g. `while squeue -h -j $ID | grep -q .; do sleep 30; done`, not with repeated calls.
8. **Confirm before destructive actions:** `scancel` (only jobs started for this task), bulk `rm`, overwriting results.

## 1. Preflight and connect

Run `scripts/preflight.sh` locally first. It reports what's set up (ssh entry, WSL on Windows, an open session) and what the user must do next. Then use the first option that fits:

| Situation | How to run commands |
| --- | --- |
| The user is on the **SBU VPN** (Duo once at VPN connect) | Plain `ssh seawulf '<command>'` |
| Usual case (Windows needs WSL) | **One long-lived session:** the user logs in once in their terminal; Claude runs `scripts/sw start` (one push), then `scripts/sw run` for everything (no more pushes) |
| The user prefers Claude running **on the cluster** | `module load claude-code` there (installed by RCI); the user signs in once with `claude auth login` |
| Nothing set up | The user pastes one-line commands into the Open OnDemand shell ([sn-ood.seawulf.stonybrook.edu](https://sn-ood.seawulf.stonybrook.edu)) and the output back |

```bash
SW=<this skill's directory>/scripts/sw
"$SW" status
"$SW" start                 # sends ONE Duo push: tell the user first
"$SW" run 600 <<'EOF'       # runs as its own login-shell bash on the login node; exit status is the script's
squeue --me
EOF
```

`run` exit 124 means the script is still running on the cluster after the wait: check later, don't rerun. Setup details, keys, Windows and troubleshooting: [references/connecting.md](references/connecting.md).

## 2. Get current facts

Once connected, run `"$SW" run 300 < scripts/cluster-facts.sh`. It prints the queues and limits, down or draining nodes, the user's Slurm accounts, quotas, project space, key modules and current jobs. Prefer it over remembered numbers: the cluster changes.

## 3. Do the work

| Task | Read |
| --- | --- |
| Choosing a queue, batch or interactive jobs, GPUs, arrays, dependencies, monitoring, failed or waiting jobs | [references/slurm.md](references/slurm.md), with job templates in [templates/](templates/) |
| Modules, conda/pip, CUDA/PyTorch/vLLM, containers, Jupyter | [references/software.md](references/software.md) |
| Where files go, quotas, moving data | [references/storage-and-data.md](references/storage-and-data.md) |
| H200/Blackwell GPUs | [references/nvwulf.md](references/nvwulf.md) (from documentation, untested) |
| Whether a fact is current, and its source | [references/verified-facts.md](references/verified-facts.md) |

A first job, done well:

```
- [ ] Code on the cluster via git (clone into /gpfs/scratch/$USER/<project>)
- [ ] Env outside scratch (home, or project space if big); caches in scratch
- [ ] Copy a template, fill it in: -shared queue + --mem for small jobs, or a100 + --gres=gpu:1
- [ ] sbatch --test-only, then sbatch --parsable; note the job id
- [ ] Wait inside one remote command; read the .out/.err file and sacct -j <id>
- [ ] If it failed: slurm.md section 9, fix, resubmit
- [ ] Copy results worth keeping out of scratch
```
