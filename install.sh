#!/usr/bin/env bash
# Sets up tools on this computer, safe to rerun (also after every update)
# 0. Checks that required commands are installed
# 1. Registers auto-update check
# 2. Creates symlink ~/agilecustoms/github/AGENTS.md for common agents instructions

set -euo pipefail

dir=$(cd "$(dirname "$0")" && pwd)

# 0. Check all commands used below are installed, before changing anything
required=(jq) # add a command here when a new step needs it
missing=()
for command in "${required[@]}"; do
  command -v "$command" >/dev/null || missing+=("$command")
done
if [ ${#missing[@]} -gt 0 ]; then
  echo "Missing commands: ${missing[*]}, install them (brew install ${missing[*]}) and rerun" >&2
  exit 1
fi

# 1. Register Claude Code SessionStart hook that runs scripts/check-for-update.sh
settings="${CLAUDE_SETTINGS:-$HOME/.claude/settings.json}" # env var to test on a copy
cmd="$dir/scripts/check-for-update.sh"
mkdir -p "$(dirname "$settings")"
[ -s "$settings" ] || echo '{}' > "$settings"
# drop previously registered entry (path may differ after moving the dir), keep other hooks as is
updated=$(jq --arg cmd "$cmd" '
  .hooks.SessionStart = [
    (.hooks.SessionStart // [])[]
    | .hooks |= map(select(.command | endswith("tools/scripts/check-for-update.sh") | not))
    | select(.hooks | length > 0)
  ] + [{matcher: "startup", hooks: [{type: "command", command: $cmd}]}]
' "$settings")
echo "$updated" > "$settings"
echo "Registered SessionStart hook in $settings: $cmd"

# 2. Create symlink ~/agilecustoms/github/AGENTS.md -> ~/agilecustoms/github/tools/agents/AGENTS.md
link="$(dirname "$dir")/AGENTS.md"
target="$(basename "$dir")/agents/AGENTS.md" # relative, so the link survives moving the whole dir
if [ -e "$link" ] && [ ! -L "$link" ]; then
  echo "$link is a regular file, not replacing it: move it away and rerun" >&2
  exit 1
fi
ln -sfn "$target" "$link"
echo "Linked $link -> $target"
