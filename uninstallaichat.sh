#!/usr/bin/env bash
set -euo pipefail

echo "🧹 AI-Chat Uninstall Script"
echo

read -rp "This will remove AI-Chat binary, virtualenv, API key exports, and related entries. Continue? [y/N]: " confirm
if [[ ! $confirm =~ ^[Yy] ]]; then
  echo "Aborting uninstallation."
  exit 0
fi

# 1) Remove global binaries
for BINARY in "$HOME/.local/bin/ai-chat" "/usr/local/bin/ai-chat"; do
  if [ -f "$BINARY" ]; then
    sudo rm -f "$BINARY" 2>/dev/null || rm -f "$BINARY"
    echo "Removed binary: $BINARY"
  fi
done

# 2) Remove project virtualenv
if [ -d ".venv" ]; then
  rm -rf .venv
  echo "Removed virtual environment: .venv/"
fi

# 3) Clean up shell profile exports
SHELL_NAME=$(basename "${SHELL:-bash}")
case "$SHELL_NAME" in
  bash) PROFILE="$HOME/.bashrc" ;;
  zsh)  PROFILE="$HOME/.zshrc" ;;
  fish) PROFILE="$HOME/.config/fish/config.fish" ;;
  *)    PROFILE="$HOME/.bashrc" ;;
esac

# Remove API key block
if grep -q "# AI-Chat API Key" "$PROFILE"; then
  sed -i '/# AI-Chat API Key/,/^$/d' "$PROFILE"
  echo "Removed OpenAI_API_KEY export from $PROFILE"
fi

# Remove PATH export entries added by installer
sed -i '/ai-chat installer/d' "$PROFILE" 2>/dev/null || true
sed -i '/export PATH.*ai-chat/d' "$PROFILE" 2>/dev/null || true
echo "Cleaned AI-Chat PATH exports from $PROFILE"

# 4) Remove env_vars and gitignore entry
if [ -f ".venv/env_vars" ]; then
  rm -f .venv/env_vars
  echo "Removed .venv/env_vars"
fi
if grep -qxF ".venv/env_vars" .gitignore; then
  sed -i '/\.venv\/env_vars/d' .gitignore
  echo "Removed .venv/env_vars from .gitignore"
fi

echo
echo "✅ Uninstallation complete!"
echo "⚠️  Please restart your shell or run: source $PROFILE"
