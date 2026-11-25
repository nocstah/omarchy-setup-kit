function dip --description 'Stop forwarding one or more SSH ports'
    if test (count $argv) -eq 0
        echo "Usage: dip <port1> [port2] ..."
        return 1
    end

    for port in $argv
        # Anchored to an actual ssh process. Omarchy's bash version matches
        # "ssh.*-L <port>..." unanchored, which also matches any *other*
        # process whose command line happens to contain that text — including
        # the shell you typed the command in.
        if pkill -f "^([^ ]*/)?ssh .*-L $port:localhost:$port"
            echo "Stopped forwarding port $port"
        else
            echo "No forwarding on port $port"
        end
    end
end
