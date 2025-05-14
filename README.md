# 🚀 AI-Chat CLI

A **lightweight**, **pipe-friendly** CLI tool to chat with OpenAI’s ChatGPT right from your terminal!  
💻 Works on **Linux**, **macOS**, and **Windows** (PowerShell, WSL).

---

## 🎯 Why You’ll Love It

- 🌟 **Minimal Setup** – No heavy dependencies, just Python & OpenAI SDK.  
- 🔗 **Pipes & Prompts** – Send command output or type questions directly.  
- 🤖 **System Roles** – Use `-s` to set AI’s “persona” (sysadmin, tutor, etc.).  
- ⚡ **Real-Time Streaming** – Watch responses stream live.  
- ☁️ **Cross-Platform** – Bash, Zsh, Fish, PowerShell – any shell!

---

## 🛠️ Installation

### 1. Clone or Download

**Git Clone**  
```bash
git clone https://github.com/jalsarraf0/ai_chat_cli.git
cd ai_chat_cli
```

**Download ZIP**  
1. Visit: https://github.com/jalsarraf0/ai_chat_cli  
2. Click **Code → Download ZIP**  
3. Unzip & enter folder:
   ```bash
   unzip ai_chat_cli-main.zip
   cd ai_chat_cli-main
   ```

---

### 2. (Optional) Virtual Environment

🔒 **Recommended** to keep things tidy.

```bash
python3 -m venv .venv
source .venv/bin/activate      # Linux/macOS
# or
.\.venv\Scripts\Activate.ps1 # Windows PowerShell
```

---

### 3. Install Python SDK

```bash
pip install --upgrade pip
pip install openai
```

---

### 4. Configure API Key

🔑 Get your key at [OpenAI Platform](https://platform.openai.com).  
Then:

- **Linux/macOS**  
  ```bash
  echo 'export OPENAI_API_KEY="sk-..."' >> ~/.bashrc
  source ~/.bashrc
  ```
- **Windows PowerShell**  
  ```powershell
  [Environment]::SetEnvironmentVariable('OPENAI_API_KEY','sk-...','User')
  ```

---

### 5. Make Executable & Install

```bash
chmod +x ai_chat_cli.py
./install_ai_chat.sh
```

This installs `ai-chat` to `~/.local/bin`.

---

## 🚀 Quick Start

### Ask a Question 💬

```bash
ai-chat "What is the difference between TCP and UDP?"
```

### Use a System Role 🎭

```bash
ai-chat -s "You are a friendly tutor." "Explain DNS in simple terms."
```

### Pipe Command Output 🔥

```bash
df -h | (
  echo "You are a disk expert."
  echo
  cat
) | ai-chat
```

### Interactive Mode 🖥️

```bash
ai-chat
# 👉 Type your questions, 'exit' to quit
```

---

## ⚙️ Advanced Flags

- `-s, --system` : Set AI's role  
- `-m, --model`  : Choose GPT model (default: **gpt-4o**)  
- `-t, --temperature`: Creativity 0.0–2.0  
- `--raw`        : No extra blank lines  
- `--version`    : Show version  

> **Tip:** Avoid `--no-stream`; streaming mode is more reliable.

---

## 🐞 Troubleshooting

- **Command not found:**  
  - Ensure `~/.local/bin` is in your PATH.  
  - Re-run `./install_ai_chat.sh`.

- **No output?**  
  - Remove `--no-stream`.  
  - Wrap your prompts and data in a single piped block.

- **API Key errors:**  
  - Double-check `OPENAI_API_KEY` export.

---

## 🧹 Uninstall

```bash
rm ~/.local/bin/ai-chat
```

---

## 📚 FAQs

**Q: Do I need Git?**  
>A: No—use ZIP or curl methods above.

**Q: Can I skip virtualenv?**  
>A: Yes; but venv keeps Python tools isolated.

---

✨ **Enjoy chatting with AI in your terminal!** ✨
