function fip --description 'Forward one or more remote ports over SSH'
    if test (count $argv) -lt 2
        echo "Usage: fip <host> <port1> [port2] ..."
        return 1
    end

    set -l host $argv[1]
    set -e argv[1]

    for port in $argv
        if ssh -f -N -L "$port:localhost:$port" $host
            echo "Forwarding localhost:$port -> $host:$port"
        end
    end
end
