#!/usr/bin/env python3
# PYTHON_ARGCOMPLETE_OK
"""
ai_chat_cli.py
==============

Interactive, multi-provider AI chat from any Linux (or macOS/Windows) terminal.

Current providers
-----------------
* OpenAI (ChatGPT family)
* Anthropic (Claude family)
* Google Gemini (official google-genai SDK)

Quick start
-----------
# 1.  Create and activate a venv
python -m venv .venv && source .venv/bin/activate

# 2.  Install package dependencies
# (replace '.' with the path to your project root once you package it)
pip install openai anthropic google-genai rich tenacity argcomplete python-dotenv

# 3.  Export at least one API key in your shell or .env file
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="claude-sk-..."
export GOOGLE_API_KEY="google-sk-..."

# 4.  Enable optional tab-completion (once per shell)
# Bash:
activate-global-python-argcomplete --user

# 5.  Run the CLI
python ai_chat_cli.py                         # default provider (openai)
python ai_chat_cli.py -p google -m gemini-2.0-flash-001
python ai_chat_cli.py --list-models           # discover model names

Copyright (c) 2025
Released under the MIT Licence
"""
from __future__ import annotations

import argparse
import os
import sys
import logging
import textwrap
from dataclasses import dataclass
from typing import Iterable, List, Optional, Dict

# --------------------------------------------------------------------------- #
# Optional third-party, imported lazily where possible
# --------------------------------------------------------------------------- #
try:
    # nice terminal colours & markdown
    from rich.console import Console
    from rich.markdown import Markdown
except ModuleNotFoundError:
    print("✘ The 'rich' package is required.  Run: pip install rich", file=sys.stderr)
    sys.exit(1)

try:
    # automatic retries with back-off
    import tenacity
except ModuleNotFoundError:
    print("✘ The 'tenacity' package is required.  Run: pip install tenacity", file=sys.stderr)
    sys.exit(1)

# argcomplete is optional; script still runs if absent
try:
    import argcomplete  # type: ignore
except ModuleNotFoundError:
    argcomplete = None  # noqa: N816  (keep name for later check)

# dotenv is optional
try:
    from dotenv import load_dotenv  # type: ignore
except ModuleNotFoundError:
    load_dotenv = None  # type: ignore

# --------------------------------------------------------------------------- #
# Globals
# --------------------------------------------------------------------------- #
console = Console()
logger = logging.getLogger("ai_chat_cli")
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
)

# --------------------------------------------------------------------------- #
# Dataclasses and abstract provider
# --------------------------------------------------------------------------- #
@dataclass
class Message:
    role: str          # "system" | "user" | "assistant"
    content: str


class ProviderError(RuntimeError):
    """Raised for provider-specific fatal errors which should reach the user."""


class BaseProvider:
    """
    Abstract interface every provider wrapper must satisfy.
    """

    # name displayed to user
    name: str
    # default system prompt (optional)
    default_system_prompt: Optional[str] = None
    # does this SDK support server-side streaming?
    supports_streaming: bool = True

    def __init__(self, model: str, temperature: float, timeout: int):
        self.model = model
        self.temperature = temperature
        self.timeout = timeout

    # ----- public API ------------------------------------------------------ #
    def chat(
        self, history: List[Message], stream: bool = True
    ) -> Iterable[str] | str:
        """
        Send the conversation *history* and either yield streaming text chunks
        or return a full reply string (if stream==False).
        """
        raise NotImplementedError  # pragma: no cover

    def list_models(self) -> List[str]:
        """Return a *best effort* list of model IDs accessible to the key."""
        raise NotImplementedError  # pragma: no cover

    # ----- helpers --------------------------------------------------------- #
    @staticmethod
    def _require_env(var: str, friendly_name: str | None = None) -> str:
        """
        Fetch *var* from environment, abort with a colourful message if absent.
        """
        val = os.getenv(var)
        if not val:
            label = friendly_name or var
            raise ProviderError(
                f"{label} is not set.  Export it or place it in a .env file."
            )
        return val


