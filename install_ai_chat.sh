#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/ai_chat_cli.py"
REQ="$SCRIPT_DIR/requirements.txt"

if [[ ! -f $SRC ]]; then
  echo "❌ Cannot find ai_chat_cli.py – run installer from project root." >&2
  exit 1
fi

echo "🚀 AI-Chat installer"
echo
read -rp "Install (g)lobal to ~/.local/bin or in (v)env .venv? [g/v]: " MODE

# Helper: append PATH export / fish_user_paths if missing
ensure_path() {
  local dest="$HOME/.local/bin"
  case "$1" in
    bash) prof="$HOME/.bashrc"; line="export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
    zsh)  prof="$HOME/.zshrc";  line="export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
    fish) prof="$HOME/.config/fish/config.fish"; line="set -Ux fish_user_paths \$HOME/.local/bin \$fish_user_paths" ;;
  esac
  if ! grep -qxF "$line" "$prof" 2>/dev/null; then
    echo -e "\n# Added by AI-Chat\n$line" >> "$prof"
    echo "✅ PATH fix added to $prof"
  fi
  # Add to current session
  [[ ":$PATH:" != *":$dest:"* ]] && export PATH="$dest:$PATH"
}

# Ask for OpenAI key once
read_api_key() { read -rp "Enter your OpenAI API key: " OPENAI_KEY; }

case "${MODE,,}" in
  g|global)
    BIN="$HOME/.local/bin"
    mkdir -p "$BIN"
    install -m755 "$SRC" "$BIN/ai-chat"
    echo "✅ ai-chat placed in $BIN"

    echo "📦 Installing Python deps (user site)"
    if ! pip install --user --break-system-packages -r "$REQ"; then
      echo "⚠️  pip user install blocked. Falling back to pipx…"
      command -v pipx >/dev/null 2>&1 || sudo apt-get install -y pipx
      pipx install --python python3 --suffix ai-chat $(tr '\n' ' ' < "$REQ")
    fi

    for sh in bash zsh fish; do ensure_path "$sh"; done

    read_api_key
    for prof in "$HOME/.bashrc" "$HOME/.zshrc"; do
      echo -e "\nexport OPENAI_API_KEY=\"$OPENAI_KEY\"" >> "$prof"
    done
    echo "set -Ux OPENAI_API_KEY \"$OPENAI_KEY\"" >> "$HOME/.config/fish/config.fish"

    echo -e "\n🎉 Global install done."
    echo "➡️  Open a *new* terminal (or 'source ~/.bashrc') then run:  ai-chat \"Hello!\""
    ;;

  v|venv)
    VENV="$SCRIPT_DIR/.venv"
    [[ -d $VENV ]] || python3 -m venv "$VENV"
    # shellcheck disable=SC1090
    source "$VENV/bin/activate"
    pip install --upgrade pip
    pip install -r "$REQ"
    install -m755 "$SRC" "$VENV/bin/ai-chat"
    read_api_key
    echo "export OPENAI_API_KEY=\"$OPENAI_KEY\"" > "$VENV/env_vars"
    grep -q env_vars "$VENV/bin/activate" || echo 'source "$VIRTUAL_ENV/env_vars"' >> "$VENV/bin/activate"

    echo -e "\n🎉 Venv install done."
    echo "➡️  Run:  source .venv/bin/activate  &&  ai-chat \"Hi\""
    ;;

  *)
    echo "❌ Invalid choice – run again and enter g or v."
    exit 1
    ;;
esac
