function _ssh_interactive --description 'True for an interactive ssh session: a destination and no remote command'
    # The ssh(1) options that consume a value, so their arguments are not
    # mistaken for the destination. Split into a list rather than glob-matched
    # so an option letter that happens to be a glob character is safe.
    set -l value_letters (string split '' -- BbcDEeFIiJLlmOoPpQRSWw)

    set -l orig $argv
    set -l dest ""
    set -l opts_done 0
    set -l i 1
    set -l n (count $argv)

    while test $i -le $n
        set -l arg $argv[$i]
        set i (math $i + 1)

        if test $opts_done -eq 0; and test "$arg" = "--"
            set opts_done 1
        else if test $opts_done -eq 0; and string match -qr '^-.+' -- $arg
            set -l letters (string sub -s 2 -- $arg)
            set -l nl (string length -- $letters)
            for j in (seq 1 $nl)
                if contains -- (string sub -s $j -l 1 -- $letters) $value_letters
                    # The value is glued to the letter (-p2222) unless the
                    # letter ends the argument, when it takes the next one.
                    test $j -eq $nl; and set i (math $i + 1)
                    break
                end
            end
        else if test -z "$dest"
            set dest $arg
        else
            # A second bare word is a remote command, not a destination.
            return 1
        end
    end

    test -n "$dest"; or return 1

    # A RemoteCommand from ssh_config or -o replays on reconnect just like a
    # positional command. `ssh -G` resolves the effective config for this exact
    # invocation without connecting. Fail closed when it cannot resolve.
    set -l resolved (command ssh -G $orig 2>/dev/null); or return 1

    if printf '%s\n' $resolved | grep -i '^remotecommand ' | grep -qvi '^remotecommand none$'
        return 1
    end
    return 0
end