# --------------------------------------------------------------------------- #
# OpenAI implementation
# --------------------------------------------------------------------------- #
class OpenAIProvider(BaseProvider):
    name = "openai"
    supports_streaming = True

    def __init__(self, model: str, temperature: float, timeout: int):
        # Lazy import so script still works without openai package if user
        # only wants other providers
        try:
            import openai  # type: ignore
        except ModuleNotFoundError as exc:
            raise ProviderError(
                "The 'openai' package is missing.  Install with: pip install openai"
            ) from exc

        super().__init__(model, temperature, timeout)
        openai.api_key = self._require_env("OPENAI_API_KEY", "OpenAI API key")
        self.client = openai.OpenAI(timeout=timeout)
        self._openai = openai

    # retry for transient network / 429 errors
    @tenacity.retry(
        reraise=True,
        stop=tenacity.stop_after_attempt(5),
        wait=tenacity.wait_exponential(multiplier=1, min=1, max=10),
    )
    def chat(self, history: List[Message], stream: bool = True):
        kwargs = dict(
            model=self.model,
            messages=[m.__dict__ for m in history],
            temperature=self.temperature,
            stream=stream,
        )

        if stream:
            resp = self.client.chat.completions.create(**kwargs)
            for chunk in resp:
                if chunk.choices and chunk.choices[0].delta.content:
                    yield chunk.choices[0].delta.content
        else:
            resp = self.client.chat.completions.create(**kwargs)
            return resp.choices[0].message.content

    def list_models(self) -> List[str]:
        try:
            models = self._openai.models.list()
            return [m.id for m in models.data]
        except Exception as exc:  # pylint: disable=broad-except
            logger.debug("OpenAI list_models failed: %s", exc)
            return [
                "gpt-4o",
                "gpt-4-turbo",
                "gpt-3.5-turbo",
            ]


# --------------------------------------------------------------------------- #
# Anthropic implementation
# --------------------------------------------------------------------------- #
class AnthropicProvider(BaseProvider):
    name = "anthropic"
    default_system_prompt = (
        "You are a helpful assistant complying fully with the user's requests."
    )

    def __init__(self, model: str, temperature: float, timeout: int):
        try:
            import anthropic  # type: ignore
        except ModuleNotFoundError as exc:
            raise ProviderError(
                "The 'anthropic' package is missing.  Install with: pip install anthropic"
            ) from exc

        super().__init__(model, temperature, timeout)
        # reads env if api_key omitted
        self.client = anthropic.Anthropic(
            api_key=self._require_env("ANTHROPIC_API_KEY", "Anthropic API key"),
            timeout=timeout,
        )
        self._anthropic = anthropic

    @tenacity.retry(
        reraise=True,
        stop=tenacity.stop_after_attempt(5),
        wait=tenacity.wait_exponential(multiplier=1, min=1, max=10),
    )
    def chat(self, history: List[Message], stream: bool = True):
        # Convert to Claude message schema
        messages = [{"role": m.role, "content": m.content} for m in history]

        kwargs: Dict[str, object] = dict(
            model=self.model,
            messages=messages,
            temperature=self.temperature,
            stream=stream,
        )

        if stream:
            resp = self.client.messages.create(**kwargs)
            for chunk in resp:
                # chunk.delta == {"text": "..."} when there is content
                if getattr(chunk, "delta", None) and chunk.delta.get("text"):
                    yield chunk.delta["text"]
        else:
            resp = self.client.messages.create(**kwargs)
            return resp.content[0]["text"]

    def list_models(self) -> List[str]:
        try:
            import requests  # lazy
            resp = requests.get(
                "https://api.anthropic.com/v1/models",
                headers={
                    "x-api-key": self._require_env(
                        "ANTHROPIC_API_KEY", "Anthropic API key"
                    ),
                    "anthropic-version": "2023-06-01",
                },
                timeout=self.timeout,
            )
            if resp.status_code == 200:
                payload = resp.json()
                return [m["id"] for m in payload.get("models", [])]
        except Exception as exc:  # pylint: disable=broad-except
            logger.debug("Anthropic list_models failed: %s", exc)
        # fallback
        return [
            "claude-3-opus-20240229",
            "claude-3-sonnet-20240229",
            "claude-3-haiku-20240307",
        ]


