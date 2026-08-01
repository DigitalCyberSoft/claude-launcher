# claude-launcher

An arrow-key menu front-end for [Claude Code](https://claude.com/product/claude-code) that remembers your model, effort level, and provider, launches fresh/continue/resume sessions, and routes the same Claude Code binary to Anthropic, Moonshot (Kimi), OpenAI, or Grok.

Run `claude` with no arguments and you get a menu. Run it with arguments and it passes straight through to the real binary with your remembered settings applied, so `claude -c`, `claude -p '...'`, and `claude mcp ...` keep working exactly as before.

```
  Start fresh
  Continue        refactor the auth module        (2h ago)
  Resume          fix flaky pty test              (yesterday)
  ──────────────────────────────────────────────────────────
  provider    [anthropic] · grok · moonshot · openai
  model       claude-opus-4-8[1m]
  effort      max
  hooks       on · PreToolUse, SessionStart, statusline, 2 plugins
  ...
  anthropic: 5h:82% left · 7d:78% left · $41.20 extra used
```

It is a single Bash script with no dependencies beyond `bash`, `curl`, and `jq`. Nothing is written into the repo; all state lives under `~/.config/claude-launcher`.

---

## Why

Claude Code is one binary, but day to day you want to:

- start a fresh session, continue the last one, or resume a specific older one, **without** remembering flags or session IDs;
- pin a model and effort level and have them stick, per provider;
- point the same binary at a different vendor (Kimi, GPT, Grok) for a session and switch back;
- turn hooks, a custom system prompt, or safe mode on or off for one run;
- see how much of your rate limit or balance is left before you start.

`claude-launcher` puts all of that on one screen and applies the correct, often non-obvious, environment and flags underneath.

---

## Install

Requirements: `bash`, `curl`, `jq`, and Claude Code already installed (`claude` on your `PATH`).

```sh
git clone https://github.com/DigitalCyberSoft/claude-launcher.git
cd claude-launcher

# Point your existing `claude` alias (or a new one) at the script:
echo "alias claude='$PWD/claude-launcher'" >> ~/.bashrc
source ~/.bashrc
```

First run seeds `~/.config/claude-launcher` with a config file, provider definitions, a status line, and a LiteLLM proxy config. Nothing outside that directory is touched until you actually launch a session.

Try it without launching anything:

```sh
CLAUDE_LAUNCHER_DRY_RUN=1 claude      # prints the exact command it would run
```

---

## Menu

On a terminal the menu is an arrow-key TUI rendered inline below your shell prompt. It uses no alternate screen: it redraws in place and erases itself on exit, so your scrollback is left intact. Selection is reverse-video, accents are colorblind-safe, and `NO_COLOR` is honored.

```
up/down     move between rows
left/right  change the value in place (provider, model, effort, toggles);
            providers whose API key env var is unset are skipped and
            marked "needs $VAR"
enter       launch (Start fresh / Continue / Resume rows) or open the
            row's full picker (provider, model)
q / esc     back out of a picker; q on the main menu quits
```

Over a pipe or a dumb terminal it falls back to a plain line menu with the same single-key shortcuts:

```
[enter/f] fresh   [c] continue   [r] resume picker
[p] provider   [m] model (o = free text, x = enable/disable)
[e] effort   [u] refresh models
[h] hooks    [s] system prompt   [v] safe mode
[q] quit
```

Your provider, model, effort, toggles, and per-model disables persist in `~/.config/claude-launcher/state`. Out of the box the defaults are Anthropic, `claude-opus-4-8[1m]`, effort `max`, hooks on, system prompt off, safe mode off.

### Sessions

The **Continue** row shows the title and age of the session `--continue` would resume (it is scoped to the current directory) and is hidden when the directory has no sessions. Below it, up to the next three sessions appear as direct **Resume** rows that launch `claude --resume=<session-id>`. An "All sessions" picker appears only when more sessions exist than are shown, and the whole Resume group is hidden when Continue already covers the only session.

Titles come from the `ai-title` records in `~/.claude/projects/<cwd>/*.jsonl`. The header line repeats this directory's last session, or, when there is none, the newest session anywhere, labeled with its project and marked "not continuable here".

### Models

The main screen lists every configured provider on one line, the current one bracketed and keyless ones annotated (`moonshot (needs $KIMI_API_KEY)`). In the model picker, `x` on the highlighted model toggles it disabled inline (shown dimmed with a `✗` and skipped when cycling); selecting a disabled model re-enables it. Free-text entry is always the last row, and the Model row shows `· N hidden` when the current provider has disabled models.

---

## Providers

| Provider | How it connects | Auth env var |
|---|---|---|
| **anthropic** | Native API, your normal Claude Code login, no env changes | (login) |
| **moonshot** | Kimi over the [documented Anthropic-compatible endpoint](https://platform.kimi.ai/docs/guide/claude-code-kimi) `https://api.moonshot.ai/anthropic` | `KIMI_API_KEY` |
| **openai** | Through a local [LiteLLM](https://docs.litellm.ai) proxy (OpenAI serves no Anthropic-compatible endpoint) | `OPENAI_API_KEY` |
| **grok** | Through the same LiteLLM proxy (xAI serves no Anthropic-compatible endpoint) | `XAI_API_KEY` |

For any third-party provider the launcher exports `ANTHROPIC_BASE_URL`, the auth token, `ANTHROPIC_MODEL`, and `ANTHROPIC_DEFAULT_HAIKU_MODEL` (so background and haiku-class calls stay on that provider), and **strips `ANTHROPIC_API_KEY` / `ANTHROPIC_AUTH_TOKEN` from the environment** so your Anthropic credential is never sent to another host.

`openai` and `grok` are deliberately separate menu entries rather than a single "litellm" one, so you pick the end vendor and model, not the plumbing. Each carries its own model list, its own vendor key check, and a `models_filter` regex so proxy-wide model discovery sorts new IDs to the right vendor.

### LiteLLM proxy (for OpenAI / Grok only)

```sh
pip install 'litellm[proxy]'
litellm --config ~/.config/claude-launcher/litellm.yaml   # needs OPENAI_API_KEY / XAI_API_KEY
```

The launcher checks the proxy is reachable before launching and prints the start command if it is not. Anthropic and Moonshot need no proxy.

### Adding a provider

Copy `~/.config/claude-launcher/providers/custom.conf.example` to `<id>.conf`. Any host with an Anthropic-compatible API works with no proxy; the example lists ready-to-use DeepSeek, Z.ai, and MiniMax endpoints.

---

## Effort matching

`--effort` is passed only at levels the selected model actually supports, and a saved effort above a model's ceiling is clamped to its highest supported level. A model with no effort support gets no `--effort` at all. A provider conf declares its supported set one of three ways:

- **`efforts="detect"`** (anthropic, moonshot): read per model from the live models listing at refresh time. Anthropic uses the listing's `capabilities.effort` flags; Moonshot uses `reasoning_efforts.valid_efforts` (e.g. `kimi-k3` supports low/high/max, the `kimi-k2.x` models support none).
- **`efforts="map"`** (openai, grok): per-model sets declared in the conf's `efforts_map`, because these vendors' model listings carry no effort metadata. A model absent from the map gets no `--effort` — safer than guessing, because OpenAI and xAI return HTTP 400 on an unsupported effort value.
- **A fixed list** (`efforts="low medium high"`) or **none** (`efforts=""`).

Cycling the effort row in the menu moves through the supported set only.

> **OpenAI / Grok caveat.** Effort only reaches these models if your LiteLLM proxy forwards Claude Code's `output_config.effort` to the vendor's `reasoning_effort`. Current LiteLLM does this; some pinned or older releases silently drop it and default every request to `medium`. The menu is correct either way; this only governs whether the chosen level actually lands. See the header comment in `litellm.yaml`.

---

## Context window and output cap

These are two different limits, and the launcher sets them independently.

**Context window (input).** For `auto_1m=1` providers, a model ID with no `[...]` suffix gets `[1m]` appended when its context window is at least 1M tokens, so it runs at the full window (the `[1m]` suffix is a Claude Code feature). Explicit suffixes always win. For third-party providers the launcher also exports `CLAUDE_CODE_MAX_CONTEXT_TOKENS` and `CLAUDE_CODE_AUTO_COMPACT_WINDOW` so auto-compaction fires at the model's real window. Without this, Claude Code assumes a 200K window for any non-`claude-*` model ID it doesn't recognize and compacts there — which is why, for example, a 1M-context Kimi model would otherwise start compacting at 200K. Native `claude-*` IDs are left alone; Claude Code's own registry already has their correct window.

**Output cap.** The `max_output_tokens` field in a conf sets `CLAUDE_CODE_MAX_OUTPUT_TOKENS`, raising Claude Code's request `max_tokens` to the model's real ceiling. Claude Code otherwise defaults to a lower value for models it doesn't have registered. This is independent of `[1m]`: the suffix changes the input window, never the output cap.

Where the numbers come from: Anthropic listings carry `max_input_tokens` and Moonshot's carry `context_length`, both cached at refresh. OpenAI's and xAI's listings carry neither, so their confs declare each model's window in a `context_map` taken from vendor docs.

---

## Selective hooks

The **hooks** row's left/right flips a master toggle. Off passes `--settings '{"disableAllHooks":true}'`, which disables all hooks, plugin hooks, and the status line together. Pressing enter opens a per-event editor where individual events (PreToolUse, SessionStart, ...) can be skipped while the rest stay on.

Claude Code has no built-in per-event switch, so the launcher gates your own hook commands. On first use it backs up `~/.claude/settings.json` to `settings.json.bak-launcher` and prefixes each hook command with:

```sh
[ -n "${CLAUDE_HOOK_SKIP_<EVENT>:-}" ] && exit 0;
```

then exports the matching variable only for runs where you asked to skip that event. Wrapped hooks behave identically when the variable is unset. Plugin hooks and the status line have no wrappable command and follow the master toggle only. The hooks row names what it governs, read from your user and project settings.

---

## Status line

The launcher seeds `~/.config/claude-launcher/statusline.sh`, a status line matching Claude Code's own segments (model, context tokens with a red mark past 90%, 5h/7d rate limits) plus one account-data segment for the active provider — Moonshot balance, or Anthropic usage and credits. It is cached for 15 minutes in `cache/info__<provider>`, the same cache the menu uses.

It is injected via `--settings` for third-party providers only, so on Anthropic your existing `~/.claude/settings.json` status line is used unchanged. With hooks toggled off the status line is suppressed on every provider, because Claude Code's `disableAllHooks` also disables the custom status line.

---

## Other toggles

- **system prompt** (`[s]`): loads a system-prompt file via `--system-prompt-file` (replace) or `--append-system-prompt-file` (append), selected by `system_prompt_mode` in the config. Point `system_prompt_file` in `~/.config/claude-launcher/config` at any Markdown file.
- **safe mode** (`[v]`): passes `--safe-mode`, Claude Code's supported way to run without your `CLAUDE.md` (it also disables skills, plugins, hooks, and MCP servers). There is no narrower per-`CLAUDE.md` switch in Claude Code.

Menu toggles are **not** applied on the pass-through path (`claude <args>`); that path mirrors the plain alias and only injects the remembered model and effort.

---

## Provider account data

A provider conf may define a `provider_info()` function that returns one line, cached 15 minutes and shown both in the menu and the status line:

- **anthropic**: subscription usage — 5h/7d remaining percentages and extra-usage credits — from the same unofficial OAuth endpoint the Claude Code status line uses (`api.anthropic.com/api/oauth/usage`; not in the public API docs, so treat it as breakable, and it is not available to plain API keys).
- **moonshot**: account balance from its documented `/v1/users/me/balance` endpoint.
- **openai / grok**: proxy reachability plus key validity only. OpenAI exposes no balance to normal API keys, and xAI exposes key status only.

---

## Model discovery

On menu start (at most once per 24h) and on demand with `[u]`, the launcher fetches the provider's models endpoint and parses `.data[].id`, which fits both Anthropic- and OpenAI-style listings. The first fetch stores a baseline; models that appear in later fetches are reported as new and added to the suggestion list. Disabling a model with `x` hides it from suggestions but keeps it in the manage view for re-enabling. Anthropic discovery uses `ANTHROPIC_API_KEY` because `GET /v1/models` does not accept the OAuth login.

---

## Files and environment

```
~/.config/claude-launcher/config            launcher config
~/.config/claude-launcher/state             remembered choices
~/.config/claude-launcher/providers/*.conf  provider definitions
~/.config/claude-launcher/cache/            model-discovery baselines, cached account data
~/.config/claude-launcher/litellm.yaml      proxy config for OpenAI/Grok
~/.config/claude-launcher/statusline.sh     seeded status line
```

| Variable | Effect |
|---|---|
| `CLAUDE_LAUNCHER_HOME` | Override the config root (default `~/.config/claude-launcher`) |
| `CLAUDE_LAUNCHER_DRY_RUN=1` | Print the final command instead of executing it |

> **Confs are seeded only when missing.** A launcher update never rewrites an existing conf, so new conf options (`auto_1m`, `max_output_tokens`, `context_map`, `efforts_map`, ...) must be added to old confs by hand, or by deleting the conf and letting it re-seed. Your `state` is never touched by re-seeding.

---

## Notes

Facts about Claude Code flags and endpoints in this tool were verified against **Claude Code 2.1.220**; the header comment in the script records what was checked and how. Behavior may differ on other versions. The Anthropic OAuth usage endpoint and the LiteLLM effort translation are both unofficial and may change.

## License

[MIT](LICENSE)
