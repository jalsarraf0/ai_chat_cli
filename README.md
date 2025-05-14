README - AI-Chat CLI Installation & Usage Guide
===============================================

This guide covers **every possible way** to install and use the `ai-chat` command-line tool. It assumes **no prior technical knowledge**.

---

CONTENTS
--------
1. What is AI-Chat?
2. Prerequisites
3. Downloading or Cloning the Repository
   - 3.1 Git Clone Method
   - 3.2 Download as ZIP from GitHub
   - 3.3 Using `curl` or `wget`
4. Installing via pip (when package is published)
5. Manual Setup (no pip)
6. Installing System-Wide vs. User-Local
7. Virtual Environment (Recommended)
   - 7.1 Create venv
   - 7.2 Activate venv
   - 7.3 Install dependencies
8. Setting Your OpenAI API Key
   - 8.1 Linux/macOS
   - 8.2 Windows PowerShell
9. Making the Script Executable (Linux/macOS)
10. Installing the Tool to Your PATH
    - 10.1 Using provided install script
    - 10.2 Manual symlink
11. Verifying Installation
12. Basic Usage Examples
    - 12.1 Direct Prompt
    - 12.2 System Prompt
    - 12.3 Piped Input
    - 12.4 Interactive Mode
13. Advanced Usage
    - 13.1 No-Stream Mode
    - 13.2 Raw Mode
14. Troubleshooting
15. Uninstalling AI-Chat
16. FAQs

---

1. WHAT IS AI-CHAT?
-------------------
AI-Chat is a lightweight command-line tool that lets you send prompts to OpenAI’s ChatGPT models directly from your terminal or PowerShell.

---

2. PREREQUISITES
----------------
- A computer running **Linux**, **macOS**, or **Windows**.
- **Python 3.9+** installed (for methods using Python).
- **Internet connection**.
- An **OpenAI API key** (get one at https://platform.openai.com).

---

3. DOWNLOADING OR CLONING THE REPOSITORY
----------------------------------------

3.1 Git Clone Method (Requires Git installed)
   1. Open your terminal (Linux/macOS) or Command Prompt/Git Bash (Windows).
   2. Run:
      ```
      git clone https://github.com/jalsarraf0/ai_chat_cli.git
      ```
   3. Change into the new folder:
      ```
      cd ai_chat_cli
      ```

3.2 Download as ZIP from GitHub (No Git required)
   1. Open https://github.com/jalsarraf0/ai_chat_cli in your web browser.
   2. Click **Code** → **Download ZIP**.
   3. Unzip the file:
      - **Windows:** Right-click ZIP → Extract All...
      - **Linux/macOS:** `unzip ai_chat_cli-main.zip`
   4. Change into the folder:
      ```
      cd ai_chat_cli-main
      ```

3.3 Using `curl` or `wget`
   - **curl**:
     ```
     curl -L https://github.com/jalsarraf0/ai_chat_cli/archive/refs/heads/main.zip -o ai_chat_cli.zip
     unzip ai_chat_cli.zip
     cd ai_chat_cli-main
     ```
   - **wget**:
     ```
     wget https://github.com/jalsarraf0/ai_chat_cli/archive/refs/heads/main.zip -O ai_chat_cli.zip
     unzip ai_chat_cli.zip
     cd ai_chat_cli-main
     ```

---

4. INSTALLING VIA PIP (IF PUBLISHED)
-----------------------------------
If `ai-chat` is published to PyPI:
```
pip install --user ai-chat
```
Then skip to section 8 to set your API key.

---

5. MANUAL SETUP (NO PIP)
------------------------
If you cannot use pip, you can run the script directly after setting up Python:
- See sections 7 (venv) and 9 (make executable) below.

---

6. INSTALLING SYSTEM-WIDE VS. USER-LOCAL
----------------------------------------
- **User-Local** (default):
  Installs into `~/.local/bin` (no sudo needed).
- **System-Wide** (requires sudo):
  Installs into `/usr/local/bin` so all users can run it:
  ```
  sudo mkdir -p /usr/local/bin
  sudo cp ai_chat_cli.py /usr/local/bin/ai-chat
  sudo chmod +x /usr/local/bin/ai-chat
  ```

---

7. VIRTUAL ENVIRONMENT (RECOMMENDED)
------------------------------------

7.1 Create the venv
```bash
python3 -m venv .venv
```

7.2 Activate the venv
- **Linux/macOS**:
  ```bash
  source .venv/bin/activate
  ```
- **Windows PowerShell**:
  ```powershell
  .\.venv\Scripts\Activate.ps1
  ```

7.3 Install dependencies
```bash
pip install --upgrade pip
pip install openai
```

---

8. SETTING YOUR OPENAI API KEY
------------------------------

8.1 Linux/macOS
Add to your shell profile:
```bash
echo 'export OPENAI_API_KEY="sk-..."' >> ~/.bashrc
source ~/.bashrc
```

8.2 Windows PowerShell
```powershell
[Environment]::SetEnvironmentVariable('OPENAI_API_KEY','sk-...','User')
```
Then restart PowerShell.

---

9. MAKING THE SCRIPT EXECUTABLE (Linux/macOS)
----------------------------------------------
```bash
chmod +x ai_chat_cli.py
```

---

10. INSTALLING THE TOOL TO YOUR PATH
------------------------------------

10.1 Using provided install script
```bash
./install_ai_chat.sh
```

10.2 Manual symlink
```bash
mkdir -p ~/.local/bin
ln -s "$(pwd)/ai_chat_cli.py" ~/.local/bin/ai-chat
```
Ensure `~/.local/bin` is in your `PATH`.

---

11. VERIFYING INSTALLATION
--------------------------
```
which ai-chat
ai-chat --version
```

---

12. BASIC USAGE EXAMPLES
------------------------

12.1 Direct Prompt
```
ai-chat "What is the capital of France?"
```

12.2 System Prompt
```
ai-chat -s "You are a tutor." "Explain quantum entanglement in simple terms."
```

12.3 Piped Input
```
df -h | ai-chat -s "Disk expert" --no-stream
```

12.4 Interactive Mode
```
ai-chat
# Then type queries, 'exit' to quit
```

---

13. ADVANCED USAGE
------------------

13.1 No-Stream Mode (entire reply at once)
```
df -h | ai-chat --no-stream
```

13.2 Raw Mode (no trailing newline)
```
echo "Hello" | ai-chat --raw
```

---

14. TROUBLESHOOTING
-------------------
- **Command not found**: Ensure `~/.local/bin` is in PATH and `ai-chat` is installed there.
- **API key error**: Confirm `OPENAI_API_KEY` is exported and correct.
- **Permission denied**: Check `chmod +x` on scripts.

---

15. UNINSTALLING AI-CHAT
------------------------
Remove the binary:
```
rm ~/.local/bin/ai-chat
```
Optionally remove the project folder.

---

16. FAQs
-------
**Q:** Do I need Python?  
**A:** Yes, for most installation methods. Use the GitHub ZIP + install script to avoid pip if needed.

**Q:** Can I use other AI providers?  
**A:** This version supports only OpenAI. No additional providers required.

---

Enjoy your AI-powered terminal experience!