# --------------------------------------------------------------------------- #
# Google Gemini implementation
# --------------------------------------------------------------------------- #
class GeminiProvider(BaseProvider):
    name = "google"
    supports_streaming = False  # streaming still rolling out

    def __init__(self, model: str, temperature: float, timeout: int):
        try:
            from google import genai  # type: ignore
        except ModuleNotFoundError as exc:
            raise ProviderError(
                "The 'google-genai' package is missing.  Install with: pip install google-genai"
            ) from exc

        super().__init__(model, temperature, timeout)
        self.client = genai.Client(
            api_key=self._require_env("GOOGLE_API_KEY", "Google API key"),
            timeout=timeout,
        )
        self._genai = genai

        # One chat session per CLI run keeps context automatically
        try:
            self.chat_session = self.client.chats.create(model=self.model)
        except Exception as exc:  # pylint: disable=broad-except
            raise ProviderError(
                f"Failed to create Gemini chat. Model '{self.model}' available?"
            ) from exc

    # Gemini Flash/Ultra currently do not stream via SDK (subject to change)
    @tenacity.retry(
        reraise=True,
        stop=tenacity.stop_after_attempt(5),
        wait=tenacity.wait_exponential(multiplier=1, min=1, max=10),
    )
    def chat(self, history: List[Message], stream: bool = True):
        # Append user message only; the chat_session preserves history
        prompt = history[-1].content

        reply = self.chat_session.send_message(
            prompt,
            temperature=self.temperature,
        )
        return reply.text  # not iterable

    def list_models(self) -> List[str]:
        try:
            models = self.client.models.list()
            # resource names look like "publishers/google/models/gemini-2.0-flash-001"
            return [m.name.split("/")[-1] for m in models]
        except Exception as exc:  # pylint: disable=broad-except
            logger.debug("Gemini list_models failed: %s", exc)
            return [
                "gemini-2.0-flash-001",
                "gemini-2.0-ultra-001",
                "gemini-1.5-pro",
            ]


# --------------------------------------------------------------------------- #
# Provider registry
# --------------------------------------------------------------------------- #
PROVIDERS = {
    OpenAIProvider.name: OpenAIProvider,
    AnthropicProvider.name: AnthropicProvider,
    GeminiProvider.name: GeminiProvider,
}

# --------------------------------------------------------------------------- #
# CLI parsing
# --------------------------------------------------------------------------- #
def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="ai-chat",
        description="Chat with OpenAI, Claude, or Gemini from your terminal.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )

    parser.add_argument(
        "-p",
        "--provider",
        choices=sorted(PROVIDERS.keys()),
        default=os.getenv("AI_CHAT_DEFAULT_PROVIDER", "openai"),
        help="which AI provider to use",
    )
    parser.add_argument(
        "-m",
        "--model",
        default=os.getenv("AI_CHAT_DEFAULT_MODEL", "gpt-4o"),
        help="model ID to use (provider-specific)",
    )
    parser.add_argument(
        "-t",
        "--temperature",
        type=float,
        default=0.7,
        help="randomness (0-2)",
    )
    parser.add_argument("--timeout", type=int, default=60, help="HTTP timeout in seconds")

    parser.add_argument(
        "--list-models",
        action="store_true",
        help="list available model IDs for the chosen provider and exit",
    )
    parser.add_argument(
        "--no-stream",
        action="store_true",
        help="disable token streaming even if the provider supports it",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="enable verbose logging (includes tracebacks)",
    )

    return parser


