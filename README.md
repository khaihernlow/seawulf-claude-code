# seawulf-claude-code

A Claude Code plugin for working on Stony Brook University's **SeaWulf** HPC cluster: submitting and checking
Slurm jobs, setting up environments, reading logs, all from Claude Code, **without a Duo push for every command**.

## Why

SeaWulf asks for a Duo approval on every new ssh session, even over an already-open connection. An assistant
that runs one `ssh` per command sends you a phone push per command, and anything you don't approve in time fails
silently after about a minute. This plugin keeps **one** session open (one approval) and streams every command
through it. Each command then takes a couple of seconds and costs no push.

It works *with* Duo, never around it: you log in and approve every session yourself, and Claude never sees or
stores your password.

## Install

In Claude Code:

```
/plugin marketplace add khaihernlow/seawulf-claude-code
/plugin install seawulf@seawulf-claude-code
```

Then ask Claude to do something on SeaWulf. The skill walks you through the one-time setup:
- an ssh `seawulf` entry in `~/.ssh/config`;
- on Windows, WSL.

See [setup](skills/seawulf/references/setup.md).

## Using it

1. Log in yourself, in a terminal (inside WSL on Windows): `ssh seawulf`. Enter your password, answer Duo, and keep the window open.
2. Ask Claude for SeaWulf work. It will tell you before it opens its session, which sends one more Duo push.
3. From then on, commands run through that session. If it drops (sleep, network change), Claude asks before reopening it.

The script can also be used by hand: `skills/seawulf/scripts/sw start | run | status | stop`.

## What's in it

| Path | What |
| --- | --- |
| [`skills/seawulf/SKILL.md`](skills/seawulf/SKILL.md) | What Claude follows: one session, no ssh retries, Slurm habits (idempotent submits, scratch, honest queue reading) |
| [`skills/seawulf/scripts/sw`](skills/seawulf/scripts/sw) | The session script (macOS, Linux, WSL; forwards to WSL from Git Bash on Windows) |
| [`skills/seawulf/references/setup.md`](skills/seawulf/references/setup.md) | One-time setup and troubleshooting |
| [`skills/seawulf/references/seawulf-notes.md`](skills/seawulf/references/seawulf-notes.md) | Observed facts about SeaWulf, each marked verified (with date) or reported |

## Status

Tested on Windows 11 with WSL (Ubuntu 24.04), on the A100 login node (`milan`), in November 2026. Not yet
tested on macOS or Linux clients, or on other SeaWulf login nodes. Reports and fixes are welcome.

Not affiliated with or endorsed by Stony Brook University or its Research Computing team. Follow SBU's
acceptable-use policies; you are responsible for what runs under your account.

## License

MIT
