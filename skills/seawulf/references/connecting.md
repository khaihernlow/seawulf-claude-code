# Connecting: accounts, hosts, Duo, and Claude's session

## Contents
1. Getting an account
2. Which host
3. Browser access (Open OnDemand)
4. ssh setup
5. Duo: what costs a push, and the lockout
6. How Claude connects (choose one)
7. Windows
8. Troubleshooting

## 1. Getting an account

- Every user needs a **project number**. Only Stony Brook faculty (or BNL staff) request projects, with a one-page PDF on the work, computing needs, software, storage and group members.
- A student or collaborator whose PI already has a project opens a ticket with the help topic **"Request an account for SeaWulf"**, giving their NetID, PI and project number.
- The user's Slurm account(s) are listed by `sacctmgr show assoc user=$USER format=account,partition,qos`. Pass one with `-A` if they have more than one.
- **Duo** must be enrolled before the first login.

Source: [RCI quick start](https://rci.stonybrook.edu/docs/quick-start-guide), [requesting accounts](https://rci.stonybrook.edu/docs/requesting-accounts-project-numbers).

## 2. Which host

| Host | Reaches | Notes |
| --- | --- | --- |
| `milan.seawulf.stonybrook.edu` (login nodes `milan1`, `milan2`) | 40-core Skylake, 96-core Milan, HBM, **A100 GPU** queues | RCI: "the best choice for most work". Use this unless there's a reason not to |
| `xeonmax.seawulf.stonybrook.edu` | Sapphire Rapids / HBM queues | |
| `login.nvwulf.stonybrook.edu` | **NVwulf**, the separate H200 / Blackwell GPU cluster | Separate home and storage. See [nvwulf.md](nvwulf.md) |
| `login.seawulf.stonybrook.edu` (`login1`, `login2`) | — | **Retired November 2026**, along with Haswell and K80/P100/V100 nodes. Rebuild software built there on milan |

**Queues depend on the login node.** `invalid partition specified` usually means the wrong one. The module list also differs per node: its MODULEPATH includes architecture folders like `milan`, `skylake` and `xeonMax`.

## 3. Browser access (Open OnDemand)

[sn-ood.seawulf.stonybrook.edu](https://sn-ood.seawulf.stonybrook.edu) needs one Duo login per browser session. It offers:
- shell access ("SeaWulf Cluster Shell Access");
- a file manager for uploads and downloads;
- Jupyter, which runs on **CPU nodes**;
- RStudio, MATLAB, code-server, a desktop, and apps including vLLM and Ollama with Open WebUI.

It's the easiest route for people new to a terminal, and the fallback for uploads when ssh transfers are awkward. The OnDemand web shell mangles multi-line pastes, so give one-line commands there.

## 4. ssh setup

The user puts this in `~/.ssh/config` on the machine Claude runs on (inside WSL on Windows):

```
Host seawulf
  HostName milan.seawulf.stonybrook.edu
  User <netid>                 # lowercase
  ServerAliveInterval 60
  # Connection reuse: one login, many ssh/scp/rsync (see section 5)
  ControlMaster auto
  ControlPath ~/.ssh/cm-%C
  ControlPersist 1h
  # Skip the Duo menu: always send a push (or phone, or a passcode)
  SendEnv DUO_PASSCODE
```

Then `export DUO_PASSCODE=push` in the shell profile. Add `ForwardX11 yes` only for graphical programs (Mac: XQuartz).

**SSH keys** (RCI recommends them) remove the password step. **They don't remove Duo:** a key-only login on milan still sent a push (tested 2026-11-20). Set one up like this:

```
ssh-keygen -t ed25519 -C "<netid>@seawulf"          # set a passphrase
ssh-add ~/.ssh/id_ed25519
ssh-copy-id -i ~/.ssh/id_ed25519.pub <netid>@milan.seawulf.stonybrook.edu
```

The SeaWulf home directory is shared by all its login nodes, so one key works for all of them. NVwulf has a separate home, so copy the key there too. Never copy the private key to the cluster.

Source: [connecting](https://rci.stonybrook.edu/docs/connecting-cluster), [Duo](https://rci.stonybrook.edu/docs/duo-authentication), [passwordless SSH](https://rci.stonybrook.edu/docs/passwordless-ssh).

## 5. Duo: what costs a push, and the lockout

- Every login asks for Duo. **After 10 Duo requests in a row go unanswered, the account is locked.** Unlocking it takes replying to an email, or a call to DoIT if Duo itself is locked. An agent that reconnects in a loop can do this to a user in minutes, so never retry a connection automatically.
- **SBU VPN:** Duo is approved once when the VPN connects, and logins through the VPN don't ask again. RCI calls this the best fix for scripts that open many connections. If the user can use the VPN, Claude can use plain `ssh` freely.
- **Connection reuse (ControlMaster):** per RCI's Duo page, later `ssh`/`scp`/`rsync` over an open connection don't ask again. **Observed exception:** on `milan` on 2026-11-20 (Windows 11, WSL Ubuntu 24.04 client), every new command over a reused connection still sent a push. Whether reuse saves pushes may depend on the client or node, so ask the user whether pushes arrive.
- `DUO_PASSCODE` only chooses the method (push, phone, passcode). It doesn't reduce how many approvals there are.

## 6. Ways Claude can work (the user chooses)

No way is best for everyone. Each is described here with its trade-offs; ask the user which fits how they work.

1. **On the SBU VPN, or connection reuse confirmed to work** (no push per command): run `ssh seawulf '<command>'` directly. Still never loop on failures.
2. **One long-lived session with `scripts/sw`** (one push per session, then none). Fits work whose code and tools live on the laptop:
   - The user logs in once in their own terminal (`ssh seawulf`) and keeps it open. With ControlMaster, the session reuses that authenticated connection. With a key, that first login is optional, but `sw start` still sends its own push either way.
   - Tell the user a push is coming, then run `scripts/sw start`.
   - Run commands with `scripts/sw run [SECS] <<'EOF' ... EOF`. Move files with `sw put` / `sw get` (up to 50 MB).
   - `scripts/sw status`, and `sw stop` when the work is done.
   - If the session drops (sleep, network, WSL restart), ask before `sw start` again.
3. **Claude Code on the cluster itself.** SeaWulf provides it as a module (`claude-code/2.1.207` on 2026-11-20; it also loads `node.js`):
   - The user connects once (ssh or the OnDemand shell: one Duo push), then runs `module load claude-code`, starts a `tmux` session so a dropped connection doesn't kill it, and runs `claude` in their project folder in scratch.
   - Commands are then local, with no per-command Duo, but Claude runs on the shared login node: **3 CPUs and 15 GB per user**, and everything heavy still goes through Slurm.
   - Unsigned, `claude -p` answers `Not logged in · Please run /login`. The user signs in once with `claude auth login` (Claude subscription by default; `--console` for API billing), or `claude setup-token` for a long-lived token on a subscription. On a machine without a browser, login normally shows a link to open on the laptop. The full sign-in on the cluster hasn't been tested here. The login is stored in the user's SeaWulf home (`~/.claude`).
   - The local laptop's files and tools aren't available that way. Code should come in through git.
   - Install this plugin there as well (the same two `/plugin` commands, inside Claude Code on the cluster), so the cluster-side Claude knows the queues, limits and rules too. The module's Claude Code version may lag behind the laptop's.
   - Fits work that lives only on the cluster.
4. **No terminal setup at all:** the user works in Open OnDemand's shell and pastes Claude's one-line commands and their output back and forth. It's slow, but it needs nothing installed.

## 7. Windows

Git Bash's ssh and Windows OpenSSH can't hold a reusable connection: Git Bash fails with `mux_client_request_session: read from master failed`. **Use WSL** (`wsl --install`; `wsl --shutdown` if it errors). `scripts/sw` forwards into WSL by itself when run from Git Bash; set `SW_WSL_DISTRO` if there are several distributions. The ssh config in section 4 goes in WSL's `~/.ssh/config`, not Windows'.

## 8. Troubleshooting

| Symptom | Likely cause |
| --- | --- |
| A command fails after ~60 s with exit 1 and no output | A Duo push went unanswered. Stop retrying; tell the user |
| "Your account has been locked out due to excessive authentication failures" | 10 unanswered pushes. The user replies to the email, or contacts DoIT |
| `Permission denied (publickey,...,password)` with BatchMode | Nothing to reuse and no key: the user must log in first |
| `Could not resolve hostname seawulf` | The ssh entry is in the other config (Windows vs WSL) |
| `invalid partition specified` | Wrong login node for that queue |
| `sbatch: command not found` | `module load slurm` (login shells usually load it already) |
| Too many failed password attempts | The IP gets blocked; open a ticket |
