# fip takes a host first, then ports. The bash original had no completion at all.
complete -c fip -f
complete -c fip -n '__fish_is_first_arg' -a '(__fish_print_hostnames)' -d Host
