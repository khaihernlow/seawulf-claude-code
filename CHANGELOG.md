# Changelog

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
