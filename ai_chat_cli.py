#!/usr/bin/env python3
# PYTHON_ARGCOMPLETE_OK
"""
ai_chat_cli.py  •  v2.0.2
— OpenAI Chat CLI with completions, config, dry-run, etc.
"""

from __future__ import annotations
import argparse, json, os, sys
from pathlib import Path
from typing import Dict, Iterable, List

try:
    import openai
except ModuleNotFoundError:
    sys.exit("✘ Please `pip install openai` first")

try:
    import argcomplete              # noqa: WPS433
except ModuleNotFoundError:          # pragma: no cover
    argcomplete = None

try:
    from colorama import Fore, Style, init as colorama_init
except ModuleNotFoundError:          # pragma: no cover
    Fore = Style = None              # type: ignore
    colorama_init = lambda: None     # type: ignore

colorama_init(autoreset=True)

__version__ = "2.0.2"
CONFIG_PATH = Path(os.getenv("AI_CHAT_CONFIG", Path.home() / ".config/ai_chat_cli/config.json"))
OPENAI_DEFAULT_MODEL = "gpt-4o"
CONFIG: Dict[str, str | float] = {}


def colour(t: str, c: str) -> str:
    return f"{getattr(Fore, c)}{t}{Style.RESET_ALL}" if Fore else t


def load_cfg() -> None:
    global CONFIG, OPENAI_DEFAULT_MODEL
    if CONFIG_PATH.is_file():
        try:
            CONFIG = json.loads(CONFIG_PATH.read_text())
            OPENAI_DEFAULT_MODEL = CONFIG.get("model", OPENAI_DEFAULT_MODEL)  # type: ignore[arg-type]
        except Exception:
            print(colour("⚠ Bad config JSON – ignored.", "YELLOW"), file=sys.stderr)


def save_cfg(opts):  # noqa: ANN001
    CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
    CONFIG_PATH.write_text(json.dumps({
        "model": opts.model,
        "temperature": opts.temperature,
        "system": opts.system_prompt or ""
    }, indent=2))
    print(colour(f"✓ Saved defaults to {CONFIG_PATH}", "GREEN"))


def stdin_text() -> str:
    return "" if sys.stdin.isatty() else sys.stdin.read().strip()


def list_models() -> None:
    try:
        models = openai.models.list()
    except Exception as e:  # noqa: BLE001
        sys.exit(colour(f"✘ Cannot fetch models: {e}", "RED"))
    for m in sorted(models, key=lambda m: m.id):
        print(m.id)
    sys.exit(0)


def send_chat(model: str, temp: float, msgs: List[Dict[str, str]], stream: bool) -> Iterable[str] | str:
    resp = openai.chat.completions.create(model=model, messages=msgs, temperature=temp, stream=stream)
    if stream:
        for chunk in resp:
            if (delta := chunk.choices[0].delta.content):
                yield delta
    else:
        return resp.choices[0].message.content


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="ai-chat", description="Tiny yet deluxe OpenAI Chat CLI")
    p.add_argument("prompt", nargs="*", help="Prompt (omit if piping stdin)")
    p.add_argument("-s", "--system", dest="system_prompt", help="System prompt / role")
    p.add_argument("-m", "--model", default=OPENAI_DEFAULT_MODEL, help="Model ID")
    p.add_argument("-t", "--temperature", type=float, default=0.7, help="Creativity 0-2")
    p.add_argument("--raw", action="store_true", help="No trailing blank line")
    p.add_argument("--no-stream", action="store_true", help="Disable streaming")
    p.add_argument("--dry-run", action="store_true", help="Show JSON payload & exit")
    p.add_argument("--list-models", action="store_true", help="List model IDs then exit")
    p.add_argument("--save-config", action="store_true", help="Persist current flags as defaults")
    p.add_argument("--install-completion", choices=["bash", "zsh", "fish", "pwsh"],
                   help="Emit completion script for given shell")
    p.add_argument("--version", action="version", version=f"%(prog)s {__version__}")
    if argcomplete:
        argcomplete.autocomplete(p)
    return p


def install_completion(shell: str) -> None:
    if not argcomplete:
        sys.exit("✘ `argcomplete` not installed")
    code = argcomplete.shellcode(executables=["ai-chat"], shell=shell)
    print(code)
    sys.exit(0)


def repl(opts, hist):  # noqa: ANN001
    try:
        import readline, atexit  # noqa: WPS433
        histfile = Path.home() / ".ai_chat_history"
        if histfile.exists():
            readline.read_history_file(histfile)
        atexit.register(lambda: readline.write_history_file(histfile))
    except ModuleNotFoundError:
        pass

    print(colour(f"🔹 Interactive – model {opts.model}.  /exit quits.", "CYAN"))
    while True:
        try:
            line = input("You > ")
        except (EOFError, KeyboardInterrupt):
            print(); break
        if line.startswith("/"):
            if line in {"/exit", "/quit"}:
                break
            if line == "/help":
                print("/exit  /model <id>  /system <msg>")
                continue
            if line.startswith("/model "):
                opts.model = line.split(maxsplit=1)[1]
                print(colour(f"✓ Model → {opts.model}", "GREEN")); continue
            if line.startswith("/system "):
                hist.append({"role": "system", "content": line.split(maxsplit=1)[1]})
                print(colour("✓ System prompt set.", "GREEN")); continue
            print("Unknown. Try /help"); continue
        if not line.strip():
            continue
        hist.append({"role": "user", "content": line})
        reply: List[str] = []
        for tok in send_chat(opts.model, opts.temperature, hist, stream=not opts.no_stream):
            print(tok, end="", flush=True); reply.append(tok)
        if not opts.raw:
            print()
        hist.append({"role": "assistant", "content": "".join(reply)})


def main() -> None:
    load_cfg()
    if not (key := os.getenv("OPENAI_API_KEY")):
        sys.exit(colour("✘ Set OPENAI_API_KEY", "RED"))
    openai.api_key = key

    args = parser().parse_args()

    if args.install_completion:
        install_completion(args.install_completion)
    if args.list_models:
        list_models()
    if args.save_config:
        save_cfg(args); sys.exit(0)

    stdin_p, arg_p = stdin_text(), " ".join(args.prompt).strip()
    if not stdin_p and not arg_p:
        msgs: List[Dict[str, str]] = []
        if args.system_prompt:
            msgs.append({"role": "system", "content": args.system_prompt})
        repl(args, msgs); return

    prompt = "\n".join(filter(None, [stdin_p, arg_p]))
    msgs: List[Dict[str, str]] = []
    if args.system_prompt:
        msgs.append({"role": "system", "content": args.system_prompt})
    msgs.append({"role": "user", "content": prompt})

    if args.dry_run:
        print(json.dumps({"model": args.model, "temperature": args.temperature, "messages": msgs}, indent=2)); return

    out = send_chat(args.model, args.temperature, msgs, stream=not args.no_stream)
    if isinstance(out, str):
        print(out); return
    for tok in out:
        print(tok, end="", flush=True)
    if not args.raw:
        print()


if __name__ == "__main__":
    main()
