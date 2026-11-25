function format-drive --description 'Wipe a drive and format it as a single exFAT partition'
    if test (count $argv) -ne 2
        echo "Usage: format-drive <device> <name>"
        echo "Example: format-drive /dev/sda 'My Stuff'"
        echo
        echo "Available drives:"
        lsblk -d -o NAME -n | awk '{print "/dev/"$1}'
        return 1
    end

    set -l device $argv[1]
    set -l label $argv[2]

    echo "WARNING: This will completely erase all data on $device and label it '$label'."
    read -P "Are you sure you want to continue? (y/N): " -l confirm

    string match -qr '^[Yy]$' -- "$confirm"; or return 1

    sudo wipefs -a "$device"; or return 1
    sudo dd if=/dev/zero of="$device" bs=1M count=100 status=progress
    sudo parted -s "$device" mklabel gpt; or return 1
    sudo parted -s "$device" mkpart primary 1MiB 100%; or return 1
    sudo parted -s "$device" set 1 msftdata on

    # A device whose name ends in a digit separates the partition number with
    # a `p`: nvme0n1 -> nvme0n1p1, mmcblk0 -> mmcblk0p1, sda -> sda1.
    # Omarchy's bash version only special-cases "nvme", so it builds
    # /dev/mmcblk01 for an SD card — a partition that never exists, leaving the
    # card wiped and partitioned but unformatted.
    set -l partition "$device"1
    if string match -qr '[0-9]$' -- "$device"
        set partition "$device"p1
    end

    sudo partprobe "$device"; or true
    sudo udevadm settle; or true

    sudo mkfs.exfat -n "$label" "$partition"; or return 1

    echo "Drive $device formatted as exFAT and labeled '$label'."
end
