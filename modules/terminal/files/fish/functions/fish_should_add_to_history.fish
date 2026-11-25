function fish_should_add_to_history --description 'Skip commands typed with a leading space'
    # Omarchy's bash layer sets HISTCONTROL=ignoreboth. fish dedupes on its own
    # (the "ignoredups" half) but records space-prefixed commands, so this
    # restores the "ignorespace" half. atuin needs its own history_filter for
    # the same effect — it hooks fish_preexec and does not consult this.
    for line in $argv
        string match -qr '^\s' -- $line; and return 1
    end
    return 0
end
