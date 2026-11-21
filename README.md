# seawulf-claude-code

A Claude Code plugin that lets Claude work on **Stony Brook University's HPC clusters**: SeaWulf, plus
NVwulf for large GPU jobs. You don't need to know HPC, and Claude doesn't need to be told how the cluster
works. Install it and ask.

- **Connects safely.** SeaWulf asks for Duo on *every* new ssh connection, and 10 unanswered pushes lock your account. Claude uses one session per approval and never retries blindly.
- **Runs jobs well:** picks the right queue, writes Slurm scripts (CPU, GPU, arrays), waits sensibly, and works out why a job failed or is still waiting.
- **Knows the GPUs:** SeaWulf's are A100s (its older K80, P100 and V100 nodes were retired in November 2026); NVwulf has H200 and RTX PRO 6000 Blackwell GPUs, with its own account and queues.
- **Sets software up properly:** modules, conda/Python envs outside the purged scratch space, CUDA/PyTorch/vLLM, containers.
- **Knows the rules:** login-node limits, quotas, the 45-day scratch purge, how to move data in and out.

Built from SBU Research Computing's documentation and checked on the live cluster. Every fact lists its source
and date, and a bundled script lets Claude re-check the cluster instead of trusting stale notes.

## Contents

[Install](#install) · [Try it](#try-it) · [Ways to work](#ways-to-work) ·
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

## Ways to work

SeaWulf asks for Duo on every new ssh connection (SSH keys only remove the password step), so how Claude
connects matters. There are four ways; pick what fits how you work. The skill's knowledge (queues, limits,
envs, failures) applies to all of them.

| | Claude runs on | Duo | Setup | Good when |
| --- | --- | --- | --- | --- |
| **One session from your laptop** | Your laptop | One push per session; commands then take ~2 s with no pushes | ssh config; WSL on Windows | Your code and tools live on your laptop and the cluster runs it |
| **On the SBU VPN** | Your laptop | Approved once at VPN connect; plain ssh after that | VPN client | You're on the VPN anyway |
| **Claude Code on SeaWulf** | The login node (`module load claude-code`) | One push per login | Sign in to Claude there once; install this plugin there too | You work only on the cluster |
| **Open OnDemand shell** | Anywhere | One login in the browser | None | You can't set anything up; you paste commands back and forth |

You always authenticate yourself, and Claude never sees or stores your password.

### One session from your laptop

`scripts/preflight.sh` checks your setup without connecting. `scripts/sw` then holds one session open for every
command, plus `put`/`get` for files. Real output from 2026-11-20 (NetID replaced):

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

### Claude Code on SeaWulf

RCI provides Claude Code as a module. Log in (`ssh seawulf`, one push), then:

```
tmux                          # so Claude survives a dropped connection
module load claude-code
claude auth login             # once; stored in your SeaWulf home
claude                        # then, inside Claude Code, install this plugin with the two /plugin commands above
```

Claude then runs on the shared login node: commands are local, but the login-node limits (3 CPUs, 15 GB per user)
apply to Claude and everything it runs there. Heavy work still goes through Slurm, which the skill handles.
Signing in on the cluster hasn't been tested yet; reports welcome.

Details for all four: [connecting.md](skills/seawulf/references/connecting.md).

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
| [`references/slurm.md`](skills/seawulf/references/slurm.md) | SeaWulf queues and limits, shared vs whole-node, A100 GPUs, batch and interactive jobs, arrays, dependencies, monitoring, failure causes |
| [`references/software.md`](skills/seawulf/references/software.md) | Modules, conda/pip placement, GPU Python, Singularity, Jupyter and OnDemand apps |
| [`references/storage-and-data.md`](skills/seawulf/references/storage-and-data.md) | Home, scratch, project space, quotas, the purge, moving data |
| [`references/nvwulf.md`](skills/seawulf/references/nvwulf.md) | NVwulf: H200 and Blackwell GPU queues, limits, modules, and the quota that blocks jobs |
| [`references/verified-facts.md`](skills/seawulf/references/verified-facts.md) | Every fact with its source and date |
| [`templates/`](skills/seawulf/templates/) | Shared-CPU, A100 and array job scripts, validated on the cluster |
| [`scripts/preflight.sh`](skills/seawulf/scripts/preflight.sh) | Checks your local setup and says what's missing (no Duo) |
| [`scripts/sw`](skills/seawulf/scripts/sw) | The one-session runner: `start`, `run`, `put`/`get` files, `stop` (macOS, Linux, WSL; forwards from Git Bash) |
| [`scripts/cluster-facts.sh`](skills/seawulf/scripts/cluster-facts.sh) | Current queues, limits, down nodes, your accounts, quotas, modules and jobs |
| [`evals/`](evals/) | Test cases for Claude's behaviour with the skill |
| [`CHANGELOG.md`](CHANGELOG.md) | What changed in each release |

## Testing

**Behaviour:** [`evals/`](evals/) has six cases, each run three times with and without the plugin and graded on
what Claude actually did (`claude plugin eval . --allow-tools Write`, Claude Code 2.1.329). Pass rates on
2026-11-20, with / without the plugin:

| Case | Claude Opus 5.5 | Claude Haiku 5.5 |
| --- | --- | --- |
| Checks jobs without a Duo push per command | 100% / 56% | 100% / 44% |
| Keeps conda envs out of purged scratch | 100% / 50% | 83% / 0% |
| Writes a correct A100 job script | 100% / 67% | 75% / 50% |
| Diagnoses an OUT_OF_MEMORY job | 100% / 83% | 83% / 50% |
| Refuses heavy work on the login node | 100% / 100% (since tightened) | 89% / 0% |
| Picks a queue for a small job | 100% / 100% | 100% / 58% |

Haiku's misses led to the "Numbers used most" table and the explicit conda lines now in `SKILL.md` and the GPU
template.

**Triggering:** [`evals/triggering/`](evals/triggering/) checks that the skill activates for SeaWulf requests and
stays quiet for near-misses (Slurm on other clusters, a personal GPU, Duo for email, course registration). Claude
runs with only the Skill tool, so nothing touches the cluster. Result: 20/20 correct (Claude Opus 5.5).

Both kinds are real, billed model runs (about $3 on Opus 5.5, under $1 on Haiku 5.5, about $1 for
triggering), and none of them connect to SeaWulf or send Duo pushes.

## Contributing

Corrections are especially welcome. The cluster changes, and some parts are only tested from one setup.
- Check a fact on the cluster (`scripts/cluster-facts.sh` helps), then update the reference **and** its row in `verified-facts.md` with the date and how you checked it.
- Keep personal details (NetIDs, paths, Slurm accounts) out of the repo.
- Keep `SKILL.md` short: details go in `references/`, one level deep.

## Status

Checked on 2026-11-20 against SeaWulf's milan login node, from Windows 11 with WSL (Ubuntu 24.04), on one
user's account; NVwulf checked the same day. Not yet tested from macOS or Linux, or on other accounts.

Related work: [hpc-skills](https://gitee.com/ktwu/hpc-skills) (Tufts, Northwestern, KAUST, EPFL) and
[Cirrus skills](https://skills.cirrus.ac.uk/) take the same approach for other clusters.

Not affiliated with or endorsed by Stony Brook University or Research Computing & Informatics. Follow SBU's
acceptable-use policies; you're responsible for what runs under your account. For help with the clusters
themselves, see [RCI's documentation](https://rci.stonybrook.edu/hpc/docs).

## License

MIT
