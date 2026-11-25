function __omarchy_cache --description 'Path to the omarchy completion cache, rebuilding it when stale'
    set -l dir (set -q XDG_CACHE_HOME; and echo $XDG_CACHE_HOME; or echo $HOME/.cache)/omarchy
    set -l cache $dir/fish-routes.tsv

    # `omarchy commands --json` takes ~2s, so it must never run on a keypress.
    # Rebuild only when the cache is missing or the omarchy CLI is newer.
    if not test -f $cache; or test /usr/bin/omarchy -nt $cache
        command mkdir -p $dir
        command omarchy commands --all --json 2>/dev/null \
            | command jq -r '.commands[]
                 | . as $c
                 | ($c.routes // [$c.route])[]
                 | [sub("^omarchy ?";""), ($c.summary // ""), ($c.args // "")]
                 | @tsv' \
            | command awk -F'\t' 'NF && $1 != ""' >$cache.tmp 2>/dev/null

        # `commands` is the dispatcher's own meta-subcommand, not a discovered
        # omarchy-* binary, so it never appears in --json. The bash completion
        # special-cases it the same way.
        if test -s $cache.tmp
            printf 'commands\tList every documented command and its summary\t[--all] [--json] [--markdown] [--check]\n' >>$cache.tmp
        end

        if test -s $cache.tmp
            command mv -f $cache.tmp $cache
        else
            command rm -f $cache.tmp
            # Keep serving a stale cache rather than completing nothing.
            test -f $cache; or return 1
        end
    end

    echo $cache
end
