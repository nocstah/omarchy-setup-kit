function tsl --description 'tmux swarm layout: N tiled panes all running the same command'
    if test -z "$argv[1]" -o -z "$argv[2]"
        echo "Usage: tsl <pane_count> <command>"
        return 1
    end
    if test -z "$TMUX"
        echo "You must start tmux to use tsl."
        return 1
    end

    set -l count $argv[1]
    # Omarchy's bash version loops `while (( ${#panes[@]} < count ))` with no
    # check that count is a number, so a typo spawns panes forever.
    if not string match -qr '^[1-9][0-9]*$' -- $count
        echo "Pane count must be a positive number, got: $count"
        return 1
    end

    set -l cmd $argv[2]
    set -l current_dir $PWD
    set -l panes $TMUX_PANE

    tmux rename-window -t $TMUX_PANE (path basename $current_dir)

    while test (count $panes) -lt $count
        # bash's ${panes[-1]} / ${panes[0]} become $panes[-1] / $panes[1]:
        # fish arrays are 1-indexed.
        set -l new_pane (tmux split-window -h -t $panes[-1] -c $current_dir -P -F '#{pane_id}')
        set -a panes $new_pane
        tmux select-layout -t $panes[1] tiled
    end

    for pane in $panes
        tmux send-keys -t $pane $cmd C-m
    end

    tmux select-pane -t $panes[1]
end
