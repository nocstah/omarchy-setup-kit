-- Pads: one app each, parked out of sight in its own special workspace. Its
-- key always gives you that app: starts it, shows it, or hides it again. The
-- size is set on every show against the monitor you're on.
--
--   Super+Shift+Return  dropdown terminal (top, 90% x 50%)
--   Super+Shift+N       notes: ~/notes/notes.md in Helix (or Neovim), centred
--   Super+Shift+Y       files: Yazi in your home folder, centred (needs yazi)
--
-- Omarchy had the browser on Super+Shift+Return (Super+Shift+B still opens
-- it), the editor on Super+Shift+N (now Super+Alt+N) and YouTube on Super+Shift+Y.
-- A pad wears a square, bevelled border in one of the theme's colours, so you
-- can tell it from a normal window. Set CUES.enabled = false for plain pads.
if not o.cmd_present("foot") then return end

local HOME = os.getenv("HOME")
local BIN = HOME .. "/.local/share/setup-kit/bin/"

local notes_editor = o.cmd_present("helix") and "helix" or (o.cmd_present("hx") and "hx" or "nvim")

local PADS = {
  terminal = {
    name = "pad-terminal",
    cmd = "foot --app-id pad-terminal --title 'Dropdown terminal'",
    w = 0.90, h = 0.50, anchor = "top", hue = "red",
  },
  notes = {
    name = "pad-notes",
    -- Helix runs in ~/notes so ~/notes/.helix/config.toml (save on focus loss) applies.
    cmd = "sh -c 'mkdir -p \"$HOME/notes\" && cd \"$HOME/notes\" && exec foot --app-id pad-notes --title Notes "
      .. notes_editor .. " notes.md'",
    w = 0.55, h = 0.65, anchor = "center", hue = "bright_red", solid = true,
  },
}
if o.cmd_present("yazi") then
  PADS.yazi = {
    name = "pad-yazi",
    cmd = "foot --app-id pad-yazi --title Files yazi " .. HOME,
    w = 0.55, h = 0.65, anchor = "center", hue = "green",
  }
end

local CUES = { enabled = true, border = 4, rounding = 0, angle = 135, lift = 0.35 }

local function theme_colors()
  local t = {}
  local f = io.open(HOME .. "/.local/state/omarchy/current/theme/colors.toml")
  if not f then return t end
  for line in f:lines() do
    local k, v = line:match('^%s*([%w_]+)%s*=%s*"#(%x%x%x%x%x%x)"')
    if k then t[k] = v end
  end
  f:close()
  return t
end

-- Mix a hex colour towards white (amount > 0) or black (amount < 0).
local function shade(hex, amount)
  local target = amount > 0 and 255 or 0
  local a = math.abs(amount)
  local out = {}
  for i = 1, 5, 2 do
    local c = tonumber(hex:sub(i, i + 1), 16)
    out[#out + 1] = string.format("%02x", math.floor(c + (target - c) * a + 0.5))
  end
  return table.concat(out)
end

-- The string form: border_color ignores the table form in a window rule.
local function bevel(hex)
  return string.format("rgb(%s) rgb(%s) rgb(%s) %ddeg", shade(hex, CUES.lift), hex, shade(hex, -CUES.lift), CUES.angle)
end

for _, p in pairs(PADS) do
  o.window("^" .. p.name .. "$", { float = true, workspace = "special:" .. p.name .. " silent", tag = "+terminal" })
end

local function cue_rules(colors, hue)
  local hex = colors[hue or "red"] or colors.red or colors.accent
  local rules = { rounding = CUES.rounding, border_size = CUES.border }
  if hex then rules.border_color = bevel(hex) end
  return rules
end

if CUES.enabled then
  local colors = theme_colors()
  for _, p in pairs(PADS) do o.window("^" .. p.name .. "$", cue_rules(colors, p.hue)) end
  -- Omarchy's scratchpad (Super+Shift+S with the kit's keys) wears it too, while a window is in it.
  o.window({ workspace = "name:special:scratchpad" }, cue_rules(colors, "red"))
end

-- The notes pad is drawn opaque: text over a see-through terminal is hard to read.
local function is_solid(class)
  for _, p in pairs(PADS) do if p.solid and p.name == class then return true end end
  return false
