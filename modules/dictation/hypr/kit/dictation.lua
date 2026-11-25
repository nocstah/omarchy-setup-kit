-- Dictation keys, for whichever dictation Omarchy uses (Voxtype by default).
--   Super+Ctrl+X        start or stop
--   F9 (hold)           talk while you hold it
--   Ctrl+Alt+Space      start or stop
--   Right Super (hold)  talk while you hold it; Super shortcuts still work
-- Omarchy 4.5's own Alt+Space and Right Alt are given back to apps.
if not (o.dictation_installed and o.dictation_installed()) then return end

hl.unbind("ALT + SPACE")
hl.unbind("ALT + Alt_R")

o.rebind("SUPER + CTRL + X", "Dictation on/off", "omarchy-dictation toggle")
o.bind_hold("F9", "Dictate while held", "omarchy-dictation start", "Stop dictating", "omarchy-dictation stop")

-- Superwhisper binds these two itself while it is the backend.
local pipe = io.popen("omarchy-default-dictation 2>/dev/null", "r")
local backend = pipe and pipe:read("*l")
if pipe then pipe:close() end
if backend ~= "superwhisper" then
  o.rebind("CTRL + ALT + SPACE", "Dictation on/off", "omarchy-dictation toggle")
  o.bind_hold("SUPER + Super_R", "Dictate while held", "omarchy-dictation start",
    "Stop dictating", "omarchy-dictation stop", { ignore_mods = true, non_consuming = true })
end

-- The Voxtype OSD plugin (blizl.voxtype-osd), when installed: its engine
-- picker and meeting controls. Super+M was Omarchy's minimise to the dock.
local f = io.open(os.getenv("HOME") .. "/.config/omarchy/plugins/blizl.voxtype-osd/manifest.json", "r")
if f then
  f:close()
  o.rebind("SUPER + E", "Voxtype engine picker (OSD plugin)", "mkdir -p $XDG_RUNTIME_DIR/voxtype && touch $XDG_RUNTIME_DIR/voxtype/engine-picker.flag")
  o.rebind("SUPER + M", "Voxtype meeting controls (OSD plugin)", "mkdir -p $XDG_RUNTIME_DIR/voxtype && touch $XDG_RUNTIME_DIR/voxtype/meeting-controls.flag")
end