def initialise_autocomplete(parser: argparse.ArgumentParser) -> None:
    if argcomplete is None:
        return
    # Provide dynamic completion for models when --provider precedes --model
    def model_completer(**_kwargs):  # kwargs: completer params unused
        # read already typed args from sys.argv for provider hint
        try:
            provider_idx = sys.argv.index("-p")
        except ValueError:
            try:
                provider_idx = sys.argv.index("--provider")
            except ValueError:
                return []
        if provider_idx + 1 < len(sys.argv):
            provider_name = sys.argv[provider_idx + 1]
            provider_cls = PROVIDERS.get(provider_name)
            if provider_cls:
                try:
                    return provider_cls("dummy", 0.0, 5).list_models()
                except ProviderError:
                    return []
        return []

    # attach completer only if argcomplete present
    parser.add_argument("--_dummy-complete-models", help=argparse.SUPPRESS).completer = (
        model_completer
    )
    argcomplete.autocomplete(parser)


# --------------------------------------------------------------------------- #
# Interactive loop
# --------------------------------------------------------------------------- #
def interactive_chat(
    client: BaseProvider, stream: bool, debug: bool = False
) -> None:  # noqa: C901
    console.print(
        f"[bold green]✔ Connected to {client.name}[/] "
        f"(model: {client.model}).  Type 'exit' or Ctrl-D to quit.\n"
    )
    history: List[Message] = []

    if client.default_system_prompt:
        history.append(Message(role="system", content=client.default_system_prompt))

    try:
        while True:
            try:
                user_text = console.input("[bold cyan]You > [/]")
            except (EOFError, KeyboardInterrupt):
                console.print("\n[bold yellow]Session ended.[/]")
                break

            if user_text.strip().lower() in {"exit", "quit", ":q"}:
                break
            if not user_text.strip():
                continue

            history.append(Message(role="user", content=user_text))

            try:
                if stream and client.supports_streaming:
                    reply_chunks = client.chat(history, stream=True)
                    assistant_text = ""
                    console.print("[bold magenta]AI > [/]", end="")
                    for chunk in reply_chunks:  # type: ignore[assignment]
                        assistant_text += chunk
                        console.print(chunk, end="")
                        console.file.flush()
                    console.print()
                else:
                    assistant_text = client.chat(history, stream=False)  # type: ignore[assignment]
                    console.print(Markdown(f"**AI >** {assistant_text}"))
            except Exception as exc:  # pylint: disable=broad-except
                if debug:
                    raise
                console.print(f"[bold red]✘ {exc}[/]")
                logger.debug("Chat error: %s", exc)
                continue

            history.append(Message(role="assistant", content=assistant_text))
    except ProviderError as exc:
        console.print(f"[bold red]{exc}[/]")


# --------------------------------------------------------------------------- #
# Main entry
# --------------------------------------------------------------------------- #
def main() -> None:
    # Optionally load .env if python-dotenv installed
    if load_dotenv is not None:
        load_dotenv()  # quietly ignore if no file

    parser = build_arg_parser()
    initialise_autocomplete(parser)
    args = parser.parse_args()

    # enable debug logging if requested
    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)

    # pick provider class
    provider_cls = PROVIDERS.get(args.provider)
    if not provider_cls:
        console.print(f"[bold red]Unknown provider: {args.provider}[/]")
        sys.exit(1)

    # Handle --list-models early
    if args.list_models:
        try:
            prov = provider_cls(args.model, args.temperature, args.timeout)
            models = prov.list_models()
            console.print(
                Markdown(
                    f"### Available models for **{prov.name}** "
                    f"(API key: {'found' if models else 'missing/unauthorised'})"
                )
            )
            for m in models:
                console.print(f"- {m}")
        except ProviderError as exc:
            console.print(f"[bold red]✘ {exc}[/]")
            sys.exit(1)
        sys.exit(0)

    # Construct provider client
    try:
        client = provider_cls(args.model, args.temperature, args.timeout)
    except ProviderError as exc:
        console.print(f"[bold red]✘ {exc}[/]")
        sys.exit(1)

    # Launch REPL
    interactive_chat(client, stream=not args.no_stream, debug=args.debug)


# --------------------------------------------------------------------------- #
if __name__ == "__main__":
    try:
        main()
    except ProviderError as err:
        console.print(f"[bold red]✘ {err}[/]")
        sys.exit(1)
