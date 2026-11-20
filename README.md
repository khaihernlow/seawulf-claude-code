# seawulf-claude-code

[![Release](https://img.shields.io/github/v/release/khaihernlow/seawulf-claude-code)](https://github.com/khaihernlow/seawulf-claude-code/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

A Claude Code plugin that lets Claude work on **Stony Brook University's HPC clusters**: SeaWulf, plus
NVwulf for large GPU jobs. You don't need to know HPC, and Claude doesn't need to be told how the cluster
works. Install it and ask.

- **Connects safely.** SeaWulf asks for Duo on *every* new ssh connection, and 10 unanswered pushes lock your account. Claude uses one session per approval and never retries blindly.
- **Runs jobs well:** picks the right queue, writes Slurm scripts (CPU, A100 GPU, arrays), waits sensibly, and works out why a job failed or is still waiting.
- **Sets software up properly:** modules, conda/Python envs outside the purged scratch space, CUDA/PyTorch/vLLM, containers.
- **Knows the rules:** login-node limits, quotas, the 45-day scratch purge, how to move data in and out.

Built from SBU Research Computing's documentation and checked on the live cluster. Every fact lists its source
and date, and a bundled script lets Claude re-check the cluster instead of trusting stale notes.

## Contents

[Install](#install) · [Try it](#try-it) · [Connecting](#connecting-without-a-duo-push-per-command) ·
[For a whole lab](#for-a-whole-lab) · [What's inside](#whats-inside) · [Testing](#testing) ·
[Contributing](#contributing) · [Status](#status)

## Install

In Claude Code:

```
/plugin marketplace add khaihernlow/seawulf-claude-code
/plugin install seawulf@seawulf-claude-code
```

You need a SeaWulf account (your PI's project number and a ticket to RCI) and Duo on your phone. On Windows,
you also need WSL. Claude walks you through the rest the first time.

## Try it

- *"Check whether my SeaWulf jobs finished and show me the errors from any that failed."*
- *"Set up a conda env with PyTorch on SeaWulf and run train.py on one A100 for 6 hours."*
- *"My job says OUT_OF_MEMORY, what do I change?"*
- *"Run this script over these 200 input files on the cluster, 20 at a time."*
- *"Why has my GPU job been pending all day?"*

## Connecting without a Duo push per command

What it looks like (real output from 2026-11-20, NetID replaced):

```
$ scripts/preflight.sh
Checking ssh setup for 'seawulf'
  ok    Host seawulf -> milan.seawulf.stonybrook.edu as jdoe
  ok    ControlMaster on (your own login can be reused by the session)
  ok    your own login is open (master connection)
  next  'sw start' opens the long-lived session (ONE Duo push: tell the user first)

$ scripts/sw start
Duo push sent to the user's phone; waiting up to 120 s for approval...
session open

$ scripts/sw run <<'EOF'
sbatch --test-only templates/gpu-a100.sbatch
EOF
sbatch: Job 2443554 to start at 2026-11-24T14:36:57 using 8 processors on nodes a100-02 in partition a100
```

Claude checks your setup with `preflight.sh` (which sends no pushes), then uses the cheapest safe option:

| Your situation | What happens |
| --- | --- |
| On the **SBU VPN** | Duo was approved when the VPN connected, so Claude uses plain ssh |
| Usual case | You log in once yourself; Claude opens **one** long-lived session (one more push) and sends every command through it, about 2 s each, with no more pushes |
| You'd rather run Claude **on the cluster** | SeaWulf has Claude Code installed: `module load claude-code`, then sign in once |
| No terminal setup | You paste Claude's commands into the Open OnDemand web shell |

SSH keys remove the password step but **not** Duo (tested). You always authenticate yourself, and Claude never
sees or stores your password. Details: [connecting.md](skills/seawulf/references/connecting.md).

## For a whole lab

To offer the plugin to everyone who opens a project, commit this to the project's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "seawulf-claude-code": {"source": {"source": "github", "repo": "khaihernlow/seawulf-claude-code"}}
  },
  "enabledPlugins": {"seawulf@seawulf-claude-code": true}
}
```

## What's inside

| Path | What |
| --- | --- |
| [`skills/seawulf/SKILL.md`](skills/seawulf/SKILL.md) | What Claude reads first: the cluster in brief, the safety rules, how to connect, where to look next |
| [`references/connecting.md`](skills/seawulf/references/connecting.md) | Accounts, hosts, OnDemand, ssh config and keys, Duo and lockouts, Windows/WSL, troubleshooting |
| [`references/slurm.md`](skills/seawulf/references/slurm.md) | Queues and limits, shared vs whole-node, A100s, batch and interactive jobs, arrays, dependencies, monitoring, failure causes |
| [`references/software.md`](skills/seawulf/references/software.md) | Modules, conda/pip placement, GPU Python, Singularity, Jupyter and OnDemand apps |
| [`references/storage-and-data.md`](skills/seawulf/references/storage-and-data.md) | Home, scratch, project space, quotas, the purge, moving data |
| [`references/nvwulf.md`](skills/seawulf/references/nvwulf.md) | The H200/Blackwell cluster (from documentation; untested) |
| [`references/verified-facts.md`](skills/seawulf/references/verified-facts.md) | Every fact with its source and date |
| [`templates/`](skills/seawulf/templates/) | Shared-CPU, A100 and array job scripts, validated on the cluster |
| [`scripts/preflight.sh`](skills/seawulf/scripts/preflight.sh) | Checks your local setup and says what's missing (no Duo) |
| [`scripts/sw`](skills/seawulf/scripts/sw) | The one-session runner (macOS, Linux, WSL; forwards from Git Bash) |
| [`scripts/cluster-facts.sh`](skills/seawulf/scripts/cluster-facts.sh) | Current queues, limits, down nodes, your accounts, quotas, modules and jobs |
| [`evals/`](evals/) | Test cases for Claude's behaviour with the skill |

## Testing

[`evals/`](evals/) holds five cases that check what matters most:
- no connection spam;
- correct A100 scripts;
- diagnosing out-of-memory jobs;
- keeping envs out of scratch;
- refusing heavy work on login nodes.

They only let Claude read and write files, so running them never touches the cluster or sends a Duo push. Run
them (with and without the plugin) using `claude plugin eval . --allow-tools Write`. These are real, billed
model runs.

## Contributing

Corrections are especially welcome. The cluster changes, and some parts are only tested from one setup.
- Check a fact on the cluster (`scripts/cluster-facts.sh` helps), then update the reference **and** its row in `verified-facts.md` with the date and how you checked it.
- Keep personal details (NetIDs, paths, Slurm accounts) out of the repo.
- Keep `SKILL.md` short: details go in `references/`, one level deep.

## Status

Checked on 2026-11-20 against SeaWulf's milan login node, from Windows 11 with WSL (Ubuntu 24.04), on one
user's account. Not yet tested from macOS or Linux, on other accounts, or on NVwulf.

Related work: [hpc-skills](https://gitee.com/ktwu/hpc-skills) (Tufts, Northwestern, KAUST, EPFL) and
[Cirrus skills](https://skills.cirrus.ac.uk/) take the same approach for other clusters.

Not affiliated with or endorsed by Stony Brook University or Research Computing & Informatics. Follow SBU's
acceptable-use policies; you're responsible for what runs under your account. For help with the clusters
themselves, see [RCI's documentation](https://rci.stonybrook.edu/hpc/docs).

## License

MIT
