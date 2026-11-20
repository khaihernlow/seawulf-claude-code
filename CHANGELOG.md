# Changelog

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
