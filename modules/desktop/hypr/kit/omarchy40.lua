-- Omarchy 4.0-style keys on 4.5: the jobs some chords had before 4.5 gave
-- them new ones. Delete a line (and run hyprctl reload) to get that key's 4.5
-- job back; or set omarchy40_keys = false in options.lua for all of them.

-- New in 4.5, taken out again.
for _, chord in ipairs({
  "SUPER + Q",               -- Close window (Super+W does that)
  "SUPER + ALT + L",         -- Cycle workspace layout back
  "SUPER + SHIFT + Q",       -- Calculator (back on Super+Ctrl+Q below)
  "SUPER + I",               -- Switch input language
  "SUPER + SHIFT + I",       -- Switch input language back
  "SUPER + CTRL + ALT + comma", -- Silence notifications (back on Super+Ctrl+comma below)
}) do
  hl.unbind(chord)
end

-- Same chord, the 4.0 job.
if o.cmd_present("omacalc") then o.rebind("SUPER + CTRL + Q", "Calculator (was on Super+Shift+Q)", "omacalc") end
o.rebind("SUPER + CTRL + T", "Activity (btop)", { tui = "btop" })                 -- 4.5: theme menu
o.rebind("SUPER + CTRL + W", "Network", { panel = "omarchy.network" })            -- 4.5: background switcher
o.rebind("SUPER + CTRL + N", "Nightlight", "omarchy-toggle-nightlight")          -- 4.5: network
o.rebind("SUPER + ALT + SPACE", "Apps menu", { menu = "apps" })                   -- 4.5: the dock's apps grid
o.rebind("SUPER + comma", "Dismiss last notification", { ipc = "notifications.dismissOne" })
o.rebind("SUPER + ALT + comma", "Open last notification", { ipc = "notifications.invokeLast" })
o.rebind("SUPER + CTRL + comma", "Silence notifications", "omarchy-toggle-notification-silencing")

-- Super+Tab walks every workspace in use, not just this monitor's.
o.rebind("SUPER + TAB", "Next workspace (all monitors)", hl.dsp.focus({ workspace = "e+1" }))
o.rebind("SUPER + SHIFT + TAB", "Previous workspace (all monitors)", hl.dsp.focus({ workspace = "e-1" }))
o.rebind("SUPER + CTRL + TAB", "Last workspace (any monitor)", hl.dsp.focus({ workspace = "previous" }))
