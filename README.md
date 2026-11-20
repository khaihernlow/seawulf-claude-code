# seawulf-claude-code

A Claude Code plugin that teaches Claude to work on **Stony Brook University's HPC clusters**: SeaWulf,
plus NVwulf for GPUs. Claude doesn't need to know anything about HPC beforehand, and neither do you.
Install it, and Claude can:

- **connect** through Duo without spamming your phone or locking your account;
- **run jobs:** pick the right queue, write and submit Slurm jobs (CPU, A100 GPU, arrays, dependencies), and work out why one failed or is waiting;
- **set up software:** modules, conda/Python envs in the right place, CUDA/PyTorch/vLLM, containers;
- **handle data:** quotas, the scratch purge, getting code and data on and off the cluster.

Everything is based on SBU Research Computing's documentation and on checks run on the cluster itself. Each
fact is marked with how and when it was verified, and a bundled script lets Claude re-check the live cluster
instead of trusting stale notes.

## Install

In Claude Code:

```
/plugin marketplace add khaihernlow/seawulf-claude-code
/plugin install seawulf@seawulf-claude-code
```

Then just ask, e.g. *"set up a conda env with PyTorch on SeaWulf and run my train.py on an A100"*.

## Connecting without a Duo push per command

SeaWulf asks for Duo at every login, and **10 unanswered requests in a row lock your account**. An assistant
running one `ssh` per command can trigger that quickly. The skill picks the cheapest safe way to connect:

1. **On the SBU VPN**, Duo is approved once when the VPN connects, so plain ssh works.
2. **Otherwise**, it keeps **one** long-lived ssh session open (one Duo approval) and streams every command
   through it (`scripts/sw`). Each command then takes a couple of seconds and costs no push.
3. **No setup at all:** you paste Claude's commands into the Open OnDemand web shell.

You always log in and approve Duo yourself, and Claude never sees or stores your password. One-time setup
(ssh config; on Windows, WSL) is in [connecting](skills/seawulf/references/connecting.md).

## What's inside

| Path | What |
| --- | --- |
| [`skills/seawulf/SKILL.md`](skills/seawulf/SKILL.md) | The overview Claude follows: how the cluster works, the safety rules, and where to look next |
| [`references/connecting.md`](skills/seawulf/references/connecting.md) | Accounts, login hosts, OnDemand, ssh config and keys, Duo and lockouts, Windows/WSL, troubleshooting |
| [`references/slurm.md`](skills/seawulf/references/slurm.md) | Queues and limits, shared vs whole-node, A100 GPUs, batch and interactive jobs, arrays, dependencies, monitoring, failure causes, priority |
| [`references/software.md`](skills/seawulf/references/software.md) | Modules, conda/pip placement, GPU Python, Singularity, Jupyter and other OnDemand apps, building from source |
| [`references/storage-and-data.md`](skills/seawulf/references/storage-and-data.md) | Home, scratch and project space, quotas and purge, every way to move data |
| [`references/nvwulf.md`](skills/seawulf/references/nvwulf.md) | The H200/Blackwell GPU cluster (from documentation; untested) |
| [`references/verified-facts.md`](skills/seawulf/references/verified-facts.md) | Every fact with its source and date |
| [`templates/`](skills/seawulf/templates/) | Job scripts (shared CPU, A100 GPU, array), validated on the cluster |
| [`scripts/sw`](skills/seawulf/scripts/sw) | The one-session runner (macOS, Linux, WSL; forwards from Git Bash on Windows) |
| [`scripts/cluster-facts.sh`](skills/seawulf/scripts/cluster-facts.sh) | Prints current queues, limits, node states, your accounts, quotas, modules and jobs |

## Status

Checked on 2026-11-20 against SeaWulf's milan login node, from Windows 11 with WSL (Ubuntu 24.04), using one
user's account. Not yet tested from macOS or Linux clients, on other accounts, or on NVwulf. Reports and fixes
are welcome: open an issue or PR.

Not affiliated with or endorsed by Stony Brook University or Research Computing & Informatics. Follow SBU's
acceptable-use policies; you are responsible for what runs under your account. For help with the clusters
themselves, see [RCI's documentation](https://rci.stonybrook.edu/hpc/docs).

## License

MIT
