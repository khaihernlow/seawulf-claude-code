---
name: seawulf
description: Run commands, Slurm jobs and file work on Stony Brook University's SeaWulf HPC cluster from Claude Code, without a Duo push per command. Use this whenever the user wants anything done on SeaWulf or SBU HPC — checking or submitting Slurm jobs (sbatch, squeue, sacct), running code on A100 GPUs, setting up conda envs in scratch, reading logs or results on the cluster, or connecting Claude to "the HPC", "seawulf", "milan", or "the cluster" — even if they don't mention ssh or Duo.
---

# SeaWulf from Claude Code

SeaWulf (Stony Brook University's HPC cluster) requires a Duo approval for **every new ssh session**, including sessions multiplexed over an already-open connection. A Claude that runs `ssh seawulf <command>` for each step sends the user a phone push for each step, and when one isn't approved quickly the command silently fails after about a minute. That looks like a flaky cluster, but it's the user's phone.

So: one long-lived session, approved once, with every command streamed through it by `scripts/sw`.

## The rules, and why

- **Never run plain `ssh`, `scp` or `rsync` to SeaWulf yourself.** Each is a new session, so a Duo push. Use `scripts/sw run`.
- **Never retry a connection or a command automatically.** A retry is another push, and a command that did start (say, `sbatch`) must not run twice.
- **Ask before `sw start`.** It sends a push to the user's phone; tell them to expect it and approve it.
- **Never ask for, type, store or log the user's password, and never try to answer Duo.** The user logs in themselves. This skill works *with* Duo, never around it.

## Workflow

### 1. Is a session open?

```bash
SW=<this skill's directory>/scripts/sw
"$SW" status
```

If it prints `session open`, go to step 3.

### 2. Open one (needs the user)

The first time on a machine, the user needs a `seawulf` entry in their ssh config, and on Windows, WSL. Walk them through [references/setup.md](references/setup.md) if `ssh -G seawulf` shows no `milan.seawulf...` hostname or `sw start` reports that ssh couldn't connect.

Then:

1. Ask the user to log in themselves in a terminal (on Windows: inside WSL) and leave it open:
   `ssh seawulf`, then password, then Duo. This holds the authenticated connection the session will reuse.
2. Tell them a second Duo push is coming, then run `"$SW" start` and wait for `session open` (up to 2 minutes).

If it fails, show the user the lines `sw start` printed and ask; don't loop.

### 3. Run things

```bash
"$SW" run 600 <<'EOF'
squeue --me
EOF
```

- The script runs as its own login-shell `bash` on the login node: `module`, `squeue`, `sbatch` and conda work, and `cd`, `exit` or `set -e` in one script don't affect the next.
- The number is how long to wait for output (seconds). Past it, `sw` returns 124, but the command **keeps running** on the cluster. Check its result later instead of rerunning it.
- Exit status and output are the script's own.
- Each call takes a couple of seconds and costs no Duo push.

Use the login node for light work: editing, `git`, `sbatch`, `squeue`, reading logs, small installs. Anything heavy goes in a Slurm job.

### 4. Get code and data there

- **Code:** push it to a git remote, then `git clone` or `git pull` on the cluster through `sw run`. The login node reaches GitHub.
- **Small text files:** write them in a script: `cat > file <<'X' ... X` inside the `sw run` heredoc. Pick a delimiter the content can't contain.
- **Large files:** ask the user. scp/sftp mean new sessions (Duo), and they failed over a shared connection in testing.

### 5. Slurm habits that avoid real trouble

- **Make submissions idempotent.** Give jobs a recognisable name (`-J`) and check `squeue --me -n NAME` before `sbatch`. `sbatch` on SeaWulf has been reported to print `Socket timed out` and still create the job, so after any `sbatch` error, look at the queue instead of resubmitting.
- **Wait inside one `sw run`**, rather than polling with many calls. For example, loop over `grep -q DONE log; sleep 10`, with a timeout below the `sw run` wait.
- **Read the queue honestly.** `squeue --me --start` gives the scheduler's estimate, and `sinfo -p a100 -N` shows node states. Nodes marked `draining`, often "Reboot ASAP", take no new jobs, so a long wait is the cluster, not the job.
- **Put work, envs, caches and outputs under `/gpfs/scratch/$USER/`.** The home quota is small, and scratch is not backed up.
- **Only cancel jobs the user started for this task**, and only with their say-so.

Partitions, accounts and other details vary by user and change over time. [references/seawulf-notes.md](references/seawulf-notes.md) lists what has been observed, each with how and when it was checked. Confirm anything time-sensitive on the cluster (`sinfo`, `sacctmgr show assoc user=$USER`) rather than trusting the notes.

## When the session drops

Laptop sleep, network changes, or WSL restarting end the session: `sw status` then says `no session`, or `run` reports `the session closed`. Tell the user and ask before `sw start` again, since that costs a push. If their own `ssh seawulf` window also closed, they need to log in there first.
