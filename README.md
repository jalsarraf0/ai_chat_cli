AI-Chat CLI
============

A simple command-line tool to chat with OpenAI's ChatGPT directly from your terminal.

---

📋 **CONTENTS**

1. What is AI-Chat?
2. Prerequisites
3. Getting the Code
4. Virtual Environment (Recommended)
5. Setting Your OpenAI API Key
6. Making the Script Executable
7. Installing to Your PATH
8. Verifying Installation
9. Basic Usage
10. Advanced Usage
11. Troubleshooting
12. Uninstalling
13. FAQs

---

1. WHAT IS AI-CHAT?
-------------------
AI-Chat lets you send prompts to OpenAI's ChatGPT right from Bash, Zsh, Fish, PowerShell, or any shell.

---

2. PREREQUISITES
----------------
- **Python 3.9+**
- **Internet connection**
- **OpenAI API key** (get one at https://platform.openai.com)
- Basic terminal knowledge (copy & paste commands)

---

3. GETTING THE CODE
-------------------

**A. Git Clone** (requires Git)
```bash
git clone https://github.com/jalsarraf0/ai_chat_cli.git
cd ai_chat_cli
```

**B. Download ZIP** (no Git)
1. Go to https://github.com/jalsarraf0/ai_chat_cli  
2. Click **Code → Download ZIP**  
3. Unzip and enter folder:
   ```bash
   unzip ai_chat_cli-main.zip
   cd ai_chat_cli-main
   ```

**C. curl / wget**
```bash
curl -L https://github.com/jalsarraf0/ai_chat_cli/archive/refs/heads/main.zip -o ai_chat_cli.zip
unzip ai_chat_cli.zip
cd ai_chat_cli-main
```
or
```bash
wget https://github.com/jalsarraf0/ai_chat_cli/archive/refs/heads/main.zip -O ai_chat_cli.zip
unzip ai_chat_cli.zip
cd ai_chat_cli-main
```

---

4. VIRTUAL ENVIRONMENT (RECOMMENDED)
------------------------------------
```bash
python3 -m venv .venv
source .venv/bin/activate       # Linux/macOS
# or
.\.venv\Scripts\Activate.ps1  # Windows PowerShell
```

---

5. SETTING YOUR API KEY
-----------------------
**Linux/macOS:**  
```bash
echo 'export OPENAI_API_KEY="sk-..."' >> ~/.bashrc
source ~/.bashrc
```

**Windows PowerShell:**  
```powershell
[Environment]::SetEnvironmentVariable('OPENAI_API_KEY','sk-...','User')
```

---

6. MAKING THE SCRIPT EXECUTABLE
-------------------------------
```bash
chmod +x ai_chat_cli.py
```
(Windows does not require this step.)

---

7. INSTALLING TO YOUR PATH
--------------------------

**A. Using install script**  
```bash
./install_ai_chat.sh
```

**B. Manual symlink**  
```bash
mkdir -p ~/.local/bin
ln -s "$(pwd)/ai_chat_cli.py" ~/.local/bin/ai-chat
export PATH="$HOME/.local/bin:$PATH"
```

---

8. VERIFYING INSTALLATION
-------------------------
```bash
which ai-chat
ai-chat --version
```

---

9. BASIC USAGE
--------------
- **Quick question:**  
  ```bash
  ai-chat "What is the capital of France?"
  ```

- **System prompt:**  
  ```bash
  ai-chat -s "You are a tutor." "Explain gravity in simple terms."
  ```

- **Pipe output:**  
  ```bash
  df -h | ai-chat -s "Disk expert" --no-stream
  ```

- **Interactive mode:**  
  ```bash
  ai-chat
  # type queries, then 'exit' to quit
  ```

---

10. ADVANCED USAGE
------------------
- `--no-stream` : full reply at once  
- `--raw`       : no extra blank lines  
- `-m`          : specify model  
- `-t`          : set temperature

---

11. TROUBLESHOOTING
-------------------
- **ai-chat: command not found**  
  Ensure `~/.local/bin` is in PATH and `ai-chat` is installed there.
- **API key errors**  
  Check `OPENAI_API_KEY` is set correctly.
- **Permission denied**  
  Run `chmod +x ai_chat_cli.py` and reinstall.

---

12. UNINSTALLING
----------------
```bash
rm ~/.local/bin/ai-chat
```

---

13. FAQs
-------
**Q:** Do I need Git?  
**A:** No—use the ZIP or curl methods.

**Q:** Can I skip virtualenv?  
**A:** Yes, but it may affect other Python packages.

---

Enjoy using AI-Chat in your terminal!
