# /etc/profile.d/claude-launcher.sh - installed by the claude-launcher RPM.
#
# Make `claude` run the launcher (/usr/bin/claude) in every shell that
# reads /etc/profile.d. A per-user native Claude Code install puts
# ~/.local/bin/claude ahead of /usr/bin in PATH, and every native install
# or update rewrites that symlink, so renaming it does not stick. PATH
# order cannot be fixed from here either: ~/.bashrc prepends ~/.local/bin
# after this file is read. Shell functions resolve before PATH, so this
# wins regardless. The launcher still runs the newest native build
# underneath (find_real_claude).
#
# `command claude` bypasses this and runs whatever PATH resolves.
if [ -x /usr/bin/claude ]; then
    claude() { /usr/bin/claude "$@"; }
fi
