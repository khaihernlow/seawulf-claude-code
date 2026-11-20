---
name: seawulf
description: Work on Stony Brook University's HPC clusters (SeaWulf, and NVwulf for GPUs) from Claude Code: connecting through Duo without locking the user out, submitting and debugging Slurm jobs, choosing queues, using A100 GPUs, setting up conda/Python and modules, storage and quotas, moving data. Use this whenever the user mentions SeaWulf, NVwulf, SBU or Stony Brook HPC, "the cluster", milan, sbatch/squeue/Slurm on SBU systems, or wants to run code, training or models on university GPUs or compute, even if they don't know HPC terms.
---

# Stony Brook HPC (SeaWulf / NVwulf)

Use this to take someone from "I have access to the university cluster" to working jobs. It assumes no prior HPC knowledge on either side, and explains things to the user in plain words as you go.

## The mental model

- **SeaWulf** is a shared cluster: hundreds of compute nodes run by Slurm, a queueing system. You `ssh` to a **login node** (`milan.seawulf.stonybrook.edu`), which is shared by everyone and is only for editing, files, installing and **submitting jobs**. Real work runs on compute nodes as **jobs**: a script that asks for cores, memory, GPUs and a time limit, waits in a queue, runs, and writes output files.
- **Storage:**
  - home is small and backed up (20 GB);
  - scratch is large and temporary (20 TB, files untouched for 45 days are deleted);
  - groups can get project space.
- **Every login needs Duo** (a phone approval). After **10 unanswered Duo requests in a row, the account is locked.**
- **NVwulf** is a separate, newer GPU cluster (H200 / Blackwell) with its own login and storage.

## Rules that protect the user

1. **Never loop or retry connections.** Each new ssh session can send a Duo push, and unanswered pushes lock the account. If a command fails after about 60 seconds with no output, a push probably went unanswered: stop and tell the user.
2. **Ask before anything that sends a push**, and say it's coming, so they can approve it.
3. **Never ask for, type, store or log the user's password**, and never try to answer Duo. The user authenticates; Claude works through what they opened.
4. **Nothing heavy on login nodes.** Each user is capped there at **3 CPUs and 15 GB of memory** (enforced by the system), shared by everyone's work. Builds, small installs, `git` and quick checks are fine. Anything long, multi-core or memory-hungry (training, loading a model to try it, big compiles) goes in a job.
5. **Never put environments or installed software in scratch** (the purge breaks them), and copy results worth keeping out of scratch.
6. **Don't run anything twice that must run once** (above all `sbatch`). After an unclear failure, check the queue before resubmitting.
7. **Only cancel jobs you started for this task, with the user's OK.**

## Step 1: Connect

Read [references/connecting.md](references/connecting.md) the first time. In short, ask the user which of these applies:

| Situation | How Claude runs commands |
| --- | --- |
| On the **SBU VPN** (Duo once at VPN connect), or ssh connection reuse confirmed to not push per command | Plain `ssh seawulf '<command>'` |
| Otherwise (the usual case; Windows needs WSL) | One long-lived session with **`scripts/sw`**: one Duo push, then no more. The user logs in once in their own terminal, then Claude runs `scripts/sw start` and approves nothing further |
| The user would rather run Claude **on the cluster** | SeaWulf has Claude Code installed (`module load claude-code`). The user logs in (one Duo push) and runs `claude` on the login node, where commands are local, with the 3-CPU / 15 GB login limits. See connecting.md section 6 |
| No ssh setup at all | The user runs Claude's one-line commands in the Open OnDemand shell ([sn-ood.seawulf.stonybrook.edu](https://sn-ood.seawulf.stonybrook.edu)) and pastes the output back |

With `scripts/sw`:

```bash
SW=<this skill's directory>/scripts/sw
"$SW" status                       # open?
"$SW" start                        # ONE Duo push: tell the user first
"$SW" run 600 <<'EOF'              # each script runs as its own login-shell bash on the login node
squeue --me
EOF
```

`run` returns the script's exit status. 124 means it's still running on the cluster after the wait (don't rerun it; check later). Each call takes about 2 seconds and costs no push.

## Step 2: Get your bearings

First thing in a new session, run [`scripts/cluster-facts.sh`](scripts/cluster-facts.sh) on the cluster (`"$SW" run 300 < scripts/cluster-facts.sh`). It prints:
- queues and limits;
- which nodes are down;
- the user's Slurm accounts, quotas and project space;
- key modules;
- their current jobs.

Trust it over any notes here: clusters change.

## Step 3: Do the work

| The user wants to… | Read |
| --- | --- |
| Run something: batch or interactive job, GPU, array, dependencies, pick a queue, debug a failed or stuck job | [references/slurm.md](references/slurm.md), with templates in [`templates/`](templates/) |
| Install Python packages or conda envs, use modules, CUDA/PyTorch/vLLM, containers, Jupyter | [references/software.md](references/software.md) |
| Know where to put files, quotas, move data in or out | [references/storage-and-data.md](references/storage-and-data.md) |
| Use H100/H200-class GPUs, or large AI work | [references/nvwulf.md](references/nvwulf.md) (documentation-based, untested) |
| Check whether a fact is current | [references/verified-facts.md](references/verified-facts.md) (what was checked, how, and when) |

A typical first job, done well:
1. Put the code on the cluster with git (`git clone` in scratch).
2. Copy a template from `templates/` and fill it in. Use a `-shared` queue with `--mem` for small jobs, or `a100` with `--gres=gpu:1` for GPU.
3. Run `sbatch --test-only` to check the request, then `sbatch --parsable` to submit, and record the job ID.
4. Wait inside **one** remote command (a loop on `squeue -j`), not by calling in repeatedly. Then read the `.out`/`.err` files and `sacct -j <id>`.
5. If it failed, check the table in slurm.md section 9, fix, and resubmit.
6. Copy results worth keeping out of scratch.

## Explaining to the user

Many users are new to HPC. When you choose a queue, size or location, say why in a sentence. For example: "a shared queue, since you only need 4 cores; it starts sooner than a whole node." When jobs wait, show them the real reason from `squeue`/`sinfo` (queue full, nodes rebooting, per-user limit) instead of guessing.
