#!/usr/bin/env bash
# Compares the latest release tag of this clone with the remote one and prints a warning if the clone is out of date
# Agents run it at the start of a session (see agents/AGENTS.md). Never fails: offline or no tags is only a notice
set -uo pipefail

dir=$(cd "$(dirname "$0")/.." && pwd)

# floating tags (v1, v1.0) are skipped: only full versions are compared
latest() {
  grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1
}

local_version=$(git -C "$dir" tag --merged HEAD | latest)
# BatchMode: no password prompt, ConnectTimeout: don't hang without network
remote_version=$(GIT_SSH_COMMAND='ssh -o BatchMode=yes -o ConnectTimeout=5' \
  git -C "$dir" ls-remote --tags --refs origin 'v*' 2>/dev/null | latest)

if [ -z "$remote_version" ]; then
  echo "Could not check for tools update (offline?): local version ${local_version:-unknown}"
elif [ "$local_version" != "$remote_version" ]; then
  echo "WARNING: tools are out of date: local ${local_version:-unknown}, latest $remote_version"
  echo "Update: git -C $dir pull && $dir/install.sh"
else
  echo "tools $local_version is up to date"
fi
