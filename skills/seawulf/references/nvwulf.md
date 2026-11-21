# NVwulf (SBU's GPU cluster)

Checked on the cluster on 2026-11-20 (`login1`, Slurm 23.02) unless marked "docs". Re-check with `sinfo`,
`scontrol show partition <queue>` and `sacctmgr show assoc user=$USER`. NVwulf changes as SeaWulf does.

NVwulf is a separate cluster for GPU and AI work, with its own login, home, storage, Slurm accounts and quota.

## Access and connecting

- **Accounts (docs):** students and staff join an existing project, and **a SeaWulf project counts**. Open a ticket at iacs.supportsystem.com with the help topic "Request an Account for NVwulf", giving NetID, PI and project number. New projects are faculty-only (a one-page PDF to a review committee). The Slurm account name differs from SeaWulf's (here `pn_..._n` vs `pn_..._s`).
- **Login:** `ssh <netid>@login.nvwulf.stonybrook.edu`. Duo applies per connection, as on SeaWulf, so the same ways to connect work, including `scripts/sw` with `SW_HOST=nvwulf` and a separate `SW_STATE` (verified). Browser: nvwulf-ood.nvwulf.stonybrook.edu (docs).
- **Separate home:** copy your ssh public key there too. Pull data from SeaWulf by running `rsync` on NVwulf.
- **Login node:** the same per-user cap as SeaWulf, 3 CPUs and 15 GB.

## Storage and the quota that blocks jobs

| Path | Notes |
| --- | --- |
| `/lustre/nvwulf/home/<netid>` | Home |
| `/lustre/nvwulf/scratch/<netid>` | Scratch |
| `/lustre/nvwulf/projects/<group>` | Group project space |
| `/lustre/nvwulf/software` | System software |

- **One 20 GB user quota covers everything you own on `/lustre`, home and scratch together.** There are no separate project quotas on home or scratch (`lfs project -d` shows 0), so moving files between them doesn't free quota. Check with **`lfs quota -h -u $USER /lustre`**; there is no `myquota` on NVwulf. A `*` after "used" means over quota.
- **Over quota means jobs stop running.** The account is switched to a QOS named `reducequotablock-qos` (max running jobs 0), and every job waits with reason **`QOSMaxJobsPerUserLimit`**. `sbatch --test-only` does *not* catch this, so it looks fine. Seen on 2026-11-20 with 27.4 GB used of 20 GB. Check `sacctmgr -n -P show assoc user=$USER format=Account,QOS`; a `reducequotablock` QOS means delete files to get under quota (or ask RCI). If jobs pend with `QOSMaxJobsPerUserLimit` while you have nothing running, check the quota first.
- Keep big datasets and model weights in project space, not home or scratch.

## Queues

| Queue | GPUs per node | Nodes | Max time | Max nodes/job | Per user (running / queued) | Default per GPU |
| --- | --- | --- | --- | --- | --- | --- |
| `debug-b40x4` | 4 × RTX PRO 6000 Blackwell (96 GB) | 12 | 2 h | 1 | 1 / 100 | 1 CPU, 7.9 GB |
| `b40x4` | same | 12 | 8 h | 2 | 3 / 100 | 1 CPU, 7.9 GB |
| `b40x4-long` | same | 12 | 2 days | 1 | 2 / 100 | 1 CPU, 11 GB |
| `debug-h200x4` | 4 × H200 (141 GB) | 4 | 2 h | 1 | 1 / 100 | 1 CPU, 11 GB |
| `h200x4` / `h200x4-long` | same | 4 | 8 h / 2 days | 2 / 1 | 3 / 100, 2 / 100 | 1 CPU, 11 GB |
| `h200x8` / `h200x8-long` | 8 × H200 | 4 | 8 h / 2 days | 1 | 2 / **2**, 1 / **2** | 1 CPU, 23 GB |

- Nodes have 64 cores, of which 62 are usable for jobs. Blackwell nodes have ~512 GB of RAM; H200x4 ~770 GB; H200x8 ~1.4 TB.
- The docs list a 1 h limit for the debug queues; `scontrol` shows **2 h**, and debug jobs get a big priority boost (PriorityJobFactor 1000).
- **The default is 1 CPU per GPU.** Ask explicitly for CPUs (`-c` or `--cpus-per-gpu`) and `--mem` sized to the work; data loading needs more than one core.
- **Fair-share cost:** usage is billed at 100 per H200 GPU, 50 per Blackwell GPU and 1 per CPU. A Blackwell GPU uses up your priority half as fast, so use it unless you need H200 memory or speed.
- Priority queues (`p-…`) need a dedicated allocation.
- **Load on 2026-11-20 evening:** H200 queues were heavily oversubscribed (h200x4: 3 running, 108 waiting). Blackwell was moderate (b40x4: 7 running, 28 waiting), and the debug queues were empty. Check before choosing: `squeue -h -p <queue> -t PD | wc -l`.
- GPUs are requested with `--gres=gpu:N`; the GPU type is set by the queue.

## Software

- Environment Modules 4.5, as on SeaWulf, but a different set. Notable:
  - **ready-made `pytorch/2.7.1` and `2.9.1`, `tensorflow/2.19.0`, `vllm/0.11.2` and `0.13.0`**;
  - `cuda12.8`, `nccl`, gcc 11 to 15, openmpi;
  - `claude-code/latest`.
- `singularity` (SingularityCE 4.5.1); no `apptainer`.
- The login node reaches GitHub, Hugging Face and PyPI.
- Rebuild compiled code on NVwulf rather than reusing SeaWulf builds.

## A first GPU job

```
#!/bin/bash
#SBATCH --job-name=gpu-test
#SBATCH --partition=debug-b40x4        # empty, high priority, 2 h; move to b40x4 / h200x4 for real runs
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8              # the default is 1 CPU per GPU
#SBATCH --mem=64G
#SBATCH --time=00:30:00
#SBATCH --output=%x-%j.out
set -euo pipefail
module load pytorch/2.9.1              # or your own env
nvidia-smi
python -c "import torch; print(torch.cuda.get_device_name(0))"
```
