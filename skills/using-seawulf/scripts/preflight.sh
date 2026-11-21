#!/usr/bin/env bash
# Preflight, run LOCALLY (not on the cluster): what's ready for working on SeaWulf, and what the user must do next.
# Sends no Duo push: it never opens a new ssh connection.
#   preflight.sh            check host alias "seawulf" (or $SW_HOST)
set -u
HOST=${SW_HOST:-seawulf}
here=$(cd "$(dirname "$0")" && pwd)
ok()   { echo "  ok    $*"; }
todo() { echo "  TODO  $*"; TODOS=$((TODOS + 1)); }
TODOS=0

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    echo "Windows (Git Bash): checking inside WSL, where ssh can hold a session"
    export MSYS_NO_PATHCONV=1
    distro=(); [ -n "${SW_WSL_DISTRO:-}" ] && distro=(-d "$SW_WSL_DISTRO")
    if ! wsl.exe "${distro[@]}" --exec true < /dev/null 2> /dev/null; then
      echo "  TODO  Install WSL (PowerShell: wsl --install, then restart), or run 'wsl --shutdown' if it errors"
      exit 1
    fi
    self=$(wsl.exe "${distro[@]}" --exec wslpath -u "$(cygpath -w "$0")" < /dev/null | tr -d '\0\r')
    wsl.exe "${distro[@]}" --exec env SW_HOST="$HOST" ${SW_STATE:+SW_STATE="$SW_STATE"} bash "$self" < /dev/null | tr -d '\0'
    exit "${PIPESTATUS[0]}"
    ;;
esac

echo "Checking ssh setup for '$HOST' on $(uname -s)"
command -v ssh > /dev/null && ok "ssh: $(ssh -V 2>&1)" || todo "install an ssh client"

cfg=$(ssh -G "$HOST" 2> /dev/null)
hostname=$(echo "$cfg" | awk '$1=="hostname"{print $2}')
user=$(echo "$cfg" | awk '$1=="user"{print $2}')
if [ "$hostname" = "$HOST" ] || [ -z "$hostname" ]; then
  todo "add a '$HOST' entry to ~/.ssh/config (references/connecting.md, section 4)"
else
  ok "Host $HOST -> $hostname as $user"
  case "$hostname" in
    *milan.seawulf*|*xeonmax.seawulf*|*nvwulf*) ;;
    *login.seawulf*) todo "login.seawulf was retired in Nov 2026: use milan.seawulf.stonybrook.edu" ;;
    *) echo "  note  $hostname is not a known SBU login host" ;;
  esac
  [ "$user" = "$(whoami)" ] && echo "  note  ssh user is your local name ($user); set 'User <netid>' if your NetID differs"
  echo "$cfg" | grep -q '^controlmaster auto' && ok "ControlMaster on (your own login can be reused by the session)" \
    || todo "add ControlMaster/ControlPath/ControlPersist to the entry so 'sw start' can reuse your login"
  echo "$cfg" | grep -qi '^sendenv.*DUO_PASSCODE' && [ -n "${DUO_PASSCODE:-}" ] && ok "DUO_PASSCODE=$DUO_PASSCODE is sent (skips the Duo menu)" \
    || echo "  note  optional: 'SendEnv DUO_PASSCODE' + 'export DUO_PASSCODE=push' skips the Duo menu (doesn't reduce pushes)"
  if ssh -O check "$HOST" 2> /dev/null; then ok "your own login is open (master connection)"
  else echo "  note  no open login to reuse: before 'sw start', the user runs 'ssh $HOST' themselves (password + Duo) and keeps it open"; fi
fi

ls ~/.ssh/id_ed25519 ~/.ssh/id_rsa > /dev/null 2>&1 && ok "an ssh key exists (removes the password step; Duo still asks)" \
  || echo "  note  optional: an ssh key removes the password step (Duo still asks every connection)"

if [ -x "$here/sw" ] || [ -f "$here/sw" ]; then
  st=$(SW_HOST="$HOST" bash "$here/sw" status 2> /dev/null)
  [ "$st" = "session open" ] && ok "sw session open: run commands with 'sw run'" \
    || echo "  next  'sw start' opens the long-lived session (ONE Duo push: tell the user first)"
fi

echo
[ $TODOS -eq 0 ] && echo "Ready." || echo "$TODOS thing(s) to set up first (see TODO lines)."
