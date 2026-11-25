function y --description 'yazi, cd-ing the shell to wherever you quit'
    set -l tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"

    # `builtin cd` on purpose: the `cd` function in config.fish falls back to
    # zoxide for non-directories, which this never needs. zoxide still records
    # the jump — its fish init hooks `--on-variable PWD`, so it sees any change.
    if read -z cwd <"$tmp"; and test -n "$cwd"; and test "$cwd" != "$PWD"
        builtin cd -- "$cwd"
    end

    rm -f -- "$tmp"
end
