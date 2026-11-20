# Running jobs with Slurm on SeaWulf

## Contents
1. The model
2. Choosing a queue
3. Shared vs whole-node queues, and memory
4. GPUs (A100)
5. Batch jobs (templates)
6. Interactive jobs
7. Arrays and dependencies
8. Watching and accounting
9. Why did my job fail?
10. Priority and waiting
11. Limits

## 1. The model

Login nodes are for editing, files, building, and submitting. Everything heavy runs on compute nodes through Slurm, either as a **batch job** (`sbatch script`, which runs unattended) or an **interactive job** (`srun ... --pty bash`, a shell on a compute node). A job asks for a queue (`-p`), a size (cores, memory, GPUs) and a time limit. It waits in the queue until those resources are free, and is killed when its time limit ends.

Slurm commands need `module load slurm` if `sbatch`/`squeue` aren't found. A login shell (`bash -l`) usually has them.

## 2. Choosing a queue

RCI's rule: **the smallest, shortest queue that fits starts soonest.** Live limits, as checked on 2026-11-20 with `scontrol show partition`:

| Queue | Max time | Nodes per job | Node type | Use for |
| --- | --- | --- | --- | --- |
| `debug-40core` | 1 h | 1–6 | 40-core, 192 GB | Quick tests (1 job at a time) |
| `short-40core-shared` / `short-96core-shared` | 4 h | ≤ 8 | shared | **A few cores**: most small jobs |
| `short-40core` / `short-96core` | 4 h | ≤ 8 | whole nodes | Whole-node jobs up to 4 h |
| `medium-40core` / `medium-96core` | 12 h | 6–16 | whole nodes | Multi-node, ≤ 12 h |
| `long-40core(-shared)` / `long-96core(-shared)` | 2 days | ≤ 6 | | Long single or few-node jobs |
| `extended-40core(-shared)` / `extended-96core(-shared)` | 7 days | ≤ 2 | | Very long jobs |
| `large-40core` / `large-96core` | 8 h | 16–50 / 16–38 | whole nodes | Big MPI jobs |
| `hbm-*-96core` | 4 h – 7 days | varies | 96-core Sapphire Rapids, 384 GB (128 GB HBM) | Memory-bandwidth-bound codes |
| `hbm-1tb-long-96core` | 2 days | 1 | 1 TB RAM | Huge memory |
| `a100` / `a100-long` / `a100-large` | 8 h / 2 days / 8 h | ≤ 2 / 1 / ≤ 4 | 4 x A100 80GB, 64 cores, 256 GB | GPUs |

Node types: `dn*` are 40-core Skylake with 192 GB; `dg*` are 96-core AMD Milan with 256 GB. `large-*` and `medium-*` have *minimum* node counts (16 and 6); a 1-node job there is rejected.

Check what's busy before choosing: `sinfo -p <queue>`, and `sinfo -p a100 -N -o "%N %T %E"` for node states and reasons.

## 3. Shared vs whole-node queues, and memory

- **`-shared` queues** (and all A100 queues) give part of a node and share the rest. **Always set `--mem`** there. The default is only ~2.4 GB per core on the CPU-shared queues and ~4 GB per core on A100.
- **Queues without `-shared`** give whole nodes exclusively, with all their memory. A 1-core job there wastes a whole node and waits longer.
- `--mem` is per node; `--mem-per-cpu` is per core. Asking for more than a node has fails with `Requested node configuration is not available`.

## 4. GPUs (A100)

- 11 nodes (`a100-01`…`a100-11`), each with 4 x A100 80GB, 64 cores and ~256 GB. The three a100 queues use the **same** nodes.
- Request GPUs with `--gres=gpu:N` (N = 1–4 per node), plus a proportional slice of the node, about 16 cores and ~60 GB per GPU. Without `--mem` you get the small per-core default.
- Per-user caps (QOS): `a100` 2 running jobs; `a100-long` 2; `a100-large` 1.
- Put `nvidia-smi` at the top of GPU jobs; it proves the job got a GPU.
- **CUDA:** modules exist from `cuda80` to `cuda130`/`cuda133` (e.g. `cuda120/toolkit/12.0`). Pip-installed PyTorch, vLLM and similar bring their own CUDA runtime and only need the driver, so load a CUDA module only to compile CUDA code.
- For large AI work (H200, Blackwell), RCI points to **NVwulf**, a separate cluster: see [nvwulf.md](nvwulf.md).

## 5. Batch jobs

Templates in [`../templates/`](../templates/), all validated with `sbatch --test-only` on 2026-11-20:

| Template | For |
| --- | --- |
| `cpu-shared.sbatch` | A few cores on a shared node: the right default for small jobs |
| `gpu-a100.sbatch` | One A100 with a proportional CPU and memory slice |
| `array.sbatch` | A parameter sweep: one task per input, with a cap on how many run at once |

Habits that prevent most problems:
- `set -euo pipefail` and `module purge` at the top, then load exactly what's needed **inside** the script; jobs don't inherit a sensible environment. Activate conda envs inside the script too.
- `cd "$SLURM_SUBMIT_DIR"`, or use absolute paths.
- Name output files with `%x-%j` (job name and id) or `%A_%a` (array id and task).
- **Check before submitting**: `sbatch --test-only script` validates the request and prints an estimated start, without submitting anything.
- **Submit idempotently.** Give the job a name, and check `squeue --me -n NAME` before `sbatch`. `sbatch` has been reported to print `Socket timed out` and still create the job, so look at the queue before ever resubmitting.
- Write scripts with Unix line endings. A Windows-edited script fails with `^M` errors; fix it with `sed -i 's/\r$//' script`.

