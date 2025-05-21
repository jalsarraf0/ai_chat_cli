# 🚀 AI-Chat CLI

Version: **v2.0.2**

A **lightweight**, **pipe-friendly** command-line tool to chat with OpenAI’s ChatGPT directly from your terminal.

---

## 📑 Table of Contents

1. [Introduction](#introduction)  
2. [Features](#features)  
3. [Prerequisites](#prerequisites)  
4. [Installation](#installation)  
   - [Global Install (Unix/macOS)](#global-install-unixmacos)  
   - [Virtual Environment Install](#virtual-environment-install)  
   - [Windows PowerShell Install](#windows-powershell-install)  
5. [Configuration](#configuration)  
6. [Usage](#usage)  
   - [Basic Prompt](#basic-prompt)  
   - [Piping Input](#piping-input)  
   - [System Prompts](#system-prompts)  
   - [Models & Temperature](#models--temperature)  
   - [Streaming vs Single Response](#streaming-vs-single-response)  
   - [Additional Flags](#additional-flags)  
   - [REPL (Interactive Mode)](#repl-interactive-mode)  
   - [Shell Completions](#shell-completions)  
7. [Scripts Overview](#scripts-overview)  
8. [Examples](#examples)  
9. [Troubleshooting](#troubleshooting)  
10. [Contributing & Support](#contributing--support)  
11. [License](#license)  

---

## Introduction

**AI-Chat CLI** brings the power of OpenAI’s ChatGPT to your shell. Whether you’re writing quick prompts, analyzing logs, or integrating AI into scripts, AI-Chat CLI is fast, scriptable, and easy to configure.

---

## Features

- 🛠 **Pipe-friendly**: Reads from STDIN and writes to STDOUT.  
- ⚙️ **Configurable**: Save defaults with `--save-config`; uses `~/.config/ai_chat_cli/config.json`.  
- 🌐 **Distro-agnostic installer**: Supports Alpine, Debian/Ubuntu, RHEL/Fedora, Arch, macOS.  
- 🔒 **Secure key management**: Store API key globally or per-project venv.  
- 📋 **Argcomplete support**: Bash, Zsh, Fish, PowerShell completions.  
- 📜 **Interactive REPL**: `/exit`, `/help`, `/model`, `/system` commands.  
- 🚦 **Dry-run & raw modes** for testing payloads and output formats.  
- 🔄 **Streaming** and non-streaming modes.  
- 📊 **Model listing**: `--list-models` to fetch available OpenAI models.  

---

## Prerequisites

- **Python 3.7+**  
- **pip** or **pipx**  
- **OpenAI API Key**  

Set your API key via environment variable before running:  
```bash
export OPENAI_API_KEY="sk-..."
```
Or use `addapi.sh` to set it permanently.

---

## Installation

### Global Install (Unix/macOS)

```bash
chmod +x install_ai_chat.sh
./install_ai_chat.sh
```
- Choose **g** for a global install in `~/.local/bin`.  
- Script bootstraps Python³, venv, and pip if missing.  
- Updates shell profiles: `.bashrc`, `.zshrc`, `.zprofile`, `.profile`, Fish.  
- Prompts and saves API key to your shell profile.

### Virtual Environment Install

```bash
chmod +x install_ai_chat.sh
./install_ai_chat.sh
```
- Choose **v** for a per-project `.venv` install.  
- Creates `.venv`, installs dependencies, saves `ai-chat` in `.venv/bin`.  
- Prompts and stores API key in `.venv/env_vars`.

### Windows PowerShell Install

```powershell
# In PowerShell:
chmod +x aichatinstallwin.ps1
.ichatinstallwin.ps1
```
- Prompts for API key.  
- Sets key as a user environment variable.  
- Option to add shim `ai-chat.bat` to PATH.

---

## Configuration

Configuration is stored in JSON at:
```
~/.config/ai_chat_cli/config.json
```
Fields:
- `model`: default model ID  
- `temperature`: default temperature  
- `system`: default system prompt  

Save current flags as defaults:
```bash
ai-chat --save-config [other flags]
```

---

## Usage

### Basic Prompt

```bash
ai-chat "Explain the benefits of async I/O in Python."
```

### Piping Input

```bash
cat my_file.txt | ai-chat -s "Summarize this document."
```

### System Prompts

```bash
ai-chat -s "You are a helpful assistant." "How to structure a README?"
```

### Models & Temperature

- Select model:
  ```bash
  ai-chat -m gpt-4 "Generate a poem about autumn."
  ```
- Adjust temperature (0–2):
  ```bash
  ai-chat -t 0.2 "Be concise."
  ```

### Streaming vs Single Response

- **Streaming** (default, prints tokens as they arrive).  
- **Single response**:
  ```bash
  ai-chat -n "List 5 shell tips."
  ```

### Additional Flags

- `--raw`: no trailing newline.  
- `--dry-run`: print JSON payload and exit.  
- `--list-models`: fetch and list OpenAI model IDs.  
- `--install-completion [bash|zsh|fish|pwsh]`: emit completion script.  
- `--version`: show CLI version.

### REPL (Interactive Mode)

Invoke without prompt or stdin:
```bash
ai-chat
```
Commands:
- `/exit` or `/quit`: exit REPL  
- `/help`: list commands  
- `/model <id>`: switch model  
- `/system <msg>`: update system prompt  

History saved at:
```
~/.ai_chat_history
```

### Shell Completions

Activate completions for your shell:
```bash
ai-chat --install-completion bash > /etc/bash_completion.d/ai-chat
ai-chat --install-completion zsh  > ${fpath[1]}/_ai-chat
```
Adjust paths per your system.

---

## Scripts Overview

- **addapi.sh**: Store/update API key globally or in venv.  
- **install_ai_chat.sh**: Cross-distro installer for Unix/macOS.  
- **uninstallaichat.sh**: Remove installation, venv, and cleanup exports.  

---

## Examples

```bash
# Quick ideas
ai-chat "Suggest 5 project names for a CLI tool."

# Code review
cat script.py | ai-chat -s "You are a code reviewer."

# Storytelling
ai-chat -m gpt-4 -t 0.9 "Write a short fantasy tale."

# Batch logs
for f in logs/*.log; do cat $f | ai-chat -s "Summarize errors"; done
```

---

## Troubleshooting

- **Command not found**: Ensure `~/.local/bin` or `.venv/bin` is in `$PATH`.  
- **PEP 668 errors**: Run in venv mode or use `--break-system-packages`.  
- **Model fetch errors**: Check network or API key.  
- **Completion not working**: Source your shell’s completion file.  

---

## Contributing & Support

Contributions welcome! Open issues or PRs.  
For questions open an issue and I will be happy to help.

---

## License

Licensed under the [MIT License](LICENSE).
