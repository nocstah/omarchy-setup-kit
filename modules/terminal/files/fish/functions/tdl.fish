function tdl --description 'tmux dev layout: editor, AI pane, terminal'
    if test -z "$argv[1]"
        echo "Usage: tdl <c|cx|codex|other_ai> [<second_ai>]"
        return 1
    end
    if test -z "$TMUX"
        echo "You must start tmux to use tdl."
        return 1
    end

    set -l current_dir $PWD
    set -l ai $argv[1]
    set -l ai2 $argv[2]

    # TMUX_PANE is stable even if the active window changes under us.
    set -l editor_pane $TMUX_PANE

    tmux rename-window -t $editor_pane (path basename $current_dir)

    # Terminal strip along the bottom, 15%.
    tmux split-window -v -l 15% -t $editor_pane -c $current_dir

    # AI on the right, 30%.
    set -l ai_pane (tmux split-window -h -l 30% -t $editor_pane -c $current_dir -P -F '#{pane_id}')

    if test -n "$ai2"
        set -l ai2_pane (tmux split-window -v -t $ai_pane -c $current_dir -P -F '#{pane_id}')
        tmux send-keys -t $ai2_pane $ai2 C-m
    end

    tmux send-keys -t $ai_pane $ai C-m
    tmux send-keys -t $editor_pane "$EDITOR ." C-m

    # Omarchy's bash version ends with `select-pane -t "$opencode_pane"`, a
    # variable never set in tdl — copy-paste from tds. It expands to empty, so
    # focus lands wherever tmux left it. Its own comment says "Select the nvim
    # pane for focus", so that is what this does.
    tmux select-pane -t $editor_pane
end
