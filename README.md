# Omarchy setup kit

Keyboard shortcuts and desktop tweaks for **Omarchy 4.5**, collected from one
person's setup so another computer can feel the same. It holds no keys,
passwords or personal files: you add your own API keys afterwards, if you want
the cloud dictation.

The installer backs up every file it replaces, tells you what it's doing, and
can undo itself.

## What you get

**Desktop**: the main part. See [SHORTCUTS.md](SHORTCUTS.md) for every key.

- **Mac-style keys.** Super works like Command: Super+C/V/A/Z/F/S/T/N/W do what
  they do on a Mac. In a browser, Super+W closes the tab and Super+Shift+[ / ]
  switch tabs. In a terminal, Super+T and Super+N open another terminal.
  Super+\` cycles the windows of one app.
- **Pads.** Super+Shift+Enter drops a terminal down from the top of the screen,
  Super+Shift+N opens a notes file (`~/notes/notes.md`, saved as you go), and
  Super+Shift+Y opens a Yazi file manager. Press the key again to hide it.
- **Look.** Rounded floating windows, wider gaps, unfocused windows faded and
  dimmed, longer and smoother animations, and blur behind see-through windows.
  Super+Shift+L switches back to Omarchy's own look. Super+Alt+Backspace drops
  the outer gaps, for a small laptop screen.
- **Omarchy 4.0 keys.** A few keys that Omarchy 4.5 gave new jobs do their old
  ones again, for example Super+Ctrl+T for btop and Super+Tab across every
  monitor.
- **App keys.** Each of these works only when the app is installed: Omasnap
  screenshots (Print, F12, Alt+Shift+4), 1Password quick access
  (Ctrl+Shift+Space), the Bitwarden bar plugin, Strata as the file manager,
  and Feishin for music.
- **Window rules.** A window joins a group only when you drop it on the group's
  tab bar. 1Password and file managers float. Omarchy's pop-up terminals stay
  solid.
- **Other.** Natural scrolling, and the clipboard keeps what you copied after
  you close the app (needs `wl-clip-persist`, which it offers to install).
  Optional, off by default: an MX Master thumb wheel that cycles workspaces, a
  gesture button that drags windows, and a US keyboard layout with æ ø å on
  AltGr.

**Terminal and apps**

- **foot.** See-through ("glass") terminals that follow the theme: more see-through
  on dark themes, less on light ones.
- **fish.** Omarchy's shell setup (its aliases, functions and completions)
  ported from bash to fish. Optional: fish is only your shell if you choose it
  (see below).
- **Helix.** Settings for the editor, and its colours follow the Omarchy theme.
- **Yazi.** Markdown files open formatted in `glow`.
- **atuin.** Shell history search.

The installer asks before installing any of these programs.

**Dictation**: Voxtype, which Omarchy installs for you.

- **Speech to text.** Groq's Whisper in the cloud (fast and accurate; needs a
  free key) or Whisper on your own computer (offline).
- **Cleanup.** Claude Haiku tidies the text: it removes "um"s and false starts,
  fixes punctuation, and spells the words in your dictionary the way you want.
  It needs an Anthropic API key; without one, you get Whisper's text as it is.
- **Keys.** Super+Ctrl+X or Ctrl+Alt+Space start and stop dictation. To talk
  only while a key is held, hold F9 or Right Super.

## Install

```
git clone https://github.com/nocstah/omarchy-setup-kit.git
cd omarchy-setup-kit
./install.sh --dry-run      # shows what would change; changes nothing
./install.sh                # asks before installing any program
```

From a tarball instead: `tar xf omarchy-setup-kit-*.tar.gz`, then `cd` into the
folder it makes and run the same two commands.

To install only some parts, use `--only desktop`, `--only terminal,dictation`
and so on. `./install.sh --help` lists all the options.

Hyprland reloads at the end, so the new keys work at once. If one of the kit's
files has an error, a notification names it, and the rest of the kit still
loads.

### After installing

- **Options.** To change one, edit `~/.config/hypr/kit/options.lua`, save it,
  and run `hyprctl reload`. Options include `thumb_wheel = true` and
  `keyboard_layout = "us,no"`. The full list, with a line on each, is at the
  top of `~/.config/hypr/kit/init.lua`.
- **Your own keys still win.** The kit loads after Omarchy's defaults and before
  your own `~/.config/hypr/bindings.lua`. A key you set there overrides the
  kit's (unbind it first, as Omarchy's comments in that file show).
- **Dictation keys.** Open `~/.config/dictate/env` and fill in the keys you
  use:
  - `VOXTYPE_WHISPER_API_KEY`, a Groq key from https://console.groq.com/keys
  - `ANTHROPIC_API_KEY`, an Anthropic key, for the cleanup

  Then run `systemctl --user restart voxtype`. The file is readable by you
  alone; don't share it.
- **Dictionary.** Add names and words that dictation gets wrong to
  `~/.config/dictate/dictionary.txt`, one per line.
- **fish.** To make fish your shell, run `chsh -s /usr/bin/fish`, then log out
  and back in.
- **MX Master gesture button** (option `mx_gesture_button`). The button sends
  nothing by itself. Install Solaar and add this rule to
  `~/.config/solaar/rules.yaml`, so that holding the button holds mouse
  button 8:

  ```yaml
  %YAML 1.3
  ---
  - Key: [Mouse Gesture Button, pressed]
  - MouseClick: [button8, depress]
  ...
  ---
  - Key: [Mouse Gesture Button, released]
  - MouseClick: [button8, release]
  ...
  ```

## Undo

```
./install.sh --restore latest    # undo the last run
./install.sh --restore all       # undo every run: back to before the kit
./install.sh --list-backups
```

Backups are kept in `~/.local/state/setup-kit/backups/`. An undo restores every
file the kit replaced and removes every file it added. Programs it installed
stay installed.

## What's left out on purpose

- **Secrets:** API keys, passwords, SSH and git settings.
- **Themes and Omarchy plugins.** The kit binds keys for a few plugins, but
  only when they are installed.
- **Things tied to one computer:** monitor layouts, keyboard and headset
  quirks, and personal apps and scripts.

## Working on the kit

`maintainer/test.sh` installs the kit into a throwaway home, with stand-ins
for every command that would change your system (packages, systemd, hyprctl),
and checks the dry run, a repeat run, the undo and the modules on their own.
It then loads Omarchy's own Lua key files followed by the kit's, against a
recording stand-in for Hyprland. It fails when a kit key leaves an Omarchy key
on the same chord or calls a part of Hyprland's API no working config uses, and
`--update-shortcuts` rewrites SHORTCUTS.md from what gets bound. It needs an
Omarchy 4.5 machine with `lua` (5.5, as Hyprland uses) and optionally `fish`.
Point `KIT_EXTRA_API_SOURCES` at more folders of working Hyprland Lua configs,
such as your own `~/.config/hypr`, to widen the API check.

`maintainer/build.sh` runs the tests, scans for anything personal (your git
name and email, user and host names, home folder, API-key shapes, and words
listed in `~/.config/setup-kit-maintainer/private-words`), and packs
`dist/omarchy-setup-kit-<date>.tar.gz`. It won't pack if the scan finds anything.

## Files

- `install.sh`: the installer.
- `SHORTCUTS.md`: every key the kit changes.
- `modules/desktop/hypr/kit/*.lua`: the Hyprland files. Each one is short and
  says what it does. They are installed into `~/.config/hypr/kit/`.
- `modules/terminal/files/`, `modules/dictation/files/`: the files copied into
  `~/.config`.
- `maintainer/`: the tests and the build script.

## Licence

MIT, see [LICENSE](LICENSE). The fish files port Omarchy's own bash setup
(also MIT) to fish.
