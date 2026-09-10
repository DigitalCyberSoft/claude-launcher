# Bash completion for `claude` (the claude-launcher front-end, which wraps
# and passes through to Claude Code).
#
# Flags and subcommands re-derived from `claude --help` and per-subcommand
# help on Claude Code 2.1.222. Re-derive when the CLI gains new flags or
# subcommands (`claude --help`, and each `claude <sub> --help`).
#
# Installed globally by the claude-launcher RPM into
# /usr/share/bash-completion/completions/claude, so it loads automatically
# for interactive shells with no ~/.bashrc sourcing.

_claude_top_flags='
--add-dir --agent --agents --allow-dangerously-skip-permissions
--allowed-tools --allowedTools --append-system-prompt --autocompact
--ax-screen-reader --background --bare --betas --bg --brief --chrome
--continue -c --dangerously-skip-permissions --debug -d --debug-file
--disable-slash-commands --disallowed-tools --disallowedTools --effort
--exclude-dynamic-system-prompt-sections --fallback-model --file
--fork-session --forward-subagent-text --from-pr --help -h --ide
--include-hook-events --include-partial-messages --input-format
--json-schema --max-budget-usd --mcp-config --model --name -n --no-chrome
--no-session-persistence --output-format --permission-mode --plugin-dir
--plugin-url --print -p --prompt-suggestions --remote-control
--remote-control-session-name-prefix --replay-user-messages --resume -r
--safe-mode --session-id --setting-sources --settings --strict-mcp-config
--system-prompt --tmux --tools --verbose -v --version --worktree -w
'

_claude_subcommands='agents auth auto-mode doctor gateway import install mcp plugin plugins project setup-token ultrareview update upgrade'

# Model aliases and provider model ids the launcher understands. Anthropic
# aliases plus the seeded third-party models; [1m] variants are offered for
# the 1M-context ids. Extend as providers are added.
_claude_models='
sonnet opus haiku
claude-opus-4-8[1m] claude-opus-5 claude-sonnet-5 claude-fable-5[1m]
claude-haiku-4-5
kimi-k3 kimi-k3[1m] kimi-k2.7-code
deepseek-v4-pro deepseek-v4-pro[1m] deepseek-flash deepseek-flash[1m]
qwen3.8-max qwen3.8-max[1m] qwen3.7-max qwen3.7-plus
gpt-5.6-sol gpt-5.6-sol[1m] gpt-5.3-codex
grok-4.5 grok-4.3 grok-4.3[1m] grok-build-0.1
'

_claude() {
    local cur prev i
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "$prev" in
        --effort)
            COMPREPLY=( $(compgen -W "low medium high xhigh max" -- "$cur") )
            return ;;
        --input-format)
            COMPREPLY=( $(compgen -W "text stream-json" -- "$cur") )
            return ;;
        --output-format)
            COMPREPLY=( $(compgen -W "text json stream-json" -- "$cur") )
            return ;;
        --permission-mode)
            COMPREPLY=( $(compgen -W "acceptEdits auto bypassPermissions default dontAsk plan" -- "$cur") )
            return ;;
        --model|--fallback-model)
            COMPREPLY=( $(compgen -W "$_claude_models" -- "$cur") )
            return ;;
        --setting-sources)
            COMPREPLY=( $(compgen -W "user project local" -- "$cur") )
            return ;;
        --tmux)
            COMPREPLY=( $(compgen -W "classic" -- "$cur") )
            return ;;
        -t|--transport)
            COMPREPLY=( $(compgen -W "stdio sse http" -- "$cur") )
            return ;;
        -s|--scope)
            COMPREPLY=( $(compgen -W "local user project managed" -- "$cur") )
            return ;;
        --debug-file|--settings|--json-schema|--system-prompt|--append-system-prompt|--mcp-config|--file)
            COMPREPLY=( $(compgen -f -- "$cur") )
            return ;;
        --add-dir|--plugin-dir)
            COMPREPLY=( $(compgen -d -- "$cur") )
            return ;;
        --agent|--agents|--betas|--name|-n|--max-budget-usd|--session-id|--remote-control-session-name-prefix|--debug|-d|--from-pr|--resume|-r|--callback-port|--client-id|-e|--env|-H|--header|--message|-m|--remote|--sparse|--email|--tools|--allowedTools|--allowed-tools|--disallowedTools|--disallowed-tools|--worktree|-w|--plugin-url)
            return ;;
    esac

    local sub1="" sub2="" sub3=""
    for (( i=1; i<COMP_CWORD; i++ )); do
        local w="${COMP_WORDS[i]}"
        case "$w" in
            -*) continue ;;
            *)
                if [[ -z "$sub1" ]]; then
                    sub1="$w"
                elif [[ -z "$sub2" ]]; then
                    sub2="$w"
                elif [[ -z "$sub3" ]]; then
                    sub3="$w"
                fi
                ;;
        esac
    done

    if [[ -z "$sub1" ]]; then
        if [[ "$cur" == -* ]]; then
            COMPREPLY=( $(compgen -W "$_claude_top_flags" -- "$cur") )
        else
            COMPREPLY=( $(compgen -W "$_claude_subcommands" -- "$cur") )
        fi
        return
    fi

    case "$sub1" in
        agents)
            [[ "$cur" == -* ]] && COMPREPLY=( $(compgen -W "--help -h --setting-sources" -- "$cur") )
            return ;;
        auth)
            _claude_auth "$sub2"
            return ;;
        auto-mode)
            _claude_auto_mode "$sub2"
            return ;;
        doctor|setup-token|update|upgrade|gateway|project)
            COMPREPLY=( $(compgen -W "--help -h" -- "$cur") )
            return ;;
        import)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "--help -h" -- "$cur") )
            else
                COMPREPLY=( $(compgen -f -- "$cur") )
            fi
            return ;;
        ultrareview)
            COMPREPLY=( $(compgen -W "--help -h" -- "$cur") )
            return ;;
        install)
            # claude-launcher intercepts `claude install` to a build chooser;
            # the same targets the native installer accepts are valid inputs.
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "--force --help -h" -- "$cur") )
            elif [[ -z "$sub2" ]]; then
                COMPREPLY=( $(compgen -W "stable latest" -- "$cur") )
            fi
            return ;;
        mcp)
            _claude_mcp "$sub2"
            return ;;
        plugin|plugins)
            _claude_plugin "$sub2" "$sub3"
            return ;;
    esac
}

