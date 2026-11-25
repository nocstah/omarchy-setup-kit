function _ssh_disarm --description 'Reset terminal modes a dropped SSH session left armed'
    # Mouse tracking (1000/1002/1003 and the 1006 encoding), focus reporting
    # (1004), the alternate screen (1049), and the cursor. A remote tmux, herdr
    # or editor arms these over the pipe and only it can disarm them; if the
    # connection dies instead of exiting cleanly they stay armed locally and
    # every mouse move floods the prompt with escape junk.
    printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?1004l\e[?1049l\e[?25h'
end
