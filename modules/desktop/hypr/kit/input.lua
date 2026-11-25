-- Scrolling and keyboard layout.
local opts = _G.kit.options

if opts.natural_scroll then
  -- Content follows your fingers, on the touchpad and the mouse wheel alike
  -- (input.natural_scroll is the mouse, input.touchpad.natural_scroll the touchpad).
  hl.config({ input = { natural_scroll = true, touchpad = { natural_scroll = true } } })
end

-- keyboard_layout = "us,no" in options.lua: those layouts, Super+F12 switches
-- every keyboard at once. "usno" is in the kit too: US with æ ø å on AltGr at
-- the Norwegian keys (AltGr+' æ, AltGr+; ø, AltGr+[ å; with Shift for capitals).
if type(opts.keyboard_layout) == "string" and opts.keyboard_layout ~= "" then
  hl.config({ input = { kb_layout = opts.keyboard_layout } })
  if opts.keyboard_layout:find(",", 1, true) then
    o.rebind("SUPER + F12", "Next keyboard layout", "hyprctl switchxkblayout all next")
  end
end
