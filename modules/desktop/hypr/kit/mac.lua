-- Mac-style Super chords. Super is the Command key: in apps, Super+<key>
-- sends Ctrl+<key>; terminals keep Ctrl for themselves, so there Super+T and
-- Super+N open another terminal and the editing chords do nothing.
local kit = require("hypr.kit.lib")

local function send(mods, key) return function() kit.send(mods, key) end end

-- An app gets mods+key; a terminal runs terminal_action, or nothing.
local function chord(mods, key, terminal_action)
  return function()
    if kit.active_is_terminal() then
      if terminal_action then terminal_action() end
    else
      kit.send(mods, key)
    end
  end
end

local function new_terminal() hl.exec_cmd("omarchy-launch-terminal") end

-- Copy and paste: Ctrl+Shift+C/V in terminals (and the Herdr app), Ctrl+C/V elsewhere.
o.rebind("SUPER + C", "Copy", function()
  if kit.active_uses_terminal_clipboard() then kit.send("CTRL SHIFT", "C") else kit.send("CTRL", "C") end
end)
o.rebind("SUPER + V", "Paste", function()
  if kit.active_uses_terminal_clipboard() then kit.send("CTRL SHIFT", "V") else kit.send("CTRL", "V") end
end)
o.rebind("SUPER + A", "Select all", chord("CTRL", "A"))

-- Super+W closes the tab in a browser (the last tab closes the window), the
-- window elsewhere. Super+Alt+W always closes the window.
o.rebind("SUPER + W", "Close tab (browser) or window", function()
  if kit.active_is_browser() then kit.send("CTRL", "W") else hl.dispatch(hl.dsp.window.close()) end
end)
o.rebind("SUPER + ALT + W", "Close window", hl.dsp.window.close())

o.rebind("SUPER + T", "New tab (terminal: new terminal)", chord("CTRL", "T", new_terminal))
o.rebind("SUPER + N", "New window (terminal: new terminal)", chord("CTRL", "N", new_terminal))
-- Omarchy had floating on Super+T.
o.rebind("SUPER + SHIFT + T", "Float or tile window", hl.dsp.window.float({ action = "toggle" }))
-- Swap the two sides of a split, beside Super+J, which turns the split.
o.rebind("SUPER + SHIFT + J", "Swap split sides", hl.dsp.layout("swapsplit"))

-- Find, save, undo and redo. Not in terminals: there Ctrl+S freezes output and
-- Ctrl+Z suspends the running program.
o.rebind("SUPER + F", "Find", chord("CTRL", "F"))
o.rebind("SUPER + CTRL + F", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
o.rebind("SUPER + CTRL + SHIFT + F", "Tiled full screen", "omarchy-hyprland-window-tiled-fullscreen-toggle")
o.rebind("SUPER + S", "Save", chord("CTRL", "S"))
o.rebind("SUPER + SHIFT + S", "Scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
o.rebind("SUPER + Z", "Undo", chord("CTRL", "Z"))
o.rebind("SUPER + SHIFT + Z", "Redo", chord("CTRL SHIFT", "Z"))

-- Reload and print in browsers. Elsewhere Super+P stays Omarchy's pseudo tile.
o.rebind("SUPER + R", "Reload page (browser)", function()
  if kit.active_is_browser() then kit.send("CTRL", "R") end
end)
o.rebind("SUPER + P", "Print (browser) or pseudo tile", function()
  if kit.active_is_browser() then kit.send("CTRL", "P") else hl.dispatch(hl.dsp.window.pseudo()) end
end)

-- Super+Shift+[ and ]: previous and next tab. A window group's tabs first, then
-- a browser's (Ctrl+Shift+Tab / Ctrl+Tab), other apps Ctrl+PgUp/PgDn.
local function tab(dir)
  return function()
    local w = hl.get_active_window()
    if not w then return end
    if w.group and (w.group.size or 0) > 1 then
      hl.dispatch(dir == "prev" and hl.dsp.group.prev() or hl.dsp.group.next())
    elseif kit.active_is_browser() then
      if dir == "prev" then kit.send("CTRL SHIFT", "Tab") else kit.send("CTRL", "Tab") end
    elseif not kit.active_is_terminal() then
      kit.send("CTRL", dir == "prev" and "Page_Up" or "Page_Down")
    end
  end
end
-- Some layouts report Shift+[ as braceleft, so both names are bound.
for _, k in ipairs({ "bracketleft", "braceleft" }) do o.rebind("SUPER + SHIFT + " .. k, "Previous tab", tab("prev")) end
for _, k in ipairs({ "bracketright", "braceright" }) do o.rebind("SUPER + SHIFT + " .. k, "Next tab", tab("next")) end

-- Super+` and Super+Shift+`: the next and previous window of the same app,
-- on any workspace. (Omarchy 4.5 had its Quake console there.)
local function same_app(dir)
  return function()
    local a = hl.get_active_window()
    if not a then return end
    local ring = {}
    for _, w in ipairs(hl.get_windows({ mapped = true })) do
      if w.class == a.class and not (w.workspace and w.workspace.special) then ring[#ring + 1] = w end
    end
    if #ring < 2 then return end
    table.sort(ring, function(x, y) return x.address < y.address end)
    local i = 1
    for k, w in ipairs(ring) do if w.address == a.address then i = k end end
    local n = ((i - 1 + (dir == "prev" and -1 or 1)) % #ring) + 1
    hl.dispatch(hl.dsp.focus({ window = "address:" .. ring[n].address }))
  end
end
o.rebind("SUPER + grave", "Next window of this app", same_app("next"))
o.rebind("SUPER + SHIFT + grave", "Previous window of this app", same_app("prev"))
