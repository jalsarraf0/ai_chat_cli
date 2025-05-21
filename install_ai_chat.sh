#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# 1) BOOTSTRAP: ensure python3, venv & pip via distro package manager
# -----------------------------------------------------------------------------
install_prereqs() {
  echo "🔍 Checking for python3, venv & pip…"
  local missing=()
  command -v python3 >/dev/null || missing+=(python3)
  python3 -m venv --help >/dev/null 2>&1 || missing+=(python3-venv)
  command -v pip3 >/dev/null || missing+=(pip)

  if (( ${#missing[@]} == 0 )); then
    return 0
  fi

  echo "⚙️  Installing missing: ${missing[*]}"
  if   command -v apt-get &>/dev/null; then
    sudo apt-get update
    sudo apt-get install -y python3 python3-venv python3-pip
  elif command -v dnf     &>/dev/null; then
    sudo dnf install -y python3 python3-virtualenv python3-pip
  elif command -v yum     &>/dev/null; then
    sudo yum install -y python3 python3-virtualenv python3-pip
  elif command -v apk     &>/dev/null; then
    sudo apk update
    sudo apk add python3 py3-virtualenv py3-pip
  elif command -v pacman  &>/dev/null; then
    sudo pacman -Sy --noconfirm python python-virtualenv python-pip
  else
    return 1
  fi
  return 0
}

if ! install_prereqs; then
  cat >&2 <<EOF
❌ Could not auto-install python3/venv/pip.
Please install manually, e.g.:

  • Debian/Ubuntu: sudo apt-get install python3 python3-venv python3-pip  
  • RHEL/Fedora:   sudo dnf install python3 python3-virtualenv python3-pip  
  • Alpine:        sudo apk add python3 py3-virtualenv py3-pip  
  • Arch:          sudo pacman -Sy python python-virtualenv python-pip  

Then re-run this installer.
EOF
  exit 1
fi

# -----------------------------------------------------------------------------
# 2) SETUP: locate interpreters & project paths
# -----------------------------------------------------------------------------
PYTHON_CMD=python3
PIP_CMD=pip3

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/ai_chat_cli.py"
REQ="$SCRIPT_DIR/requirements.txt"

[[ -f $SRC ]] || { echo "❌ Missing ai_chat_cli.py in $SCRIPT_DIR" >&2; exit 1; }
[[ -f $REQ ]] || { echo "❌ Missing requirements.txt in $SCRIPT_DIR" >&2; exit 1; }

# -----------------------------------------------------------------------------
# 3) PATH HELPER: ensure ~/.local/bin in Bash, Zsh (rc+profile), Fish & sh rc’s
# -----------------------------------------------------------------------------
ensure_path() {
  local dest="$HOME/.local/bin"
  local profs line

  case "$1" in
    bash) profs=("$HOME/.bashrc") ;;
    zsh)  profs=("$HOME/.zshrc" "$HOME/.zprofile") ;;
    fish) profs=("$HOME/.config/fish/config.fish") ;;
    sh)   profs=("$HOME/.profile") ;;
    *)    return ;;
  esac

  line='export PATH="$HOME/.local/bin:$PATH"'
  for prof in "${profs[@]}"; do
    mkdir -p "$(dirname "$prof")"
    if ! grep -Fxq "$line" "$prof" 2>/dev/null; then
      {
        echo ""
        echo "# Added by AI-Chat installer"
        echo "$line"
      } >> "$prof"
      echo "✅ Updated PATH in $prof"
    fi
  done

  [[ ":$PATH:" != *":$dest:"* ]] && export PATH="$dest:$PATH"
}

# -----------------------------------------------------------------------------
# 4) PROMPT: read OpenAI key once
# -----------------------------------------------------------------------------
read_api_key() {
  read -rp "Enter your OpenAI API key: " OPENAI_KEY
}

# -----------------------------------------------------------------------------
# 5) INSTALL: global vs. virtualenv
# -----------------------------------------------------------------------------
cat <<EOF

🚀 AI-Chat CLI Installer
   Supports Alpine, Debian/Ubuntu, RHEL/Fedora, Arch, etc.

EOF

read -rp "Install (g)lobal to ~/.local/bin or in (v)env .venv? [g/v]: " MODE
case "${MODE,,}" in

  g|global)
    BIN="$HOME/.local/bin"
    mkdir -p "$BIN"
    install -m755 "$SRC" "$BIN/ai-chat"
    echo "✅ Launcher installed to $BIN/ai-chat"
    echo

    # Make current session see ~/.local/bin
    export PATH="$HOME/.local/bin:$PATH"

    # pip install with retry & pipx fallback
    echo "📦 Installing Python dependencies…"
    if ! "$PIP_CMD" install --user -r "$REQ"; then
      echo "⚠️ pip install failed; retrying with --break-system-packages"
      if ! "$PIP_CMD" install --user --break-system-packages -r "$REQ"; then
        echo "⚠️ pip (break-system) failed; falling back to pipx"
        if ! command -v pipx &>/dev/null; then
          echo "🔧 Installing pipx…"
          "$PIP_CMD" install --user pipx || \
            "$PIP_CMD" install --user --break-system-packages pipx
          # ensure pipx is on PATH
          ensure_path bash && ensure_path zsh && ensure_path fish && ensure_path sh
          export PATH="$HOME/.local/bin:$PATH"
        fi
        echo "📦 Installing dependencies via pipx…"
        pipx install --python python3 --suffix "-ai-chat" \
          $(tr '\n' ' ' < "$REQ")
      fi
    fi

    # Persist PATH in future shells
    for shell in bash zsh fish sh; do
      ensure_path "$shell"
    done

    # Persist API key
    echo
    read_api_key
    # write into all relevant profiles
    for prof in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.profile"; do
      echo "" >> "$prof"
      echo "export OPENAI_API_KEY=\"$OPENAI_KEY\"" >> "$prof"
    done
    mkdir -p "$HOME/.config/fish"
    echo "set -Ux OPENAI_API_KEY \"$OPENAI_KEY\"" >> \
      "$HOME/.config/fish/config.fish"

    # Warn if still not on PATH
    if ! command -v ai-chat &>/dev/null; then
      echo
      echo "⚠️ ~/.local/bin is still not on your current PATH."
      echo "   To use ai-chat now, run:"
      echo '     export PATH="$HOME/.local/bin:$PATH"'
    fi

    echo
    echo "🎉 Global installation complete!"
    echo "   In new shells, ai-chat will be available automatically."
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

    echo
    read_api_key
    echo "export OPENAI_API_KEY=\"$OPENAI_KEY\"" > "$VENV/env_vars"
    if ! grep -q env_vars "$VENV/bin/activate"; then
      echo 'source "$VIRTUAL_ENV/env_vars"' >> "$VENV/bin/activate"
    fi

    echo
    echo "🎉 Virtual-env installation complete!"
    echo "   To use:"
    echo "     source .venv/bin/activate"
    echo "     ai-chat \"Hi there!\""
    ;;

  *)
    echo "❌ Invalid choice: enter 'g' or 'v'." >&2
    exit 1
    ;;
esac
