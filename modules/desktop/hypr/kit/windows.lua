-- Window rules.
local HOME = os.getenv("HOME")
local BIN = HOME .. "/.local/share/setup-kit/bin/"

-- A dragged window joins a group only when dropped on the group's tab bar,
-- not anywhere over the group, so you can still drop one beside a group.
hl.config({ group = { drag_into_group = 2 } })

-- Omarchy's pop-up terminals (updates, installs: app ids org.omarchy.*) are
-- drawn opaque, so a see-through terminal setting doesn't make their logs
-- hard to read. The Omarchy agent is a full terminal and stays as it is.
o.window("org\\.omarchy\\..*", { force_rgbx = true })
o.window("org\\.omarchy\\.agent", { force_rgbx = false })
if type(_G.kit_popup_sub) == "table" then pcall(function() _G.kit_popup_sub:remove() end) end
_G.kit_popup_sub = hl.on("window.open", function(w)
  if not w or not w.pid or w.pid <= 0 then return end
  local class = w.class or w.initial_class or ""
  if class == "org.omarchy.agent" or not class:match("^org%.omarchy%.") then return end
  hl.exec_cmd(BIN .. "foot-popup-opaque " .. w.pid)
end)

-- Password managers and file managers float, centred.
o.window("com\\.onepassword\\.OnePassword|1[Pp]assword", { float = true, center = true })
o.window("io\\.github\\.lgse\\.Strata|org\\.gnome\\.Nautilus", { float = true, center = true, size = { 1280, 800 } })
