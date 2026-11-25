# Omarchy's shell setup (default/bash: aliases, functions, environment) ported
# to fish, from the setup kit. Omarchy ships bash only. Use fish for your
# terminals with: chsh -s /usr/bin/fish (log out and in again).
#
#   default/bash/fns/*     -> ported into functions/ (all 54 names)
#   default/bash/inputrc   -> readline-only, meaningless in fish

# --- env bootstrap for sessions uwsm did not set up --------------------------
# Inside a Hyprland session, uwsm exports OMARCHY_PATH / PATH / EDITOR before
# anything runs, so this is a no-op. A shell started OUTSIDE that session (ssh,
# a VT login) gets none of it, and fish never reads /etc/profile.d — so mirror
# default/bash/env-bootstrap here. Guarded so the uwsm values always win.

if not set -q OMARCHY_PATH
    # /etc/omarchy.conf is POSIX sh, written by omarchy-dev-link. Absent on a
    # packaged install, where the default is the right answer.
    if test -r /etc/omarchy.conf
        set -l v (sed -n 's/^[[:space:]]*OMARCHY_PATH=//p' /etc/omarchy.conf | tr -d '"\'' | tail -1)
        test -n "$v"; and set -gx OMARCHY_PATH $v
    end
    set -q OMARCHY_PATH; or set -gx OMARCHY_PATH /usr/share/omarchy
end

# Only prepend in dev-link mode; a packaged install already has omarchy-* on
# PATH via /usr/bin. fish_add_path is idempotent, so this cannot accumulate.
if test "$OMARCHY_PATH" != /usr/share/omarchy
    fish_add_path -g -p $OMARCHY_PATH/bin
end
fish_add_path -g -a $HOME/.local/share/mise/shims $HOME/.local/bin

# /etc/profile.d/locale.sh runs for login shells only. Without it an ssh
# session lands in the C locale, where printf emits \u escapes literally.
if not set -q LANG
    if test -r /etc/locale.conf
        for line in (cat /etc/locale.conf)
            string match -qr '^\s*(#|$)' -- $line; and continue
            set -l kv (string split -m1 '=' -- $line)
            test (count $kv) -eq 2; and set -gx $kv[1] (string trim -c '"\'' -- $kv[2])
        end
    end
    set -q LANG; or set -gx LANG C.UTF-8
end

if not status is-interactive
    exit
end

# --- environment -------------------------------------------------------------
# Below the interactive guard on purpose: Omarchy sources default/bash/envs
# from its rc chain, i.e. AFTER bash's own `[[ $- != *i* ]] && return`. That
# layering matters now that fish is the login shell, because sddm's
# wayland-session runs `$SHELL --login -c "sh -c 'export -p'"` and folds the
# result into the session environment. Anything exported non-interactively here
# would leak session-wide -- and BROWSER in particular must not, or xdg-settings
# refuses to change the default browser.

set -q EDITOR; or set -gx EDITOR omarchy-launch-editor --inline
set -gx SUDO_EDITOR $EDITOR
set -gx BROWSER omarchy-launch-browser
set -gx BAT_THEME ansi

# Color man pages with bat
set -gx MANROFFOPT -c
set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"


# Silence fish's built-in "Welcome to fish..." banner. Set globally rather than
# with `set -U`, so it lives in this file instead of the opaque fish_variables
# store. The `quote` block below is the greeting we actually want.
set -g fish_greeting

# --- file system -------------------------------------------------------------
if command -q eza
    alias ls 'eza -lh --group-directories-first --icons=auto'
    alias lsa 'ls -a'
    alias lt 'eza --tree --level=2 --long --icons --git'
    alias lta 'lt -a'
end

# foot is not kitty, so this is the plain-bat preview branch of Omarchy's `ff`
alias ff "fzf --preview 'bat --style=numbers --color=always {}'"

function eff --description 'Edit a fuzzy-picked file'
    set -l file (ff)
    test -n "$file"; and $EDITOR "$file"
end

function sff --description 'scp a fuzzy-picked recent file: sff host:/tmp/'
    if test (count $argv) -eq 0
        echo "Usage: sff <destination> (e.g. sff host:/tmp/)"
        return 1
    end
    set -l file (find . -type f -printf '%T@\t%p\n' | sort -rn | cut -f2- | ff)
    test -n "$file"; and scp "$file" $argv[1]
end

# Omarchy's `zd`: cd normally, fall back to zoxide's frecency database.
if command -q zoxide
    function cd --description 'cd with zoxide fallback'
        if test (count $argv) -eq 0
            builtin cd $HOME
        else if test -d "$argv[1]"
            builtin cd $argv
        else
            if not __zoxide_z $argv
                echo "Error: Directory not found"
                return 1
            end
            printf "\U000F17A9 "
            pwd
        end
    end
end

function open --description 'xdg-open, detached from the terminal'
    xdg-open $argv >/dev/null 2>&1 &
    disown
end

# --- directories -------------------------------------------------------------
abbr -a -- .. 'cd ..'
abbr -a -- ... 'cd ../..'
abbr -a -- .... 'cd ../../..'

# --- tools -------------------------------------------------------------------
alias a 'omarchy-agent --inline'
alias c 'opencode --auto'
alias cy 'codex --approve-for-me'
alias d docker
alias r rails
alias t 'tmux attach; or tmux new -s Work'
alias h herdr
alias mup 'MISE_MINIMUM_RELEASE_AGE=0 mise up'

# These wrap tdl (fns/tmux), so they only work now that tdl is ported.
alias ic 'tdl c'
alias ix 'tdl cx'
alias icx 'tdl c cx'

function cx --description 'Clear scrollback, then claude'
    printf "\033[2J\033[3J\033[H"
    claude --permission-mode auto
end

function n --description 'nvim, defaulting to the current directory'
    if test (count $argv) -eq 0
        command nvim .
    else
        command nvim $argv
    end
end

function compress --description 'tar -czf a directory'
    set -l target (string trim -r -c / -- $argv[1])
    tar -czf "$target.tar.gz" "$target"
end
alias decompress 'tar -xzf'

# --- git ---------------------------------------------------------------------
alias g git
alias gcm 'git commit -m'
alias gcam 'git commit -a -m'
alias gcad 'git commit -a --amend'

# --- tool init (order matters: atuin and starship go last) -------------------
command -q mise; and mise activate fish | source
command -q zoxide; and zoxide init fish | source
command -q fzf; and fzf_key_bindings
command -q atuin; and atuin init fish | source
command -q starship; and starship init fish | source
