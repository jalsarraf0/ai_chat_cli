# ai-chat CLI (OpenAI Edition)

A simple, pipe-friendly CLI for interacting with OpenAI's Chat Completions API from any shell (Bash, Zsh, Fish, PowerShell, etc.).

## Features

- **Lightweight**: No extra dependencies beyond `openai`.
- **Stdin & Positional Prompts**: Accepts piped input or direct arguments.
- **System Role Prompts**: Use `-s/--system` to set the assistant’s role.
- **Streaming & Raw Modes**: `--no-stream` for complete replies; `--raw` to suppress extra newlines.
- **Interactive REPL**: Fallback when no prompt or stdin is provided.
- **Cross-Platform**: Works on Linux, macOS, and Windows shells.
- **Versioned**: `--version` flag for easy version checks.

## Installation

1. **Install the OpenAI SDK**:
   ```bash
   pip install --user openai
   ```

2. **Set your API key**:
   ```bash
   export OPENAI_API_KEY="sk-..."
   ```

3. **Make the script executable and install**:
   ```bash
   chmod +x ai_chat_cli.py
   ./install_ai_chat.sh
   ```

This installs `ai-chat` to `~/.local/bin`.

## Usage

### Direct prompt
```bash
ai-chat "What is the difference between a hard link and a symlink?"
```

### System prompt
```bash
ai-chat -s "You are a blockchain advisor." "Explain peer-to-peer in simple terms."
```

### Piped input
```bash
df -h | ai-chat -s "Disk usage expert" --no-stream
```

### Interactive mode
```bash
ai-chat
```

Type your queries, or `exit` to quit.

## Flags

- `-s, --system` : Set a system/role prompt.
- `-m, --model`  : Choose model (default: gpt-4o).
- `-t, --temperature`: Creativity level (0–2).
- `--no-stream`: Disable streaming output.
- `--raw`: Suppress trailing newline.
- `--version`: Show version.

## Examples

```bash
free -h | ai-chat -s "System monitor" --no-stream
uptime | ai-chat -s "Performance guru" --no-stream
```

## License

MIT License – use and modify freely.
