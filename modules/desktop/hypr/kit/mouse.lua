-- Mouse.
local opts = _G.kit.options
local BIN = os.getenv("HOME") .. "/.local/share/setup-kit/bin/"

-- Super + mouse wheel switched workspaces; a free-spinning wheel kept doing
-- that after Super was pressed for some other shortcut.
if opts.no_super_wheel then
  hl.unbind("SUPER + mouse_down")
  hl.unbind("SUPER + mouse_up")
end

-- A mouse's thumb wheel (sideways scroll, as on the MX Master): over a window
-- group it flips the group's tabs, elsewhere it walks this monitor's
-- workspaces. A flick has to be deliberate (3 events in 300 ms) to count.
-- It takes two-finger sideways scrolling on a touchpad too, so it's off by default.
if opts.thumb_wheel then
  hl.config({ binds = { scroll_event_delay = 0 } })
  o.rebind("mouse_right", "Thumb wheel: next workspace or tab", BIN .. "thumb-wheel m+1")
  o.rebind("mouse_left", "Thumb wheel: previous workspace or tab", BIN .. "thumb-wheel m-1")
end

-- The MX Master's gesture button: hold it and move the mouse to drag a window.
-- The button sends nothing by itself; Solaar has to turn it into button 8
-- (see README.md, "MX Master gesture button").
if opts.mx_gesture_button then
  o.rebind("mouse:264", "Move window (gesture button)", hl.dsp.window.drag(), { mouse = true })
end
