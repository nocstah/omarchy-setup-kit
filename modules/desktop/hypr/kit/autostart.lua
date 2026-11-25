-- Programs started with Hyprland.
local opts = _G.kit.options

-- Keep what you copied after the app you copied it from closes.
if opts.clipboard_persist and o.cmd_present("wl-clip-persist") then
  o.exec_on_start("wl-clip-persist --clipboard regular --reconnect-tries inf")
end
