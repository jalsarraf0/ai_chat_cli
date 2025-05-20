#!/usr/bin/env bash
set -euo pipefail

# Detect if this script is being sourced
if [ "${BASH_SOURCE[0]}" != "$0" ]; then
  SOURCED=1
else
  SOURCED=0
fi

echo "🔧 AI-Chat API Key Setup"
echo

# Prompt where to store the key
read -rp "Where do you want to store your OpenAI API key? (v)env / (g)lobal: " choice

case "${choice,,}" in
  v|venv)
    # Ensure .venv exists
    if [ ! -d ".venv" ]; then
      echo "➕ Creating virtual environment..."
      python3 -m venv .venv
    fi

    # Prompt for the key
    read -rp "Enter your OpenAI API key: " OPENAI_KEY

    # Write to .venv/env_vars
    ENVFILE=".venv/env_vars"
    mkdir -p "$(dirname "$ENVFILE")"
    cat > "$ENVFILE" <<EOF
export OPENAI_API_KEY="$OPENAI_KEY"
EOF
    echo "✅ Stored key in $ENVFILE"

    # Hook into activation script
    ACTV=".venv/bin/activate"
    if ! grep -q "env_vars" "$ACTV"; then
      echo "source \"\$PWD/$ENVFILE\"" >> "$ACTV"
      echo "✅ Will load key when you run: source .venv/bin/activate"
    else
      echo "ℹ️  .venv/bin/activate already sources env_vars"
    fi

    # Add to .gitignore
    if ! grep -qxF ".venv/env_vars" .gitignore; then
      echo ".venv/env_vars" >> .gitignore
      echo "✅ Added .venv/env_vars to .gitignore"
    fi
    ;;

  g|global)
    # Prompt for the key
    read -rp "Enter your OpenAI API key: " OPENAI_KEY

    # Detect shell profile
    SHELL_NAME=$(basename "${SHELL:-/bin/bash}")
    case "$SHELL_NAME" in
      bash) PROFILE="$HOME/.bashrc" ;;
      zsh)  PROFILE="$HOME/.zshrc" ;;
      fish) PROFILE="$HOME/.config/fish/config.fish" ;;
      *)    PROFILE="$HOME/.bashrc" ;;
    esac

    # Append export to profile
    LINE="export OPENAI_API_KEY=\"$OPENAI_KEY\""
    if ! grep -qxF "$LINE" "$PROFILE"; then
      printf "\n# AI-Chat API key\n%s\n" "$LINE" >> "$PROFILE"
      echo "✅ Added key to $PROFILE"
    else
      echo "ℹ️  $PROFILE already contains an API key export"
    fi

    # Reload in this session if sourced
    if [ "$SOURCED" -eq 1 ]; then
      # Apply to current shell
      source "$PROFILE"
      echo "🔄 Reloaded $PROFILE into current shell"
    else
      echo "⚠️  To load it now, run: source $PROFILE"
    fi
    ;;

  *)
    echo "❌ Invalid choice: '$choice'. Please rerun and type 'v' or 'g'."
    exit 1
    ;;
esac

echo
echo "🎉 Setup complete!"
echo "   • (venv) run 'source .venv/bin/activate' before using ai-chat"
echo "   • (global) API key export added to $PROFILE"
