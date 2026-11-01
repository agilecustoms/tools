# tools
Dev Tools

## Setup
Clone next to the other agilecustoms repos (`~/agilecustoms/github/tools`) and run `./install.sh` (needs `jq`).
After every update (`git pull`) run `./install.sh` again. It:
- links `agents/AGENTS.md` into `~/agilecustoms/github/AGENTS.md`, so agents apply shared rules in every repo
- registers Claude Code SessionStart hook in `~/.claude/settings.json` that runs `scripts/check-for-update.sh`

## Content
- `agents/AGENTS.md` - shared rules for AI agents
- `scripts/check-for-update.sh` - warns when this clone is behind the latest release
- `build/tools.sh` - `ac_build_token` to get CodeArtifact token for local builds
