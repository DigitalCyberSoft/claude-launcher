Name:           claude-launcher
Version:        0.1.0
Release:        1%{?dist}
Summary:        Menu front-end that becomes the primary `claude`, wrapping Claude Code

License:        MIT
URL:            https://github.com/DigitalCyberSoft/claude-launcher
Source0:        claude-launcher
Source1:        README.md
Source2:        LICENSE

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

Providers beyond Anthropic (Moonshot/Kimi, DeepSeek, Qwen, OpenAI, Grok)
are supported by routing the same binary through the appropriate endpoint
or a per-session LiteLLM proxy.

%prep
# Nothing to unpack; sources are installed directly.
cp -p %{SOURCE0} .
cp -p %{SOURCE1} .
cp -p %{SOURCE2} .

%install
install -D -m 0755 %{SOURCE0} %{buildroot}%{_bindir}/claude
install -D -m 0644 %{SOURCE1} %{buildroot}%{_datadir}/doc/%{name}/README.md
install -D -m 0644 %{SOURCE2} %{buildroot}%{_datadir}/licenses/%{name}/LICENSE

%files
%{_bindir}/claude
%doc %{_datadir}/doc/%{name}/README.md
%license %{_datadir}/licenses/%{name}/LICENSE

%post
# On a fresh system with no Claude Code yet, the first `claude` invocation
# offers to install one. Nothing to do here.
:

%changelog
* Wed Aug 05 2026 DigitalCyberSoft <claude@dcs.io> - 0.1.0-1
- Initial package: installs the launcher as /usr/bin/claude (primary
  `claude`), wrapping and discovering the real Claude Code build
- `claude install` opens the build chooser (native latest / specific
  version / npm user / npm system / switch active build)
- find_real_claude never resolves to a launcher (signature check), so the
  wrapper never execs itself
