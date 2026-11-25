function tdlm --description 'One tdl window per subdirectory of the current directory'
    if test -z "$argv[1]"
        echo "Usage: tdlm <c|cx|codex|other_ai> [<second_ai>]"
        return 1
    end
    if test -z "$TMUX"
        echo "You must start tmux to use tdlm."
        return 1
    end

    set -l ai $argv[1]
    set -l ai2 $argv[2]
    set -l base_dir $PWD
    set -l first 1

    # tmux disallows dots and colons in session names.
    tmux rename-session (path basename $base_dir | tr '.:' '--')

    set -l cmd "tdl $ai"
    test -n "$ai2"; and set cmd "$cmd $ai2"

    # find rather than a glob: an empty directory makes fish's wildcard error.
    for dirpath in (find $base_dir -mindepth 1 -maxdepth 1 -type d -not -name '.*' | sort)
        if test $first -eq 1
            # Reuse the current window for the first project.
            tmux send-keys -t $TMUX_PANE "cd '$dirpath' && $cmd" C-m
            set first 0
        else
            set -l pane_id (tmux new-window -c $dirpath -P -F '#{pane_id}')
            tmux send-keys -t $pane_id "$cmd" C-m
        end
    end
end
