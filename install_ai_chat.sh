#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Installing updated ai-chat..."

PROJECT_DIR="/home/jalsarraf/git/ai_chat_cli"
SRC="$PROJECT_DIR/ai_chat_cli.py"
TARGET="$HOME/.local/bin/ai-chat"

# Ensure ~/.local/bin exists
mkdir -p "$HOME/.local/bin"

# Remove old version if it exists
if command -v ai-chat &>/dev/null; then
  echo "🧹 Removing old ai-chat from: $(command -v ai-chat)"
  rm -f "$(command -v ai-chat)"
fi

# Copy updated script and make executable
echo "📄 Copying $SRC to $TARGET"
cp "$SRC" "$TARGET"
chmod +x "$TARGET"

# Add ~/.local/bin to PATH if missing
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  echo '📌 Adding ~/.local/bin to PATH in ~/.bashrc'
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
  export PATH="$HOME/.local/bin:$PATH"
fi

# Verify installation
echo "✅ ai-chat installed at: $(which ai-chat)"
ai-chat --version || echo "ℹ️ Run 'ai-chat' to start using it!"