end
if type(_G.kit_pads) == "table" and type(_G.kit_pads._subs) == "table" then
  for _, sub in ipairs(_G.kit_pads._subs) do pcall(function() sub:remove() end) end
end
local subs = {}
subs[#subs + 1] = hl.on("window.open", function(w)
  if not w or not w.pid or w.pid <= 0 or not is_solid(w.class or "") then return end
  hl.exec_cmd(BIN .. "foot-popup-opaque " .. w.pid)
end)

local function work_area(m)
  local rot = (m.transform or 0) % 2 == 1
  local mw = math.floor((rot and m.height or m.width) / (m.scale or 1) + 0.5)
  local mh = math.floor((rot and m.width or m.height) / (m.scale or 1) + 0.5)
  local r = type(m.reserved) == "table" and m.reserved or {}
  local rl, rt = r.left or r[1] or 0, r.top or r[2] or 0
  local rr, rb = r.right or r[3] or 0, r.bottom or r[4] or 0
  return (m.x or 0) + rl, (m.y or 0) + rt, mw - rl - rr, mh - rt - rb
end

local function focused_monitor()
  for _, m in ipairs(hl.get_monitors()) do if m.focused then return m end end
  return hl.get_monitor_at_cursor()
end

local function find_pad(p)
  for _, w in ipairs(hl.get_windows()) do if w.mapped and w.class == p.name then return w end end
end

local function shown_on(p, m)
  local s = m.active_special_workspace
  return s ~= nil and s.name == "special:" .. p.name
end

local function place(p, w, m)
  local ax, ay, aw, ah = work_area(m)
  local W, H = math.floor(aw * p.w), math.floor(ah * p.h)
  local X = ax + math.floor((aw - W) / 2)
  local Y = p.anchor == "top" and ay or ay + math.floor((ah - H) / 2)
  local target = "address:" .. w.address
  hl.dispatch(hl.dsp.window.resize({ x = W, y = H, window = target }))
  hl.dispatch(hl.dsp.window.move({ x = X, y = Y, window = target }))
end

local function reveal(p, w, m)
  -- A pad dragged out to a normal workspace is taken back first.
  if not (w.workspace and w.workspace.name == "special:" .. p.name) then
    hl.dispatch(hl.dsp.window.move({ workspace = "special:" .. p.name, follow = false, window = "address:" .. w.address }))
  end
  place(p, w, m)
  hl.dispatch(hl.dsp.workspace.toggle_special(p.name))
end

local function toggle(p)
  local m = focused_monitor()
  if not m then return end
  if shown_on(p, m) then
    hl.dispatch(hl.dsp.workspace.toggle_special(p.name))
    return
  end
  local w = find_pad(p)
  if w then reveal(p, w, m) return end
  -- Not running: start it, then wait (up to 5 s) for its window.
  hl.dispatch(hl.dsp.exec_cmd(p.cmd))
  local tries = 0
  local function wait()
    tries = tries + 1
    local nw = find_pad(p)
    if nw then
      reveal(p, nw, focused_monitor() or m)
    elseif tries < 50 then
      hl.timer(wait, { timeout = 100, type = "oneshot" })
    end
  end
  hl.timer(wait, { timeout = 150, type = "oneshot" })
end

o.rebind("SUPER + SHIFT + RETURN", "Dropdown terminal", function() toggle(PADS.terminal) end)
o.rebind("SUPER + SHIFT + N", "Notes pad", function() toggle(PADS.notes) end)
o.rebind("SUPER + ALT + N", "Editor", { omarchy = "editor" })
if PADS.yazi then
  o.rebind("SUPER + SHIFT + Y", "Files pad (Yazi)", function() toggle(PADS.yazi) end)
end

-- For scripts: hyprctl eval 'kit_pads.toggle("notes")'
_G.kit_pads = { toggle = function(name) local p = PADS[name]; if p then toggle(p) end end, _subs = subs }

-- Pads drop over the desktop as it is: no darkening behind them.
hl.config({ decoration = { dim_special = 0 } })

-- Special workspaces drop down from the top and go back up, like a dropdown
-- terminal. ("top" enters from the top; leaving towards the top is "bottom".)
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slidevert top" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slidevert bottom" })
