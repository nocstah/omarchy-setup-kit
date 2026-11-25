function iso2sd --description 'Write an ISO to a USB/SD drive'
    if test (count $argv) -lt 1
        echo "Usage: iso2sd <input_file> [output_device]"
        echo "Example: iso2sd ~/Downloads/ubuntu-25.04-desktop-amd64.iso /dev/sda"
        return 1
    end

    set -l iso $argv[1]
    set -l drive $argv[2]

    if not test -r "$iso"
        echo "No such ISO: $iso"
        return 1
    end

    if test -z "$drive"
        set -l available_sds (lsblk -dpno NAME | grep -E '/dev/sd')

        if test (count $available_sds) -eq 0
            echo "No SD drives found and no drive specified"
            return 1
        end

        # omarchy-drive-select does `drives="$@"` and then reads it line by
        # line, so it needs ONE newline-delimited argument. Without `string
        # collect` fish would split these into separate arguments and the
        # picker would treat the whole list as a single drive name.
        set drive (omarchy-drive-select (string join \n $available_sds | string collect))

        if test -z "$drive"
            echo "No drive selected"
            return 1
        end
    end

    sudo dd bs=4M status=progress oflag=sync if="$iso" of="$drive"
    sudo eject "$drive"
end
