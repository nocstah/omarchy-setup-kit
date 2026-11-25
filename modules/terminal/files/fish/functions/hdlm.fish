function hdlm --description 'One hdl tab per subdirectory of the current directory'
    if test -z "$argv[1]"
        echo "Usage: hdlm <c|cx|codex|other_ai> [<second_ai>]"
        return 1
    end
    if test -z "$HERDR_PANE_ID"
        echo "You must start herdr to use hdlm."
        return 1
    end

    set -l ai $argv[1]
    set -l ai2 $argv[2]
    set -l base_dir $PWD
    set -l first 1

    herdr workspace rename $HERDR_WORKSPACE_ID (path basename $base_dir) >/dev/null

    # bash builds this with `printf -v ... %q`, which has no fish equivalent.
    # `string escape` is the right tool anyway: the pane now runs fish, so the
    # command needs fish quoting rather than bash's.
    set -l hdl_command "hdl "(string escape -- $ai)
    test -n "$ai2"; and set hdl_command "$hdl_command "(string escape -- $ai2)

    # find rather than a glob: an empty directory makes fish's wildcard error.
    for dirpath in (find $base_dir -mindepth 1 -maxdepth 1 -type d -not -name '.*' | sort)
        if test $first -eq 1
            # Reuse the current tab for the first project.
            herdr pane run $HERDR_PANE_ID "cd "(string escape -- $dirpath)" && $hdl_command" >/dev/null
            set first 0
        else
            set -l pane_id (herdr tab create --workspace $HERDR_WORKSPACE_ID --cwd $dirpath --no-focus \
                | jq -r '.result.root_pane.pane_id')
            herdr pane run $pane_id "$hdl_command" >/dev/null
        end
    end
end
