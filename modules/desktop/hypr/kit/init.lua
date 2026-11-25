-- Setup kit: keyboard shortcuts and desktop tweaks on top of Omarchy 4.5.
-- Loaded from the end of ~/.config/hypr/hyprland.lua (the "setup-kit" block).
-- Turn parts on or off in options.lua next to this file; your choices there
-- survive a reinstall. Each part is one file here, so you can read what it does.

local defaults = {
  mac_keys = true,          -- mac.lua: Super+C/V/W/T/N/A/F/S/Z/R/P, tab keys, Super+`
  omarchy40_keys = true,    -- omarchy40.lua: Omarchy 4.0-style keys kept on 4.5
  app_keys = true,          -- apps.lua: keys for apps, each only if that app is installed
  pads = true,              -- pads.lua: dropdown terminal, notes and files pads
  look = true,              -- look.lua: rounded floating windows, dimmed inactive ones, wide gaps, motion
  windows = true,           -- windows.lua: window rules (groups, popups, floating apps)
  natural_scroll = true,    -- input.lua: content follows your fingers, mouse wheel too
  keyboard_layout = nil,    -- input.lua: e.g. "us,no" (Super+F12 switches); nil keeps Omarchy's
  no_super_wheel = true,    -- mouse.lua: Super + mouse wheel no longer switches workspaces
  thumb_wheel = false,      -- mouse.lua: a mouse's thumb wheel (MX Master) cycles workspaces or a group's tabs.
                            --   Off by default: it also takes two-finger horizontal touchpad scrolling.
  mx_gesture_button = false,-- mouse.lua: hold the MX Master gesture button to drag a window (needs a Solaar rule)
  clipboard_persist = true, -- autostart.lua: keep the clipboard after the app you copied from closes
  dictation_keys = true,    -- dictation.lua (dictation module): Super+Ctrl+X, F9, Ctrl+Alt+Space, Right Super
}

local opts = {}
for k, v in pairs(defaults) do opts[k] = v end
local found, chosen = pcall(require, "hypr.kit.options")
if found and type(chosen) == "table" then
  for k, v in pairs(chosen) do opts[k] = v end
end

_G.kit = { options = opts, version = "1" }

local dir = os.getenv("HOME") .. "/.config/hypr/kit/"
local function part(name)
  local f = io.open(dir .. name .. ".lua", "r")
  if not f then return end -- that module isn't installed
  f:close()
  local ok, err = pcall(require, "hypr.kit." .. name)
  if not ok then
    hl.exec_cmd("notify-send -u critical 'Setup kit' " .. string.format("%q", name .. ".lua: " .. tostring(err)))
  end
end

part("input")
part("mouse")
if opts.windows then part("windows") end
if opts.look then part("look") end
if opts.omarchy40_keys then part("omarchy40") end
if opts.mac_keys then part("mac") end
if opts.app_keys then part("apps") end
if opts.pads then part("pads") end
if opts.dictation_keys then part("dictation") end
part("autostart")
