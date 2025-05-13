# ai-chat-cli

An interactive, multi-provider AI chat CLI for OpenAI (ChatGPT), Anthropic (Claude), and Google Gemini models.

## Features

- **Multiple Providers**: Switch between OpenAI, Anthropic, and Google Gemini.
- **Interactive REPL**: Chat in your terminal with streaming responses.
- **Tab Completion**: Optional Bash/Zsh/Fish autocompletion via `argcomplete`.
- **List Models**: Discover available model IDs with `--list-models`.
- **No Config Files**: All configuration via environment variables or CLI flags.
- **Retry Logic**: Automatic retries with exponential back-off for transient API errors.
- **Provider Flexibility**: Lazy imports allow installation of only the SDKs you need.
- **User-Friendly**: Clear error messages and debug mode (`--debug`) for tracebacks.
- **Packaging Ready**: Install via `pip install .` and use the `ai-chat` command.

## Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/jalsarraf0/ai_chat_cli.git
   cd ai_chat_cli
   ```

2. **Create and activate a virtual environment**:
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   ```

3. **Install dependencies** using the provided `requirements.txt`:
   ```bash
   pip install --upgrade pip
   pip install -r requirements.txt
   ```

4. **Install the CLI tool** into your environment:
   ```bash
   pip install .
   ```

5. **(Optional) Enable tab-completion**:
   ```bash
   activate-global-python-argcomplete --user
   ```

## Usage

Set your API keys (replace `...` with your actual keys):

```bash
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="claude-sk-..."
export GOOGLE_API_KEY="google-sk-..."
```

Run the chat CLI:

```bash
ai-chat                                   # uses default provider (openai)
ai-chat -p openai -m gpt-4o               # specify provider and model
ai-chat -p anthropic --list-models        # list Anthropic models
ai-chat --no-stream                       # disable streaming output
ai-chat --debug                           # show full tracebacks on error
```

## Environment Variables

- `OPENAI_API_KEY` — Your OpenAI API key.
- `ANTHROPIC_API_KEY` — Your Anthropic API key.
- `GOOGLE_API_KEY` — Your Google API key.
- `AI_CHAT_DEFAULT_PROVIDER` — Default provider (openai, anthropic, or google).
- `AI_CHAT_DEFAULT_MODEL` — Default model ID.

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests on GitHub.

## License

MIT License © 2025
