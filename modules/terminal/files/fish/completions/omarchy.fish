# Completion for the omarchy CLI.
#
# Replaces /usr/share/omarchy/default/bash/completions, which is bash-only
# (complete -F / COMPREPLY / compgen). This version reads `omarchy commands
# --json` instead of scanning omarchy-* binaries, so it also carries each
# command's summary — fish shows those in the completion menu.
#
# Two deliberate improvements over the bash original:
#   - a command with BOTH subcommands and its own argument forms offers both
#     (bash stops at the subcommands)
#   - flags are collected from anywhere in the argument spec, not just its
#     first token

function __omarchy_complete --description 'Candidates for the next omarchy token'
    set -l cache (__omarchy_cache); or return

    # Tokens already completed, minus the command name itself.
    set -l tokens (commandline -opc)
    set -e tokens[1]
    set -l prefix (string join ' ' -- $tokens)

    command awk -F'\t' -v prefix="$prefix" '
    function emit(v) {
        if (v == "" || (v in seen2)) return
        if (v ~ /^[+-]?N$/) return          # placeholder standing for a number
        seen2[v] = 1
        print v
    }

    # Positional candidate: a bare literal, or each branch of <a|b> / [a|b].
    function positional(t,   inner, vals, nv, v) {
        if (t ~ /^[<\[].*[>\]]$/) {
            inner = substr(t, 2, length(t) - 2)
            if (index(inner, "|") == 0) {
                if (substr(inner, 1, 1) == "-") emit(inner)   # a lone [--flag]
                return                                        # else a free value like <id>
            }
            nv = split(inner, vals, /\|/)
            for (v = 1; v <= nv; v++) emit(vals[v])
        } else if (t ~ /^--/ || t ~ /^[a-z][a-z0-9-]*$/) {
            emit(t)
        }
    }

    # Flags may sit anywhere in the spec, not only at its head.
    function flags(t,   inner, vals, nv, v) {
        if (t ~ /^[<\[].*[>\]]$/) t = substr(t, 2, length(t) - 2)
        if (index(t, "|") > 0) {
            nv = split(t, vals, /\|/)
            for (v = 1; v <= nv; v++) if (substr(vals[v], 1, 1) == "-") emit(vals[v])
        } else if (substr(t, 1, 1) == "-") {
            emit(t)
        }
    }

    BEGIN { plen = length(prefix) }

    {
        route = $1; summary = $2; args = $3

        rest = ""
        if (plen == 0) {
            rest = route
        } else if (route == prefix) {
            argspec[route] = args
            next
        } else if (substr(route, 1, plen + 1) == prefix " ") {
            rest = substr(route, plen + 2)
        }

        if (rest != "") {
            seg = rest
            sub(/ .*/, "", seg)
            if (!(seg in seen)) { seen[seg] = 1; order[++n] = seg }
            # A description only belongs to the segment when it IS the whole route.
            if (rest == seg && summary != "") desc[seg] = summary
        }
    }

    END {
        for (i = 1; i <= n; i++) {
            s = order[i]
            seen2[s] = 1
            print s (s in desc ? "\t" desc[s] : "")
        }

        if (!(prefix in argspec)) exit
        spec = argspec[prefix]
        if (spec == "") exit

        # Alternative whole forms are separated by " | " at the top level.
        na = split(spec, alts, / \| /)
        for (a = 1; a <= na; a++) {
            nt = split(alts[a], tok, / +/)
            if (nt < 1) continue
            positional(tok[1])
            for (j = 1; j <= nt; j++) flags(tok[j])
        }
    }
    ' $cache
end

# -f: no file completion — omarchy takes routes, not paths.
complete -c omarchy -f
complete -c omarchy -a '(__omarchy_complete)'
