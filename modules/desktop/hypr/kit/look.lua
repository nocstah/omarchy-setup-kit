-- The look: two sets of gaps and corners you switch between with
-- Super+Shift+L, remembered in ~/.local/state/kit-look.
--   custom   rounded, squircle-ish corners on floating windows, wide gaps,
--            unfocused windows a little faded and darker, so focus reads at a glance
--   omarchy  Omarchy's own: square corners, no fading, 5/10 gaps
-- Edge mode (Super+Alt+Backspace) drops the outer gaps on top of either look,
-- for a small laptop screen; remembered in ~/.local/state/kit-edge.
-- Also here: the motion (window and workspace animations) and blur behind
-- see-through windows, so the kit's glassy terminals show the wallpaper.
local STATE = os.getenv("HOME") .. "/.local/state/kit-look"
local EDGE_STATE = os.getenv("HOME") .. "/.local/state/kit-edge"
local opts = _G.kit.options

local looks = {}
looks.custom = {
  general = { gaps_in = 14, gaps_out = 24, border_size = 2, resize_on_border = true },
  decoration = {
    rounding = 4,
    rounding_power = 2.6, -- above 2 the corner bends toward a squircle, the macOS shape
    active_opacity = 1.0,
    inactive_opacity = 0.85,
    dim_inactive = true,
    dim_strength = 0.15,
    dim_around = 0.4,
  },
}
looks.omarchy = {
  general = { gaps_in = 5, gaps_out = 10, border_size = 2, resize_on_border = false },
  decoration = {
    rounding = 0,
    rounding_power = 2.0,
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    dim_inactive = false,
    dim_strength = 0.5,
    dim_around = 0.4,
  },
}

local function read(path, fallback)
  local f = io.open(path)
  if not f then return fallback end
  local s = (f:read("*l") or ""):gsub("%s+", "")
  f:close()
  return s
end
local function write_state(path, value)
  local f = io.open(path, "w")
  if f then f:write(value, "\n") f:close() end
end

local current = read(STATE, "custom")
if not looks[current] then current = "custom" end
local edge_on = read(EDGE_STATE, "off") == "on"

local function apply()
  hl.config(looks[current])
  if edge_on then hl.config({ general = { gaps_out = 0 } }) end
end
apply()

_G.kit_look = {
  toggle = function()
    current = current == "omarchy" and "custom" or "omarchy"
    write_state(STATE, current)
    apply()
    hl.exec_cmd("notify-send -e -t 1500 'Look' '" .. current .. "'")
  end,
  edge = function()
    edge_on = not edge_on
    write_state(EDGE_STATE, edge_on and "on" or "off")
    apply()
    hl.exec_cmd("notify-send -e -t 1500 'Edge mode' '" .. (edge_on and "on" or "off") .. "'")
  end,
  current = function() return current end,
}
o.rebind("SUPER + SHIFT + L", "Switch look (custom / Omarchy)", function() _G.kit_look.toggle() end)
o.rebind("SUPER + ALT + BACKSPACE", "Edge mode (no outer gaps)", function() _G.kit_look.edge() end)

-- Tiled windows stay square whatever the look; floating ones get its corners.
hl.window_rule({ name = "kit-tiled-square", match = { float = false }, rounding = 0 })

-- Blur behind see-through windows. xray: the blur shows the wallpaper, not
-- the windows stacked underneath, which is what makes a terminal read as glass.
if opts.blur ~= false then
  hl.config({ decoration = { blur = {
    enabled = true, size = 16, passes = 2, noise = 0.015, contrast = 1.05, brightness = 1.0,
    vibrancy = 0.24, ignore_opacity = false, new_optimizations = true, xray = true,
    popups = true, special = false,
  } } })
end

-- Motion: Omarchy's is short and turns workspace slides and the fade between
-- windows off. These are longer and eased.
hl.curve("kitMac",     { type = "bezier", points = { { 0.25, 0.10 }, { 0.25, 1.00 } } })
hl.curve("kitSnap",    { type = "bezier", points = { { 0.16, 1.00 }, { 0.30, 1.00 } } })
hl.curve("kitSoftOut", { type = "bezier", points = { { 0.38, 0.00 }, { 0.20, 1.00 } } })
hl.curve("kitRise",    { type = "bezier", points = { { 0.22, 1.00 }, { 0.36, 1.00 } } })

hl.animation({ leaf = "windowsIn",   enabled = true, speed = 5.5, bezier = "kitRise",    style = "popin 92%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 3.5, bezier = "kitSoftOut", style = "popin 92%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4,   bezier = "kitSnap" })
hl.animation({ leaf = "fadeIn",      enabled = true, speed = 4,   bezier = "kitMac" })
hl.animation({ leaf = "fadeOut",     enabled = true, speed = 3,   bezier = "kitMac" })
hl.animation({ leaf = "fadeSwitch",  enabled = true, speed = 4,   bezier = "kitMac" })
hl.animation({ leaf = "fadeShadow",  enabled = true, speed = 6,   bezier = "kitMac" })
hl.animation({ leaf = "fadeDim",     enabled = true, speed = 4,   bezier = "kitMac" })
hl.animation({ leaf = "border",      enabled = true, speed = 6,   bezier = "kitMac" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 5,   bezier = "kitSnap",    style = "slidefade 20%" })
