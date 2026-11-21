# Changelog

## 0.7.0 (2026-11-20)

- The skill is renamed from `seawulf` to `using-seawulf` (folder `skills/using-seawulf/`), so "SeaWulf" always means the cluster. In Claude Code it appears as `seawulf:using-seawulf`. The plugin name and install commands are unchanged.

## 0.6.1 (2026-11-20)

- `cluster-facts.sh` works on both clusters: it detects SeaWulf or NVwulf, lists every queue's load and node states, warns when a blocking QOS is attached, and reads the right quota (`myquota` on SeaWulf, `lfs quota` on NVwulf). Tested on both.
- Fix: `sw` called itself by a relative path (`./sw`), which broke `start` failure handling and `put`/`get` from Git Bash. It now uses its absolute path.
- NVwulf notes: the vllm and pytorch modules work (versions recorded), there's no shared LLM weight cache, and project space is per group.

## 0.6.0 (2026-11-20)

- `references/getting-help.md`: when to contact RCI and how to draft a support ticket (RCI's required details plus job IDs, QOS and quota facts). Claude drafts; the user submits.
- NVwulf verified on the cluster: H200 and Blackwell queues with real limits and defaults (1 CPU per GPU), fair-share costs, ready-made pytorch/vllm modules, Lustre paths, and the main trap: one 20 GB quota over home and scratch that, when exceeded, silently blocks every job (`QOSMaxJobsPerUserLimit`, not caught by `sbatch --test-only`).
- `sw start` verified against NVwulf (`SW_HOST=nvwulf`); the 0.4.0 session code is now tested end to end.
- README and SKILL.md say which GPUs are where: A100 on SeaWulf (older types retired), H200 and Blackwell on NVwulf.

## 0.5.0 (2026-11-20)

- `sw run` stops a command on the cluster after its SECS limit (exit 124), so one slow command (such as an `srun` waiting for a busy queue) can't block every later command in the session.
- `SKILL.md` gains a "Numbers used most" table (queues, default memory, GPU slices, login-node and storage limits, conda in jobs), after Haiku runs showed smaller models don't always open the references.
- GPU template activates the conda env explicitly (`module load anaconda/3`, `conda activate`).
- The four ways to work (laptop session, VPN, Claude Code on SeaWulf, OnDemand shell) are presented as options, not ranked; the skill notices when it is already running on a SeaWulf login node.
- Evals: login-node case tightened, queue-choice case added, Haiku results, and a trigger check (`evals/triggering/`, 20/20).

## 0.4.0 (2026-11-20)

- `sw put` / `sw get`: copy files and folders (up to 50 MB, `SW_MAX_MB`) through the open session. No scp, no extra Duo push; binary-safe, checksums verified both ways.
- The session now notices when ssh has ended (it reports "the session ended" instead of waiting out the timeout), keeps its queue and log private (mode 700/600), and trims them once they pass 20 MB.
- New rule: close the session when the work is done (`sw stop`), as RCI asks users to log out of login nodes.
- CI: shellcheck, script syntax, manifest JSON, relative links, SKILL.md limits and the Claude Code plugin validator on every push.
- Not yet verified on the cluster: starting a session with the new code (needs one Duo push); `run`, `put` and `get` were tested through a session opened by the previous version.

## 0.3.0 (2026-11-20)

- Broadened from connecting to working on SeaWulf: cluster model and safety rules, Slurm (queues and limits, A100 GPUs, arrays, dependencies, failures), software, storage and data, NVwulf (documentation only).
- `scripts/preflight.sh` (local setup check, no Duo) and `scripts/cluster-facts.sh` (current queues, limits, quotas, modules).
- Job templates validated on the cluster; every fact listed with its source and date.
- Five evaluation cases (`evals/`).
- Tested: SSH keys don't skip Duo; login nodes cap users at 3 CPUs / 15 GB; Claude Code is installed on SeaWulf as a module.

## 0.1.0 (2026-11-20)

- First version: one long-lived ssh session per Duo approval (`scripts/sw`).
