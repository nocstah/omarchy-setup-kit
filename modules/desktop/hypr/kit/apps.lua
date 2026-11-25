-- Keys for apps. Each is bound only when its app is installed, checked every
-- time Hyprland loads its config, so installing the app later turns its key on.
local kit = require("hypr.kit.lib")
local HOME = os.getenv("HOME")

local function first_present(...)
  for _, cmd in ipairs({ ... }) do
    if kit.have(cmd) then return cmd end
  end
end

-- Screenshots: Omasnap (github.com/omacom/omasnap) when installed, on Print,
-- F12 and Alt+Shift+4 (the Mac's Cmd+Shift+4). Without it F12 and Alt+Shift+4
-- run Omarchy's screenshot tool, and Print stays Omarchy's.
local omasnap = first_present("omasnap", HOME .. "/.local/bin/omasnap")
if omasnap then
  for _, key in ipairs({ "PRINT", "F12", "ALT + SHIFT + 4" }) do o.rebind(key, "Screenshot (Omasnap)", omasnap) end
  hl.layer_rule({ match = { namespace = "^omasnap$" }, no_anim = true, animation = "none", no_screen_share = true })
else
  for _, key in ipairs({ "F12", "ALT + SHIFT + 4" }) do o.rebind(key, "Screenshot", "omarchy-capture-screenshot") end
end

-- 1Password's quick access. On Wayland apps can't take global keys, so
-- Hyprland holds Ctrl+Shift+Space for it.
if kit.have("/opt/1Password/1password") then
  o.rebind("CTRL + SHIFT + SPACE", "1Password quick access",
    "/opt/1Password/1password --ozone-platform=wayland --quick-access")
end

-- The Bitwarden bar panel plugin (qs-bitwarden-cli) on Omarchy's Passwords key.
if kit.plugin("io.github.elevate08.qs-bitwarden-cli") then
  o.rebind("SUPER + SHIFT + SLASH", "Bitwarden", "omarchy-shell io.github.elevate08.qs-bitwarden-cli toggle")
end

-- Strata as the file manager, in place of Nautilus.
local strata = first_present("strata", HOME .. "/.local/bin/strata")
if strata then
  o.rebind("SUPER + SHIFT + F", "File manager (Strata)", { launch = strata })
  o.rebind("SUPER + ALT + SHIFT + F", "File manager here (Strata)",
    "uwsm-app -- " .. strata .. " \"$(omarchy-cmd-terminal-cwd)\"")
end

-- Feishin, a music player for a Navidrome or Jellyfin library.
if kit.have("feishin") then
  o.rebind("SUPER + ALT + M", "Music library (Feishin)", { launch = "feishin", focus = "^feishin$" })
end
