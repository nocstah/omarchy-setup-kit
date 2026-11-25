-- Shared helpers for the kit's key files.
local M = {}
local HOME = os.getenv("HOME")

-- A program on PATH, or an absolute path that exists.
function M.have(cmd) return o.cmd_present(cmd) end

-- An Omarchy shell plugin that is installed (~/.config/omarchy/plugins/<id>).
function M.plugin(id)
  local f = io.open(HOME .. "/.config/omarchy/plugins/" .. id .. "/manifest.json", "r")
  if f then f:close() return true end
  return false
end

-- Press and release a shortcut in the focused window. The down/up split is
-- the one Omarchy's clipboard keys use (default/hypr/bindings/clipboard.lua):
-- send_shortcut can leave a synthetic key stuck, and wtype would merge the
-- Super you are holding into the chord.
function M.send(mods, key)
  hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
  hl.timer(function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
  end, { timeout = 50, type = "oneshot" })
end

-- Tags come from Omarchy's own app rules (default/hypr/apps/*.lua), so
-- "browser" and "terminal" mean what they mean to Omarchy. Dynamic tags end in "*".
function M.active_has_tag(...)
  local w = hl.get_active_window()
  if not w then return false end
  local wanted = { ... }
  for _, tag in ipairs(w.tags or {}) do
    local t = tag:gsub("%*$", "")
    for _, x in ipairs(wanted) do
      if t == x then return true end
    end
  end
  return false
end

function M.active_is_terminal() return M.active_has_tag("terminal") end

function M.active_is_browser()
  return M.active_has_tag("chromium-based-browser", "firefox-based-browser")
end

-- The Herdr app draws terminals in a window Omarchy doesn't tag as a terminal
-- (tagging it would change its opacity and the keys below), so copy and paste
-- treat it as one by its class.
function M.active_uses_terminal_clipboard()
  if M.active_is_terminal() then return true end
  local w = hl.get_active_window()
  return w ~= nil and tostring(w.class or "") == "herdr-app"
end

return M
