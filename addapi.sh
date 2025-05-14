#!/usr/bin/env bash
set -euo pipefail

# 1. Ensure we’re in the project root
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

# 2. Don’t run as root
if [ "$(id -u)" -eq 0 ]; then
  echo "✘ Please run this as your normal user, not root (no sudo)."
  exit 1
fi

# 3. Ensure .venv exists
if [ ! -d ".venv" ]; then
  echo "✘ .venv directory not found. Create it first with:"
  echo "    python3 -m venv .venv"
  exit 1
fi

# 4. Prompt for API keys (silent input)
read -rp "OpenAI API key: " -s OPENAI_API_KEY; echo
read -rp "Anthropic API key: " -s ANTHROPIC_API_KEY; echo
read -rp "Google API key: " -s GOOGLE_API_KEY; echo

# 5. Write them as exported vars
ENV_FILE=".venv/env_vars"
cat > "$ENV_FILE" <<EOF
# Auto-generated — do not commit
export OPENAI_API_KEY="$OPENAI_API_KEY"
export ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY"
export GOOGLE_API_KEY="$GOOGLE_API_KEY"
EOF
echo "✔ Wrote and exported keys to $ENV_FILE"

# 6. Patch activate to source env_vars
ACTIVATE=".venv/bin/activate"
SOURCE_LINE="source \"\$VIRTUAL_ENV/env_vars\""
if ! grep -Fxq "$SOURCE_LINE" "$ACTIVATE"; then
  {
    echo ""
    echo "# load project API keys"
    echo "$SOURCE_LINE"
  } >> "$ACTIVATE"
  echo "✔ Updated $ACTIVATE to load your env_vars on activation"
else
  echo "ℹ $ACTIVATE already sources env_vars"
fi

# 7. Protect .venv and env_vars from Git
GITIGNORE=".gitignore"
touch "$GITIGNORE"
for entry in ".venv/" "env_vars"; do
  if ! grep -Fxq "$entry" "$GITIGNORE"; then
    echo "$entry" >> "$GITIGNORE"
    echo "✔ Added '$entry' to $GITIGNORE"
  fi
done

# 8. Fix ownership if you ever ran with sudo
sudo chown -R "$(id -u):$(id -g)" .venv 2>/dev/null || true

echo
echo "🎉 Setup complete!"
echo "   From now on run:"
echo "     source .venv/bin/activate"
echo "   and your API keys will be in the environment."
