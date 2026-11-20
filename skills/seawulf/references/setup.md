# One-time setup

Two things: an ssh `seawulf` entry that keeps the user's login open for reuse, and, on Windows, WSL.

## 1. Windows only: use WSL

Neither Git Bash's ssh nor Windows' built-in OpenSSH can keep a reusable connection: Git Bash fails with
`mux_client_request_session: read from master failed`, and Windows OpenSSH has no ControlMaster support.
Inside WSL it works.

- Check: `wsl -l -v` lists a Linux distribution (e.g. Ubuntu). If not: `wsl --install` (needs a restart).
- If WSL errors (for example `Wsl/Service/0x80072747`), `wsl --shutdown` and try again.
- If there are several distributions, tell `sw` which one: set `SW_WSL_DISTRO=<name>` (default: the default one).

Do steps 2 and 3 **inside WSL** on Windows; `sw` (run from Git Bash or anywhere) forwards to it.

## 2. The ssh entry

Append to `~/.ssh/config` (create it with mode 600 if missing), with the user's NetID:

```
Host seawulf
  HostName milan.seawulf.stonybrook.edu
  User <NetID>
  ControlMaster auto
  ControlPath ~/.ssh/cm-%C
  ControlPersist 8h
  ServerAliveInterval 60
```

- `milan.seawulf.stonybrook.edu` is the login node for the A100 GPU partitions (the one this was tested on).
  SeaWulf has other login nodes for other partitions; check SBU's SeaWulf documentation if the user needs a
  different one, and use a different alias (and `SW_HOST`) for each.
- ControlMaster keeps the user's password-authenticated connection open (8 h) so the `sw` session can open on
  it without a password. It does **not** avoid Duo: every new session still asks.
- Check it parsed: `ssh -G seawulf | grep -E '^(hostname|user|controlpath) '`.

## 3. Log in once, then start the session

1. The user runs `ssh seawulf` in a terminal (WSL on Windows), types their password, answers Duo, and keeps the
   window open.
2. Claude runs `sw start`; the user approves the second Duo push.
3. `sw status` prints `session open`.

## Troubleshooting

| Symptom | Likely cause |
| --- | --- |
| `sw start` fails with `Permission denied (publickey,...,password)` | No open `ssh seawulf` login for it to reuse (or it was opened outside WSL on Windows). Log in first |
| `sw start` waits, then `session did not open` | The Duo push wasn't approved within 2 minutes |
| `sw run` says `the session closed` | Sleep, network change or WSL restart. Ask the user, then log in / `sw start` again |
| `Could not resolve hostname seawulf` | The ssh entry is in a different config (Windows vs WSL each have their own `~/.ssh/config`) |
| Paths like `C:/...` appear where `/mnt/c/...` was meant (Windows) | Git Bash path conversion; `sw` sets `MSYS_NO_PATHCONV=1` itself, but your own commands may need it |
