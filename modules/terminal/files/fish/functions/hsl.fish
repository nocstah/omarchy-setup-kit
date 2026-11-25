function hsl --description 'herdr swarm layout: N panes in a grid, all running the same command'
    if test -z "$argv[1]" -o -z "$argv[2]"
        echo "Usage: hsl <pane_count> <command>"
        return 1
    end
    if test -z "$HERDR_PANE_ID"
        echo "You must start herdr to use hsl."
        return 1
    end

    set -l count $argv[1]
    # Same guard as tsl: bash loops on this unchecked.
    if not string match -qr '^[1-9][0-9]*$' -- $count
        echo "Pane count must be a positive number, got: $count"
        return 1
    end

    set -l cmd $argv[2]
    set -l current_dir $PWD

    herdr tab rename $HERDR_TAB_ID (path basename $current_dir) >/dev/null

    # Tile into a grid: ceil(sqrt(count)) columns, rows spread across them.
    set -l cols 1
    while test (math "$cols * $cols") -lt $count
        set cols (math $cols + 1)
    end

    # Even columns come from splitting the rightmost one off at 1/(n-k+1) each
    # time, which keeps the list in left-to-right order.
    set -l columns $HERDR_PANE_ID
    for k in (seq 1 (math $cols - 1))
        set -a columns (_herdr_split $columns[-1] right (_herdr_ratio 1 (math "$cols - $k + 1")) $current_dir)
    end

    # Split each column into its share of rows, evenly and top-to-bottom.
    # bash indexes columns from 0; fish lists are 1-based, so the remainder
    # test compares against idx-1.
    set -l panes
    for idx in (seq 1 $cols)
        set -l col $columns[$idx]
        set -l rows (math "floor($count / $cols)")
        test (math $idx - 1) -lt (math "$count % $cols"); and set rows (math $rows + 1)

        set -a panes $col
        set -l last $col
        for j in (seq 1 (math $rows - 1))
            set last (_herdr_split $last down (_herdr_ratio 1 (math "$rows - $j + 1")) $current_dir)
            set -a panes $last
        end
    end

    for pane in $panes
        herdr pane run $pane $cmd >/dev/null
    end
end
