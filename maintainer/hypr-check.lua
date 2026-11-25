-- Loads Omarchy 4.5's own Lua helpers and default keys, then the setup kit,
-- against a stand-in for Hyprland's hl API that records what they do. Checks
-- the kit and writes SHORTCUTS.md.
--
--   HOME=<a home with the kit installed> lua maintainer/hypr-check.lua <scenario> [shortcuts.md]
--
-- scenario "all": every app and plugin the kit can bind for is present.
-- scenario "bare": none are, and dictation isn't installed.
-- scenario "dictation": as "all", for a home with only the dictation module.
-- KIT_API_SOURCES: folders of Lua configs known to work with Hyprland; the
-- kit may only call hl functions and dispatchers used there.
local scenario = arg[1] or "all"
local out_md = arg[2]
local HOME = assert(os.getenv("HOME"))
local OMARCHY = os.getenv("OMARCHY_PATH") or "/usr/share/omarchy"
package.path = HOME .. "/.config/?.lua;" .. OMARCHY .. "/?.lua;" .. package.path
local BT = string.char(96) -- a backtick

local errors = {}
local function err(msg) errors[#errors + 1] = msg end

-- What Hyprland's Lua API is known to have.
local known_hl, known_dsp = {}, {}
local sources = os.getenv("KIT_API_SOURCES") or (OMARCHY .. "/default/hypr")
for dir in sources:gmatch("[^:]+") do
  local p = io.popen("grep -rhoE 'hl\\.[a-z_]+(\\.[a-z_]+)*' " .. string.format("%q", dir) .. " --include='*.lua' 2>/dev/null")
  for name in p:read("*a"):gmatch("[^\n]+") do
    known_hl[name:match("^hl%.([a-z_]+)")] = true
    local d = name:match("^hl%.dsp%.(.+)$")
    if d then known_dsp[d] = true end
  end
  p:close()
end

-- Where a call comes from: a kit file or an Omarchy file (not the helpers).
local function origin()
  for level = 3, 30 do
    local info = debug.getinfo(level, "S")
    if not info then break end
    local s = info.source or ""
    local k = s:match("/hypr/kit/([%w_]+)%.lua$")
    if k then return "kit/" .. k end
    local d = s:match("/default/hypr/(.+)%.lua$")
    if d and d ~= "helpers" then return "omarchy/" .. d end
  end
  return "?"
end

local MOD_ORDER = { SUPER = 1, CTRL = 2, ALT = 3, SHIFT = 4 }
local function norm(keys)
  local mods, key = {}, nil
  for raw in keys:gmatch("[^+]+") do
    local part = raw:gsub("^%s+", ""):gsub("%s+$", "")
    local up = part:upper()
    if up == "CONTROL" then up = "CTRL" end
    if MOD_ORDER[up] and part == up then mods[#mods + 1] = up else key = part end
  end
  table.sort(mods, function(a, b) return MOD_ORDER[a] < MOD_ORDER[b] end)
  key = key or "?"
  if not key:find("[:_]") then key = key:upper() end
  local k = table.concat(mods, " + ")
  return (k ~= "" and (k .. " + ") or "") .. key
end

local binds, order = {}, {}
local kit_seq, seq = {}, 0
local replaced = {} -- key -> what Omarchy had there, when the kit unbinds it
local taken = {}    -- keys the kit unbound
local dsp_used, hl_used = {}, {}
local config = {}
local execs = {}
local in_kit = false

local function merge(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" and type(dst[k]) == "table" then merge(dst[k], v)
    elseif type(v) == "table" then dst[k] = {}; merge(dst[k], v)
    else dst[k] = v end
  end
end

local function dsp_proxy(path)
  return setmetatable({}, {
    __index = function(_, k) return dsp_proxy(path and (path .. "." .. k) or k) end,
    __call = function()
      if in_kit then dsp_used[path] = origin() end
      return { dsp = path }
    end,
  })
end

local sub = { remove = function() end }
local api = {
  dsp = dsp_proxy(nil),
  bind = function(keys, dispatcher, opts)
    local k = norm(keys)
    if not binds[k] then binds[k] = {}; order[#order + 1] = k end
    local src = origin()
    if src:match("^kit/") and not kit_seq[k] then seq = seq + 1; kit_seq[k] = seq end
    table.insert(binds[k], { src = src, desc = opts and opts.description, release = opts and opts.release })
  end,
  unbind = function(keys)
    local k = norm(keys)
    if in_kit then
      for _, b in ipairs(binds[k] or {}) do
        if b.src:match("^omarchy/") and not b.release then replaced[k] = replaced[k] or b.desc or "?" end
      end
      taken[k] = origin()
    end
    binds[k] = nil
  end,
  config = function(t) if in_kit then merge(config, t) end end,
  get_config = function() return nil end,
  exec_cmd = function(c) execs[#execs + 1] = c end,
  on = function() return sub end,
  timer = function() return sub end,
  get_monitors = function() return {} end,
  get_windows = function() return {} end,
  get_active_window = function() return nil end,
  get_window = function() return nil end,
  get_monitor_at_cursor = function() return nil end,
  plugin = {},
}
hl = setmetatable({}, {
  __index = function(_, k)
    if in_kit then hl_used[k] = origin() end
    local v = api[k]
    if v == nil then v = function() end end
    return v
  end,
})

-- Omarchy's helpers and default keys, as default/hypr/omarchy.lua loads them.
require("default.hypr.helpers")
pcall(require, "default.hypr.monitor-workspaces")
o.workspaces = o.workspaces or { move_to_monitor = function() return function() end end }
pcall(require, "default.hypr.dictation-backend")

-- The scenario: which apps are installed.
local real_present = o.cmd_present
local is_app = {}
for _, a in ipairs({ "omasnap", "strata", "feishin", "yazi", "omacalc", "helix", "hx", "wl-clip-persist", "/opt/1Password/1password" }) do is_app[a] = true end
o.cmd_present = function(cmd)
  if cmd:match("/%.local/bin/") or is_app[cmd] then return scenario == "all" end
  if cmd == "foot" then return true end
  return real_present(cmd)
end
local real_open = io.open
io.open = function(path, mode)
  if type(path) == "string" and path:find("/.config/omarchy/plugins/", 1, true) and (mode == nil or mode == "r") then
    if scenario ~= "all" then return nil end
    return real_open("/dev/null", "r")
  end
  return real_open(path, mode)
end
local real_popen = io.popen
io.popen = function(cmd, mode)
  if cmd:match("^omarchy%-default%-dictation") then return real_popen("echo voxtype", mode) end
  return real_popen(cmd, mode)
end

for _, m in ipairs({ "media", "clipboard", "input-method", "jis", "tiling", "utilities", "dictation" }) do
  local ok, e = pcall(require, "default.hypr.bindings." .. m)
  if not ok then err("Omarchy's bindings." .. m .. " didn't load here: " .. tostring(e)) end
end
pcall(require, "default.hypr.bindings.applications")
local omarchy_had = {}
for k, list in pairs(binds) do omarchy_had[k] = #list > 0 end
-- Omarchy's bindings/dictation.lua defines o.dictation_installed; the scenario decides it.
o.dictation_installed = function() return scenario ~= "bare" end

-- In "all", every option on, so every key the kit can bind is bound and listed.
if scenario == "all" then
  package.loaded["hypr.kit.options"] = { thumb_wheel = true, mx_gesture_button = true, keyboard_layout = "us,no" }
end

-- The kit.
in_kit = true
local ok, e = pcall(require, "hypr.kit.init")
in_kit = false
if not ok then err("kit init failed: " .. tostring(e)) end
for _, c in ipairs(execs) do
  if c:find("Setup kit", 1, true) then err("a kit part failed: " .. c) end
end

-- Checks.
for name, where in pairs(hl_used) do
  if not known_hl[name] then err(where .. " calls hl." .. name .. ", which no known config uses") end
end
for path, where in pairs(dsp_used) do
  if not known_dsp[path] then err(where .. " uses hl.dsp." .. path .. ", which no known config uses") end
end

local kit_keys = {}
for _, k in ipairs(order) do
  local list = binds[k]
  if list then
    local kit_press, other_press = 0, 0
    for _, b in ipairs(list) do
      if not b.release then
        if b.src:match("^kit/") then kit_press = kit_press + 1 else other_press = other_press + 1 end
      end
      if b.src:match("^kit/") and not b.desc then err(k .. " (" .. b.src .. ") has no description") end
    end
    if kit_press > 0 then kit_keys[#kit_keys + 1] = k end
    if kit_press > 0 and other_press > 0 then err(k .. ": the kit binds it but Omarchy's bind is still there too") end
    if kit_press > 1 then err(k .. ": the kit binds it twice") end
  end
end

local function src_of(k) return binds[k] and binds[k][1] and binds[k][1].src or "none" end
if scenario == "dictation" then
  for _, k in ipairs({ "SUPER + CTRL + X", "F9", "CTRL + ALT + SPACE", "SUPER + Super_R" }) do
    if not src_of(k):match("^kit/dictation") then err(k .. " isn't the kit's dictation key (" .. src_of(k) .. ")") end
  end
  if src_of("SUPER + C"):match("^kit/") then err("Mac keys loaded without the desktop module") end
elseif scenario == "all" then
  local function want(cond, msg) if not cond then err(msg) end end
  local c = config
  want(c.general and c.general.gaps_in == 14, "the custom look's gaps aren't set")
  want(c.decoration and c.decoration.blur and c.decoration.blur.enabled == true, "blur isn't on")
  want(c.group and c.group.drag_into_group == 2, "drag_into_group isn't 2")
  want(c.input and c.input.natural_scroll == true, "natural scroll isn't on")
  want(c.decoration and c.decoration.dim_special == 0, "dim_special isn't 0")
  for _, k in ipairs({ "SUPER + C", "SUPER + W", "SUPER + SHIFT + RETURN", "SUPER + SHIFT + Y", "F12", "SUPER + CTRL + X", "F9", "SUPER + SHIFT + SLASH", "CTRL + SHIFT + SPACE", "SUPER + E" }) do
    want(src_of(k):match("^kit/"), k .. " isn't the kit's (" .. src_of(k) .. ")")
  end
else
  for _, k in ipairs({ "SUPER + SHIFT + Y", "SUPER + CTRL + X", "SUPER + SHIFT + SLASH", "CTRL + SHIFT + SPACE", "PRINT", "SUPER + E", "SUPER + ALT + M" }) do
    if src_of(k):match("^kit/") then err(k .. " is bound although its app isn't there") end
  end
  if src_of("F12") ~= "kit/apps" then err("F12 should fall back to Omarchy's screenshot") end
  if omarchy_had["ALT + SPACE"] and src_of("ALT + SPACE") == "none" then err("Alt+Space should stay Omarchy's when dictation isn't installed") end
end

-- SHORTCUTS.md
local PRETTY = {
  SUPER = "Super", CTRL = "Ctrl", ALT = "Alt", SHIFT = "Shift", RETURN = "Enter", BACKSPACE = "Backspace",
  SPACE = "Space", PRINT = "Print", TAB = "Tab", GRAVE = BT, BRACKETLEFT = "[", BRACKETRIGHT = "]",
  SLASH = "/", COMMA = ",", SUPER_R = "Right Super", ALT_R = "Right Alt",
  MOUSE_LEFT = "Thumb wheel back", MOUSE_RIGHT = "Thumb wheel forward", ["MOUSE:264"] = "Gesture button",
  MOUSE_DOWN = "Wheel down", MOUSE_UP = "Wheel up",
}
local function pretty(k)
  local parts = {}
  for raw in k:gmatch("[^+]+") do
    local part = raw:gsub("^%s+", ""):gsub("%s+$", "")
    parts[#parts + 1] = PRETTY[part:upper()] or part
  end
  local s = table.concat(parts, " + ")
  s = s:gsub("^Super %+ Right Super$", "Right Super"):gsub("^Alt %+ Right Alt$", "Right Alt")
  if s:find(BT, 1, true) then return BT .. BT .. " " .. s .. " " .. BT .. BT end
  return BT .. s .. BT
end

local SECTIONS = {
  { "kit/mac", "Mac-style keys", "Super works like the Command key. In apps it sends the Ctrl shortcut; terminals keep Ctrl for themselves, so there Super+T and Super+N open another terminal and the editing keys do nothing. Option mac_keys." },
  { "kit/omarchy40", "Omarchy 4.0 keys", "Keys whose job Omarchy 4.5 changed, back to what they did in 4.0. Option omarchy40_keys." },
  { "kit/pads", "Pads", "A pad is one app kept out of sight: its key starts it, shows it, or hides it again. Option pads." },
  { "kit/look", "Look", "Two looks: custom (rounded floating windows, wide gaps, unfocused windows faded and dimmed, tiled windows square) and Omarchy's own. Edge mode drops the outer gaps on either. Option look." },
  { "kit/apps", "Apps", "Each key is there only when its app is installed (checked whenever Hyprland loads its config). Without Omasnap, F12 and Alt+Shift+4 take Omarchy's own screenshot tool and Print stays Omarchy's. Option app_keys." },
  { "kit/input", "Keyboard", "Only with keyboard_layout set to two or more layouts, such as \"us,no\" or \"usno,no\"." },
  { "kit/mouse", "Mouse", "Thumb wheel: option thumb_wheel (off by default). Gesture button: option mx_gesture_button (off by default), with Solaar set up as in README.md." },
  { "kit/dictation", "Dictation", "Only when dictation is installed (the dictation module offers Voxtype). Option dictation_keys." },
}

if out_md then
  local lines = {
    "# Shortcuts",
    "",
    "What the setup kit changes on top of Omarchy 4.5's own keys (Super+K lists them all).",
    "\"Was\" is what Omarchy 4.5 had on that key. Options are in " .. BT .. "~/.config/hypr/kit/options.lua" .. BT .. ".",
    "",
    "Generated from the kit's Lua files by " .. BT .. "maintainer/test.sh" .. BT .. ".",
  }
  local seen = {}
  for _, s in ipairs(SECTIONS) do
    local rows = {}
    local sorted = {}
    for _, k in ipairs(kit_keys) do sorted[#sorted + 1] = k end
    table.sort(sorted, function(a, b) return (kit_seq[a] or 0) < (kit_seq[b] or 0) end)
    for _, k in ipairs(sorted) do
      local b
      for _, x in ipairs(binds[k]) do if not x.release and x.src == s[1] then b = x end end
      if b and not seen[k] and not k:find("BRACE") then
        seen[k] = true
        local hold = false
        for _, x in ipairs(binds[k]) do if x.release then hold = true end end
        rows[#rows + 1] = "| " .. pretty(k) .. (hold and " (hold)" or "") .. " | " .. (b.desc or "") .. " | " .. (replaced[k] or "") .. " |"
      end
    end
    if #rows > 0 then
      for _, l in ipairs({ "", "## " .. s[2], "", s[3], "", "| Keys | Does | Was |", "| --- | --- | --- |" }) do lines[#lines + 1] = l end
      for _, r in ipairs(rows) do lines[#lines + 1] = r end
    end
  end
  local gone = {}
  for k, where in pairs(taken) do
    if not binds[k] and replaced[k] then gone[#gone + 1] = "| " .. pretty(k) .. " | " .. replaced[k] .. " | " .. where:gsub("^kit/", "") .. ".lua |" end
  end
  table.sort(gone)
  if #gone > 0 then
    for _, l in ipairs({ "", "## Keys the kit takes away", "", "Omarchy 4.5 keys the kit leaves empty. Delete the line in that kit file to get one back.", "", "| Keys | Omarchy 4.5 had | Kit file |", "| --- | --- | --- |" }) do lines[#lines + 1] = l end
    for _, r in ipairs(gone) do lines[#lines + 1] = r end
  end
  local f = assert(real_open(out_md, "w"))
  f:write(table.concat(lines, "\n"), "\n")
  f:close()
end

local n_rep, n_gone = 0, 0
for k in pairs(replaced) do if binds[k] then n_rep = n_rep + 1 end end
for k in pairs(taken) do if not binds[k] and replaced[k] then n_gone = n_gone + 1 end end
print(string.format("%s: %d kit keys, %d of them on Omarchy keys, %d Omarchy keys taken away", scenario, #kit_keys, n_rep, n_gone))
if #errors > 0 then
  for _, m in ipairs(errors) do print("FAIL " .. m) end
  os.exit(1)
end
print("ok")
