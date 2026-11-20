# NVwulf (SBU's GPU cluster)

**Source: RCI documentation only. Not tested by this skill's author.** Confirm on the cluster (`sinfo`,
`scontrol show partition <queue>`) before relying on it.

NVwulf is a separate cluster for GPU and AI work, with its own login, home, storage and accounts. Access is
requested separately ([getting access](https://rci.stonybrook.edu/docs/getting-access-nvwulf)).

- **Login:** `ssh <netid>@login.nvwulf.stonybrook.edu` (Duo, like SeaWulf). Browser: [nvwulf-ood.nvwulf.stonybrook.edu](https://nvwulf-ood.nvwulf.stonybrook.edu).
- **Separate home:** copy your ssh public key there too. Copy data from SeaWulf by running `rsync` on NVwulf.
- **Slurm:** `module load slurm`. Software via `module avail` / `module load`.
- **Rebuild** compiled code on NVwulf rather than reusing SeaWulf builds.

Queues ([NVwulf queues](https://rci.stonybrook.edu/docs/nvwulf-queues)):

| Queue | GPUs per node | CPUs | Host RAM | Max time | Max nodes |
| --- | --- | --- | --- | --- | --- |
| `debug-h200x4` | 4 x H200 NVL 141 GB | 64 (62 usable) | ~750 GB | 1 h | 1 |
| `debug-b40x4` | 4 x RTX PRO 6000 Blackwell 96 GB | 64 (62) | ~512 GB | 1 h | 1 |
| `h200x4` / `h200x4-long` | 4 x H200 NVL | 64 (62) | ~750 GB | 8 h / 48 h | 2 / 1 |
| `h200x8` / `h200x8-long` | 8 x H200 NVL | 64 (62) | ~1,500 GB | 8 h / 48 h | 1 |
| `b40x4` / `b40x4-long` | 4 x RTX PRO 6000 Blackwell | 64 (62) | ~512 GB | 8 h / 48 h | 2 / 1 |

Priority queues (`p-...`) need a dedicated allocation. Memory is shared per GPU (on a B40 node, about 125 GB per GPU). Slurm assigns default CPUs and memory from the GPUs requested; see `scontrol show partition <queue>`. Test in a `debug-` queue first, request only the GPUs you'll use, and `exit` interactive sessions promptly.

A minimal GPU job, following RCI's example:

```
#!/bin/bash
#SBATCH --job-name=test-gpu
#SBATCH --partition=h200x4
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --mem=25G
#SBATCH --gres=gpu:1
#SBATCH --time=00:05:00
module load slurm
nvidia-smi
python train.py
```