_claude_auth() {
    local sub2="$1"
    if [[ -z "$sub2" ]]; then
        if [[ "$cur" == -* ]]; then
            COMPREPLY=( $(compgen -W "--help -h" -- "$cur") )
        else
            COMPREPLY=( $(compgen -W "help login logout status" -- "$cur") )
        fi
        return
    fi
    case "$sub2" in
        login)
            COMPREPLY=( $(compgen -W "--claudeai --console --email --sso --help -h" -- "$cur") ) ;;
        status)
            COMPREPLY=( $(compgen -W "--json --text --help -h" -- "$cur") ) ;;
        logout|help)
            COMPREPLY=( $(compgen -W "--help -h" -- "$cur") ) ;;
    esac
}

_claude_auto_mode() {
    local sub2="$1"
    if [[ -z "$sub2" ]]; then
        if [[ "$cur" == -* ]]; then
            COMPREPLY=( $(compgen -W "--help -h" -- "$cur") )
        else
            COMPREPLY=( $(compgen -W "config critique defaults help" -- "$cur") )
        fi
        return
    fi
    case "$sub2" in
        critique)
            COMPREPLY=( $(compgen -W "--model --help -h" -- "$cur") ) ;;
        config|defaults|help)
            COMPREPLY=( $(compgen -W "--help -h" -- "$cur") ) ;;
    esac
}

_claude_mcp() {
    local sub2="$1"
    if [[ -z "$sub2" ]]; then
        if [[ "$cur" == -* ]]; then
            COMPREPLY=( $(compgen -W "--help -h" -- "$cur") )
        else
            COMPREPLY=( $(compgen -W "add add-from-claude-desktop add-json get help list remove reset-project-choices serve" -- "$cur") )
        fi
        return
    fi
    case "$sub2" in
        add)
            COMPREPLY=( $(compgen -W "--callback-port --client-id --client-secret -e --env -H --header -h --help -s --scope -t --transport" -- "$cur") ) ;;
        add-from-claude-desktop)
            COMPREPLY=( $(compgen -W "-h --help -s --scope" -- "$cur") ) ;;
        add-json)
            COMPREPLY=( $(compgen -W "--client-secret -h --help -s --scope" -- "$cur") ) ;;
        remove)
            COMPREPLY=( $(compgen -W "-h --help -s --scope" -- "$cur") ) ;;
        serve)
            COMPREPLY=( $(compgen -W "-d --debug -h --help --verbose" -- "$cur") ) ;;
        get|list|reset-project-choices|help)
            COMPREPLY=( $(compgen -W "-h --help" -- "$cur") ) ;;
    esac
}

_claude_plugin() {
    local sub2="$1" sub3="$2"
    if [[ -z "$sub2" ]]; then
        if [[ "$cur" == -* ]]; then
            COMPREPLY=( $(compgen -W "--help -h" -- "$cur") )
        else
            COMPREPLY=( $(compgen -W "disable enable help i install list marketplace remove tag uninstall update validate" -- "$cur") )
        fi
        return
    fi
    case "$sub2" in
        marketplace)
            if [[ -z "$sub3" ]]; then
                if [[ "$cur" == -* ]]; then
                    COMPREPLY=( $(compgen -W "--help -h" -- "$cur") )
                else
                    COMPREPLY=( $(compgen -W "add help list remove rm update" -- "$cur") )
                fi
                return
            fi
            case "$sub3" in
                add)
                    COMPREPLY=( $(compgen -W "-h --help --scope --sparse" -- "$cur") ) ;;
                list)
                    COMPREPLY=( $(compgen -W "-h --help --json" -- "$cur") ) ;;
                remove|rm|update|help)
                    COMPREPLY=( $(compgen -W "-h --help" -- "$cur") ) ;;
            esac
            ;;
        disable)
            COMPREPLY=( $(compgen -W "-a --all -h --help -s --scope" -- "$cur") ) ;;
        enable|install|i|update)
            COMPREPLY=( $(compgen -W "-h --help -s --scope" -- "$cur") ) ;;
        uninstall|remove)
            COMPREPLY=( $(compgen -W "-h --help --keep-data -s --scope" -- "$cur") ) ;;
        list)
            COMPREPLY=( $(compgen -W "--available -h --help --json" -- "$cur") ) ;;
        tag)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "--dry-run -f --force -h --help -m --message --push --remote" -- "$cur") )
            else
                COMPREPLY=( $(compgen -d -- "$cur") )
            fi
            ;;
        validate)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "-h --help" -- "$cur") )
            else
                COMPREPLY=( $(compgen -f -- "$cur") )
            fi
            ;;
    esac
}

complete -F _claude claude
