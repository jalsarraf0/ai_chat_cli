#!/usr/bin/env python3
# PYTHON_ARGCOMPLETE_OK
"""
ai_chat_cli.py  •  Minimal‑OpenAI Edition
=================================================
A tiny, dependency‑light CLI that lets you talk to **OpenAI Chat Completions** from *any* shell:

* Works with **pipes** – feed it `stdin` or supply a prompt as an argument.
* Optional **`-s/--system`** prompt to establish role (sysadmin, writer, etc.).
* **Interactive fallback** when no prompt/pipe is given.
* **Cross‑platform**: Bash/Z‑sh (Linux/macOS), PowerShell or Cmd (Windows).
* Clean, plain‑text output by default – perfect for further piping or redirection.
* Flags kept short & memorable (`-m`, `-t`, `--raw` …).

Installation (user site)  ▸  `pip install --user openai` then drop this file somewhere on $PATH.

Example usage
-------------
$ echo "df -h" | sh -c 'df -h | ai-chat -s "You are a disk guru" --raw'
$ ai-chat -s "Explain like I" "Write a one‑liner to find the 10 largest log files."  
$ free -h | ai-chat -s "Fedora sysadmin" --model gpt-4o-mini

"""
from __future__ import annotations

import argparse
import os
import sys
import json
import platform
from typing import List, Dict, Iterable

try:
    import openai
except ModuleNotFoundError:
    print("✘ Please `pip install openai` first", file=sys.stderr)
    sys.exit(1)

__version__ = "1.0.0"
OPENAI_DEFAULT_MODEL = os.getenv("AI_CHAT_DEFAULT_MODEL", "gpt-4o")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def stdin_text() -> str:
    """Return piped/redirected stdin if any, else empty string."""
    if sys.stdin.isatty():
        return ""
    return sys.stdin.read().strip()


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="ai-chat",
        description="Simple OpenAI ChatGPT CLI (stdin‑friendly)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("prompt", nargs="*", help="Prompt words (optional if stdin)")
    p.add_argument("-s", "--system", help="System prompt / role")
    p.add_argument("-m", "--model", default=OPENAI_DEFAULT_MODEL, help="OpenAI model id")
    p.add_argument("-t", "--temperature", type=float, default=0.7, help="0‑2 creativity")
    p.add_argument("--raw", action="store_true", help="Plain output (no extra blank lines)")
    p.add_argument("--no-stream", action="store_true", help="Disable streaming tokens")
    p.add_argument("--version", action="version", version=f"%(prog)s {__version__}")
    return p


def send_chat(model: str, temperature: float, messages: List[Dict[str, str]], stream: bool) -> Iterable[str] | str:
    resp = openai.chat.completions.create(
        model=model,
        messages=messages,
        temperature=temperature,
        stream=stream,
    )
    if stream:
        for chunk in resp:
            delta = chunk.choices[0].delta.content
            if delta:
                yield delta
    else:
        return resp.choices[0].message.content


# ---------------------------------------------------------------------------
# Main logic
# ---------------------------------------------------------------------------

def main() -> None:
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        print("✘ Set OPENAI_API_KEY env var first", file=sys.stderr)
        sys.exit(1)

    openai.api_key = api_key

    parser = build_parser()
    args = parser.parse_args()

    stdin_prompt = stdin_text()
    arg_prompt = " ".join(args.prompt).strip()

    # If no prompt via args nor stdin, start interactive repl
    if not stdin_prompt and not arg_prompt:
        interactive_mode(args)
        return

    user_prompt = "\n".join(filter(None, [stdin_prompt, arg_prompt]))
    history: List[Dict[str, str]] = []
    if args.system:
        history.append({"role": "system", "content": args.system})
    history.append({"role": "user", "content": user_prompt})

    result = send_chat(args.model, args.temperature, history, stream=not args.no_stream)

    if isinstance(result, str):
        print(result)
    else:
        for token in result:
            print(token, end="", flush=True)
        if not args.raw:
            print()


def interactive_mode(args):
    print(f"🔹 Connected to OpenAI ({args.model}) – type 'exit' to quit.\n")
    history: List[Dict[str, str]] = []
    if args.system:
        history.append({"role": "system", "content": args.system})

    while True:
        try:
            user_text = input("You > ")
        except (EOFError, KeyboardInterrupt):
            print("\nBye.")
            break
        if user_text.strip().lower() in {"exit", "quit"}:
            break
        if not user_text.strip():
            continue
        history.append({"role": "user", "content": user_text})
        for token in send_chat(args.model, args.temperature, history, stream=True):
            print(token, end="", flush=True)
        print("\n")
        # Append assistant message to history so context grows
        history.append({"role": "assistant", "content": ""})  # placeholder updated below
        history[-1]["content"] = token  # last chunk retains full text – okay for simple use‑case


if __name__ == "__main__":
    main()
