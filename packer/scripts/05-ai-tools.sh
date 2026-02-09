#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing Claude Code..."
su - arch -c '
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    curl -fsSL https://claude.ai/install.sh | bash
'

echo "==> Installing OpenCode..."
su - arch -c '
    curl -fsSL https://opencode.ai/install | bash
'

echo "==> 05-ai-tools.sh complete"