## 6. Interactive jobs

```
srun -p short-40core-shared -n 4 --mem=16G --time=01:00:00 --pty bash     # a few cores
srun -p debug-40core --time=00:30:00 --pty bash                             # quick test node
srun -p a100 --gres=gpu:1 -c 8 --mem=60G --time=01:00:00 --pty bash         # one GPU
```

`--pty bash` goes last. `exit` releases the node; always exit when done. The session dies if the connection drops, so long work belongs in a batch job. If it hangs without "job has been allocated resources", the queue is busy: ask for less, or use a shared queue.

**Claude can't drive an interactive `srun` shell through a non-interactive connection.** For Claude's own work, prefer batch jobs, or `srun` with a command instead of a shell: `srun -p short-40core-shared -n 1 --mem=4G -t 10 python check.py`. That blocks until done (on an idle shared queue it took ~1.5 s end to end on 2026-11-20), so keep it short. It's handy for quick checks on a compute node, like testing an import or network access.

## 7. Arrays and dependencies

- Arrays: `--array=0-99` (max size here 1001), `%N` caps how many run at once (`--array=0-99%10`), and `$SLURM_ARRAY_TASK_ID` picks the input. Prefer one array over hundreds of separate `sbatch` calls; the per-user queue limit is ~100 submitted jobs.
- Dependencies: `jid=$(sbatch --parsable step1.sbatch)` then `sbatch --dependency=afterok:$jid step2.sbatch`. Also `afterany` (regardless of outcome), `afternotok` (on failure) and `after` (once it starts). A dependency that can never be met shows `DependencyNeverSatisfied`; `scancel` it.

## 8. Watching and accounting

```
squeue --me                                  # your jobs (ST: PD pending, R running, CG completing)
squeue --me --start                          # scheduler's start estimates (often pessimistic)
scontrol show job <id>                       # everything about one job, including Reason
sacct -j <id> --format=JobID,JobName,State,ExitCode,Elapsed,Timelimit,MaxRSS
seff <id>                                    # CPU and memory efficiency after it ends
scancel <id>                                 # or: scancel --me -n NAME
```

To wait for a job from a script, loop inside **one** remote command (e.g. `while squeue -h -j $id | grep -q .; do sleep 30; done`) rather than calling in again and again.

## 9. Why did my job fail?

| `sacct` State / ExitCode | Meaning | Fix |
| --- | --- | --- |
| `FAILED 1:0` | Program error | Read the end of the `.out`/`.err` file. `ModuleNotFoundError`: load modules and activate the env inside the script |
| `FAILED 2:0` | Bad arguments, missing file, syntax | Run the command by hand in an interactive job |
| `127` / `126` | Command not found / not executable | Module not loaded, typo, Windows line endings (`^M`), `chmod +x` |
| `OUT_OF_MEMORY`, `0:9`, "oom-kill" | Exceeded `--mem` | `seff <id>`, then request the peak plus ~20% |
| `TIMEOUT` | Hit the time limit | Longer `--time`, a longer queue, or checkpointing |
| `CANCELLED`, `0:15` | `scancel`, or stopped by Slurm | Check whether it was the time limit |
| `NODE_FAIL` | Hardware or system fault | Resubmit; report repeat offenders with job IDs |
| "CUDA out of memory" | GPU memory full | Smaller batch or model, mixed precision, more GPUs |
| "no CUDA-capable device" | No GPU requested | `--gres=gpu:1`; check with `nvidia-smi` |
| Segfault (signal 11) | Mixed toolchains, or code built elsewhere | `module purge`, load only what's needed, rebuild on milan |
| Disk quota exceeded / no space left | Home (20 GB) or scratch quota | `myquota`; move work to scratch, envs out of home caches |

Source: [why did my job fail](https://rci.stonybrook.edu/docs/job-failures).

## 10. Priority and waiting

- Scheduling is multifactor priority (fair-share plus age) with **backfill**: short, small jobs can start in gaps ahead of big ones. Asking for less time helps.
- `PD (Priority)` means others are ahead. `PD (Resources)` means you're next. `QOSMaxJobsPerUserLimit` means you're at your per-user cap.
- Nodes in state `draining` or `drained` ("Reboot ASAP", maintenance) take no new jobs. Check `sinfo -N -p <queue>` before blaming the job; on 2026-11-20, 7 of the 11 A100 nodes were draining and GPU waits were days.

## 11. Limits (2026-11-20, `sacctmgr show qos`)

- Running jobs per user: `short-*` 4, `long-*` 3, `extended-*` 3, `medium-*` 1, `large-*` 1, `debug-40core` 1, `a100` 2, `a100-long` 2, `a100-large` 1.
- Shared queues cap total resources per user instead. For example, `short-40core-shared`: 320 cores, 322 GB, 8 nodes.
- About 100 queued (submitted) jobs per user per queue; RCI says up to 32 nodes in use at once outside `large` queues.
- Re-check with `sacctmgr show qos format=Name%30,MaxWall,MaxJobsPU,MaxSubmitPU,MaxTRESPU%40`, or `scripts/cluster-facts.sh`.
