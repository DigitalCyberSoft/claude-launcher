Name:           claude-launcher
Version:        0.4.0
Release:        1%{?dist}
Summary:        Menu front-end that becomes the primary `claude`, wrapping Claude Code

License:        MIT
URL:            https://github.com/DigitalCyberSoft/claude-launcher
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildArch:      noarch

# Runtime tools the launcher itself uses. Claude Code is intentionally NOT
# a dependency: the launcher discovers an existing native/npm install and,
# via `claude install`, can install or switch builds on demand.
Requires:       bash
Requires:       coreutils
Requires:       /usr/bin/curl
Requires:       jq

# Owns the `claude` command name. There is no distribution `claude`
# package to conflict with; a user-level native install under
# ~/.local/bin still takes precedence in a typical user PATH, and the
# launcher discovers and wraps it either way.
Provides:       claude = %{version}-%{release}

%description
claude-launcher is a single Bash front-end for Claude Code. Installed as
/usr/bin/claude, it becomes the primary `claude` on the system: with no
arguments it shows an arrow-key menu (fresh / continue / resume sessions,
provider, model, effort, per-run toggles), and it execs the real Claude
Code binary underneath with the chosen environment and flags applied.

It never runs itself: it discovers the real Claude Code build (a native
install under ~/.local/share/claude/versions, or an npm install) and, when
none is present or when you run `claude install`, offers to install or
switch between the native and npm builds, including pinning older
versions. Switching a build only repoints the launcher's config; it never
touches ~/.claude (settings, sessions, credentials) or the launcher's own
configuration under ~/.config/claude-launcher.

Providers beyond Anthropic (Moonshot/Kimi, DeepSeek, Qwen, OpenAI, Grok,
OpenRouter) are supported by routing the same binary through the
appropriate endpoint or a per-session LiteLLM proxy. A global bash
completion for `claude` is installed as well.

%prep
%autosetup -n %{name}-%{version}

%install
install -D -m 0755 claude-launcher %{buildroot}%{_bindir}/claude
# Global bash completion for `claude`; loads automatically for interactive
# shells (no ~/.bashrc sourcing needed).
install -D -m 0644 completions/claude.bash \
    %{buildroot}%{_datadir}/bash-completion/completions/claude
install -D -m 0644 README.md %{buildroot}%{_datadir}/doc/%{name}/README.md
install -D -m 0644 LICENSE %{buildroot}%{_datadir}/licenses/%{name}/LICENSE

%files
%{_bindir}/claude
%{_datadir}/bash-completion/completions/claude
%doc %{_datadir}/doc/%{name}/README.md
%license %{_datadir}/licenses/%{name}/LICENSE

%changelog
* Mon Nov 09 2026 DigitalCyberSoft <claude@dcs.io> - 0.4.0-1
- Drop the claude.ai-only Artifact tool family (--disallowedTools) on every
  third-party launch: it cannot work without the claude.ai connector, and
  DeepSeek 400s the whole request over its schema pattern. New per-conf
  disallowed_tools field for tools a specific endpoint rejects
- Models: claude-opus-5-5 (new default), claude-fable-5-1,
  claude-sonnet-5-5, claude-haiku-5-5; kimi-k3.1-pro(+highspeed);
  qwen3.8-flash; gpt-6-astra, gpt-6.1-sol/terra, gpt-6-sol/luna,
  gpt-5.6-terra/luna; grok-4.7, grok-4.6; OpenRouter stealth/crouton-alpha
  (ox-alpha retired), claude-opus-5.5, gpt-6-astra, gemini-4-argon
- OpenAI context pinned to the 922000-token input maximum, not the 1.05M
  window that includes output, so long sessions stay within limits
- Moonshot gains a context_map fallback so a model newer than the cached
  listing no longer falls back to Claude Code's 200K default

* Thu Sep 10 2026 DigitalCyberSoft <claude@dcs.io> - 0.3.0-1
- DeepSeek: follow the flash rename to `deepseek-flash` (DeepSeek-V4.1-
  Flash, which also carries vision); the retired `deepseek-v4-flash` alias
  is kept in context_map so state that still remembers it keeps working
- DeepSeek's K is 1024, not 1000: their API reference bounds max_tokens at
  "between 1 and 384K (393216)", so the output cap is 393216 (was 384000)
  and 1M context is 1048576 (was 1000000)
- Fix a model with no context_map entry getting NO context pin at all:
  selecting the newly-named deepseek-flash left Claude Code on its 200000
  fallback with no [1m] suffix. The picker discovers new model ids
  automatically, but their limits are declared per model
- Wire the xhigh effort level. `ultra` is accepted by DeepSeek's endpoint
  but rejected by Claude Code, which silently falls back to the default
  effort, so it is deliberately left out
- completions/README: track the renamed DeepSeek id

* Fri Aug 21 2026 DigitalCyberSoft <claude@dcs.io> - 0.2.0-1
- Add OpenRouter provider over its native Anthropic-compatible "skin"
  (direct endpoint, no proxy); pins ANTHROPIC_API_KEY empty so an
  Anthropic key cannot leak to a third-party host
- Seed stealth/ox-alpha and auto-surface cloaked "stealth/*" models as
  new models via the /api/v1/models catalog refresh
- write_efforts_map reads OpenRouter reasoning.supported_efforts, so
  per-model effort levels are honored (ox-alpha: low/high/max only)

* Wed Aug 05 2026 DigitalCyberSoft <claude@dcs.io> - 0.1.0-1
- Initial package: installs the launcher as /usr/bin/claude (primary
  `claude`), wrapping and discovering the real Claude Code build
- `claude install` opens the build chooser (native latest / specific
  version / npm user / npm system / switch active build)
- find_real_claude never resolves to a launcher (signature check), so the
  wrapper never execs itself
- Ships global bash completion for `claude`
  (/usr/share/bash-completion/completions/claude), refreshed to 2.1.222
  flags/subcommands and completing the launcher's provider model ids
