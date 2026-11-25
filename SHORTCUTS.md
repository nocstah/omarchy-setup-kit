# Shortcuts

What the setup kit changes on top of Omarchy 4.5's own keys (Super+K lists them all).
"Was" is what Omarchy 4.5 had on that key. Options are in `~/.config/hypr/kit/options.lua`.

Generated from the kit's Lua files by `maintainer/test.sh`.

## Mac-style keys

Super works like the Command key. In apps it sends the Ctrl shortcut; terminals keep Ctrl for themselves, so there Super+T and Super+N open another terminal and the editing keys do nothing. Option mac_keys.

| Keys | Does | Was |
| --- | --- | --- |
| `Super + C` | Copy | Universal copy |
| `Super + V` | Paste | Universal paste |
| `Super + A` | Select all | Select all |
| `Super + W` | Close tab (browser) or window | Close window |
| `Super + Alt + W` | Close window |  |
| `Super + T` | New tab (terminal: new terminal) | Toggle window floating/tiling |
| `Super + N` | New window (terminal: new terminal) |  |
| `Super + Shift + T` | Float or tile window | Activity |
| `Super + Shift + J` | Swap split sides |  |
| `Super + F` | Find | Full screen |
| `Super + Ctrl + F` | Full screen | Tiled full screen |
| `Super + Ctrl + Shift + F` | Tiled full screen |  |
| `Super + S` | Save | Toggle scratchpad |
| `Super + Shift + S` | Scratchpad | Google Maps |
| `Super + Z` | Undo |  |
| `Super + Shift + Z` | Redo |  |
| `Super + R` | Reload page (browser) |  |
| `Super + P` | Print (browser) or pseudo tile | Pseudo window |
| `Super + Shift + [` | Previous tab |  |
| `Super + Shift + ]` | Next tab |  |
| `` Super + ` `` | Next window of this app | Toggle Quake console |
| `` Super + Shift + ` `` | Previous window of this app | Move window to Quake console |

## Omarchy 4.0 keys

Keys whose job Omarchy 4.5 changed, back to what they did in 4.0. Option omarchy40_keys.

| Keys | Does | Was |
| --- | --- | --- |
| `Super + Ctrl + Q` | Calculator (was on Super+Shift+Q) |  |
| `Super + Ctrl + T` | Activity (btop) | Theme menu |
| `Super + Ctrl + W` | Network | Background switcher |
| `Super + Ctrl + N` | Nightlight | Network |
| `Super + Alt + Space` | Apps menu | Apps |
| `Super + ,` | Dismiss last notification | Dismiss, invoke, or focus last notification |
| `Super + Alt + ,` | Open last notification | Dismiss last notification |
| `Super + Ctrl + ,` | Silence notifications | Control notifications with the keyboard |
| `Super + Tab` | Next workspace (all monitors) | Next workspace |
| `Super + Shift + Tab` | Previous workspace (all monitors) | Previous workspace |
| `Super + Ctrl + Tab` | Last workspace (any monitor) | Former workspace |

## Pads

A pad is one app kept out of sight: its key starts it, shows it, or hides it again. Option pads.

| Keys | Does | Was |
| --- | --- | --- |
| `Super + Shift + Enter` | Dropdown terminal | Browser |
| `Super + Shift + N` | Notes pad | Editor |
| `Super + Alt + N` | Editor |  |
| `Super + Shift + Y` | Files pad (Yazi) | YouTube |

## Look

Two looks: custom (rounded floating windows, wide gaps, unfocused windows faded and dimmed, tiled windows square) and Omarchy's own. Edge mode drops the outer gaps on either. Option look.

| Keys | Does | Was |
| --- | --- | --- |
| `Super + Shift + L` | Switch look (custom / Omarchy) |  |
| `Super + Alt + Backspace` | Edge mode (no outer gaps) |  |

## Apps

Each key is there only when its app is installed (checked whenever Hyprland loads its config). Without Omasnap, F12 and Alt+Shift+4 take Omarchy's own screenshot tool and Print stays Omarchy's. Option app_keys.

| Keys | Does | Was |
| --- | --- | --- |
| `Print` | Screenshot (Omasnap) | Screenshot |
| `F12` | Screenshot (Omasnap) |  |
| `Alt + Shift + 4` | Screenshot (Omasnap) |  |
| `Ctrl + Shift + Space` | 1Password quick access |  |
| `Super + Shift + /` | Bitwarden | Passwords |
| `Super + Shift + F` | File manager (Strata) | File manager |
| `Super + Alt + Shift + F` | File manager here (Strata) | File manager (cwd) |
| `Super + Alt + M` | Music library (Feishin) |  |

## Keyboard

Only with keyboard_layout set to two or more layouts, such as "us,no" or "usno,no".

| Keys | Does | Was |
| --- | --- | --- |
| `Super + F12` | Next keyboard layout |  |

## Mouse

Thumb wheel: option thumb_wheel (off by default). Gesture button: option mx_gesture_button (off by default), with Solaar set up as in README.md.

| Keys | Does | Was |
| --- | --- | --- |
| `Thumb wheel forward` | Thumb wheel: next workspace or tab |  |
| `Thumb wheel back` | Thumb wheel: previous workspace or tab |  |
| `Gesture button` | Move window (gesture button) |  |

## Dictation

Only when dictation is installed (the dictation module offers Voxtype). Option dictation_keys.

| Keys | Does | Was |
| --- | --- | --- |
| `Super + Ctrl + X` | Dictation on/off |  |
| `F9` (hold) | Dictate while held |  |
| `Ctrl + Alt + Space` | Dictation on/off |  |
| `Right Super` (hold) | Dictate while held |  |
| `Super + E` | Voxtype engine picker (OSD plugin) |  |
| `Super + M` | Voxtype meeting controls (OSD plugin) | Minimize window to the dock |

## Keys the kit takes away

Omarchy 4.5 keys the kit leaves empty. Delete the line in that kit file to get one back.

| Keys | Omarchy 4.5 had | Kit file |
| --- | --- | --- |
| `Alt + Space` | Toggle dictation | dictation.lua |
| `Right Alt` | Start dictation (push-to-talk) | dictation.lua |
| `Super + Alt + L` | Cycle workspace layout back | omarchy40.lua |
| `Super + Ctrl + Alt + ,` | Toggle silencing notifications | omarchy40.lua |
| `Super + I` | Switch input language | omarchy40.lua |
| `Super + Q` | Close window | omarchy40.lua |
| `Super + Shift + I` | Switch input language back | omarchy40.lua |
| `Super + Shift + Q` | Calculator | omarchy40.lua |
| `Super + Wheel down` | Scroll active workspace forward | mouse.lua |
| `Super + Wheel up` | Scroll active workspace backward | mouse.lua |
