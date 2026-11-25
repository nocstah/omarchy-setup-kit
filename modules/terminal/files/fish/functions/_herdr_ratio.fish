function _herdr_ratio --description 'Echo a split ratio as a float'
    # Kept on awk rather than fish's `math -s4`: math trims trailing zeros
    # (1 instead of 1.0000) and herdr's --ratio parser is not verifiable here.
    awk -v a="$argv[1]" -v b="$argv[2]" 'BEGIN { printf "%.4f", a / b }'
end
