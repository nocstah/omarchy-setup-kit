function ssh --description 'ssh, cleaning up the terminal and reconnecting when a session drops'
    set -l started (date +%s)

    command ssh $argv
    set -l rc $status

    # Non-interactive output (a pipe, a script): behave exactly like ssh.
    isatty stdout; or return $rc

    _ssh_disarm

    # Reconnect only when an interactive session drops. ssh exits 255 for
    # transport failures, but: a fast 255 with no established session is a
    # connect/auth failure; a remote command's own 255 is indistinguishable and
    # must not have its side effects replayed; and redirected stdin would feed
    # the remaining piped input to a fresh remote shell.
    if test $rc -ne 255
        return $rc
    end
    isatty stdin; or return $rc
    _ssh_interactive $argv; or return $rc
    test (math (date +%s) - $started) -lt 30; and return $rc

    while true
        echo "Connection lost. Reconnecting (Ctrl-C to stop)..."
        sleep 2

        command ssh $argv
        set rc $status
        _ssh_disarm

        # Anything but another transport failure ends the loop — including
        # 130 from Ctrl-C, which is what stops this without a bash subshell.
        if test $rc -ne 255
            return $rc
        end
    end
end
