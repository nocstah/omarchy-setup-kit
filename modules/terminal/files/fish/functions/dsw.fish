function dsw --description 'Stop all rsync-on-change watchers'
    set -l found 0
    # Our own process group, so a stray pattern match can never kill this shell.
    set -l self (ps -o pgid= -p $fish_pid | string trim)

    for pid in (pgrep -f 'rsw-watch ')
        set -l pgid (ps -o pgid= -p $pid 2>/dev/null | string trim)
        test -n "$pgid"; or continue
        test "$pgid" = "$self"; and continue

        # rsw uses setsid, so each watcher is its own group: kill the group to
        # take the inotifywait and rsync children with it.
        if kill -- -$pgid 2>/dev/null
            echo "Stopped watch (pid $pid)"
            set found 1
        end
    end

    test $found -eq 1; or echo "No active watches"
end
