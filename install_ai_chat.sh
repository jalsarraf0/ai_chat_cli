#!/usr/bin/env bash
set -euo pipefail

# ── Helpers: package-manager bootstrap ─────────────────────────────────────────

install_prereqs() {
  echo "🔍 Checking for python3, venv & pip…"
  local missing=()
  command -v python3 >/dev/null || missing+=(python3)
  python3 -m venv --help >/dev/null 2>&1 || missing+=(python3-venv)
  command -v pip3 >/dev/null || missing+=(pip)

  if [[ ${#missing[@]} -eq 0 ]]; then
    return 0
  fi

  echo "⚙️  Attempting to install missing: ${missing[*]}"
  if command -v apt-get &>/dev/null; then
    sudo apt-get update
    sudo apt-get install -y "${missing[@]/#/python3-}"
    return 0
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y "${missing[@]}"
    return 0
  elif command -v yum &>/dev/null; then
    sudo yum install -y "${missing[@]}"
    return 0
  elif command -v apk &>/dev/null; then
    sudo apk update
    # Alpine packages: python3, py3-pip, py3-virtualenv
    local toadd=()
    [[ " ${missing[*]} " == *" python3 "* ]] && toadd+=(python3)
    [[ " ${missing[*]} " == *" python3-venv "* ]] && toadd+=(py3-virtualenv)
    [[ " ${missing[*]} " == *" pip "* ]] && toadd+=(py3-pip)
    sudo apk add "${toadd[@]}"
    return 0
  elif command -v pacman &>/dev/null; then
    sudo pacman -Sy --noconfirm python python-virtualenv python-pip
    return 0
  else
    return 1
  fi
}

# Try to auto-install; if that fails, bail with instructions.
if ! install_prereqs; then
  cat >&2 <<EOF
❌ Could not install python3/venv/pip automatically.
Please install them manually, e.g.:

  • Debian/Ubuntu: sudo apt-get install python3 python3-venv python3-pip  
  • RHEL/Fedora:   sudo dnf install python3 python3-virtualenv python3-pip  
  • Alpine:        sudo apk add python3 py3-virtualenv py3-pip  
  • Arch:          sudo pacman -Sy python python-virtualenv python-pip  

Then re-run this installer.
EOF
  exit 1
fi

# ── Locate interpreters ────────────────────────────────────────────────────────

PYTHON_CMD=python3
PIP_CMD=pip3

# ── Paths and sources ──────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/ai_chat_cli.py"
REQ="$SCRIPT_DIR/requirements.txt"

[[ -f $SRC ]] || { echo "❌ ai_chat_cli.py not found in $SCRIPT_DIR" >&2; exit 1; }

# ── PATH helper ────────────────────────────────────────────────────────────────

ensure_path() {
  local dest="$HOME/.local/bin"
  local prof line
  case "$1" in
    bash) prof="$HOME/.bashrc"; line='export PATH="$HOME/.local/bin:$PATH"' ;;
    zsh)  prof="$HOME/.zshrc";  line='export PATH="$HOME/.local/bin:$PATH"' ;;
    fish) prof="$HOME/.config/fish/config.fish"; line='set -Ux fish_user_paths $HOME/.local/bin $fish_user_paths' ;;
    *)    return ;;
  esac

  mkdir -p "$(dirname "$prof")"
  if ! grep -Fxq "$line" "$prof" 2>/dev/null; then
    {
      echo ""
      echo "# Added by AI-Chat installer"
      echo "$line"
    } >> "$prof"
    echo "✅ Updated PATH in $prof"
  fi

  [[ ":$PATH:" != *":$dest:"* ]] && export PATH="$dest:$PATH"
}

# ── API-Key prompt ─────────────────────────────────────────────────────────────

read_api_key() {
  read -rp "Enter your OpenAI API key: " OPENAI_KEY
}

# ── Main installer ────────────────────────────────────────────────────────────

echo
echo "🚀 AI-Chat CLI Installer"
echo "   (supports Alpine, Debian/Ubuntu, RHEL/Fedora, Arch, etc.)"
echo

read -rp "Install (g)lobal to ~/.local/bin or in (v)env .venv? [g/v]: " MODE
case "${MODE,,}" in

  g|global)
    BIN="$HOME/.local/bin"
    mkdir -p "$BIN"

    install -m755 "$SRC" "$BIN/ai-chat"
    echo "✅ ai-chat launcher installed to $BIN/ai-chat"

    echo "📦 Installing Python dependencies (user site)…"
    if ! "$PIP_CMD" install --user -r "$REQ"; then
      echo "⚠️  pip install failed; falling back to pipx sandbox"

      if ! command -v pipx &>/dev/null; then
        echo "🔧 Installing pipx via $PIP_CMD…
"
        "$PIP_CMD" install --user pipx
        ensure_path bash && ensure_path zsh && ensure_path fish
        export PATH="$HOME/.local/bin:$PATH"
      fi

      echo "📦 Installing requirements via pipx…"
      pipx install --python python3 --suffix "-ai-chat" $(tr '\n' ' ' < "$REQ")
    fi

    for sh in bash zsh fish; do
      ensure_path "$sh"
    done

    read_api_key
    for prof in "$HOME/.bashrc" "$HOME/.zshrc"; do
      echo "" >> "$prof"
      echo "export OPENAI_API_KEY=\"$OPENAI_KEY\"" >> "$prof"
    done
    mkdir -p "$HOME/.config/fish"
    echo "set -Ux OPENAI_API_KEY \"$OPENAI_KEY\"" >> "$HOME/.config/fish/config.fish"

    echo
    echo "🎉 Global installation complete!"
    echo "   Restart your shell (or run 'source ~/.bashrc') then:"
    echo "     ai-chat \"Hello, world!\""
    ;;

  v|venv)
    VENV="$SCRIPT_DIR/.venv"
    if [[ ! -d $VENV ]]; then
      echo "🛠 Creating virtualenv at $VENV"
      "$PYTHON_CMD" -m venv "$VENV"
    fi

    # shellcheck disable=SC1090
    source "$VENV/bin/activate"
    pip install --upgrade pip
    pip install -r "$REQ"
    install -m755 "$SRC" "$VENV/bin/ai-chat"

    read_api_key
    echo "export OPENAI_API_KEY=\"$OPENAI_KEY\"" > "$VENV/env_vars"
    if ! grep -q env_vars "$VENV/bin/activate"; then
      echo 'source "$VIRTUAL_ENV/env_vars"' >> "$VENV/bin/activate"
    fi

    echo
    echo "🎉 Virtual-env installation complete!"
    echo "   Run:"
    echo "     source .venv/bin/activate && ai-chat \"Hi there!\""
    ;;

  *)
    echo "❌ Invalid choice – enter 'g' or 'v'." >&2
    exit 1
    ;;
esac
