-- Ported from bindings.conf. Verified against origin/quattro (187 default binds).
--
-- v4 moved ALL app launchers to SUPER+SHIFT+<key> and freed bare SUPER+<key>
-- for window management. Your config uses bare SUPER for apps, so every key
-- that v4 already claims is unbound first.
--
-- Dropped: SUPER+SPACE -> dms spotlight (adopting omarchy-shell; SUPER+SPACE
-- is now the Omarchy menu). SUPER+RETURN terminal: v4's default already does
-- this, including cwd, so no override needed.

------------------------------------------------------------------
-- Bare-SUPER app launchers that shadow a v4 default
------------------------------------------------------------------

hl.unbind("SUPER + F")   -- was: Full screen
o.bind("SUPER + F", "File manager", { omarchy = "nautilus" })

hl.unbind("SUPER + T")   -- was: Toggle window floating/tiling
o.bind("SUPER + T", "Activity", { tui = "btop" })

hl.unbind("SUPER + L")   -- was: Toggle workspace layout
o.bind("SUPER + L", "Lock", "omarchy-system-lock")

hl.unbind("SUPER + X")   -- was: Universal cut (clipboard)
o.bind("SUPER + X", "X", { webapp = "https://x.com/" })

------------------------------------------------------------------
-- Bare-SUPER keys v4 leaves free
------------------------------------------------------------------

o.bind("SUPER + B", "Browser", "google-chrome-stable")
o.bind("SUPER + M", "Music",  { omarchy = "spotify" })
o.bind("SUPER + N", "Editor", { omarchy = "editor" })
o.bind("SUPER + D", "Docker", { tui = "lazydocker" })
o.bind("SUPER + A", "T3 Chat", { webapp = "https://t3.chat" })
o.bind("SUPER + Y", "YouTube", { webapp = "https://youtube.com/" })

------------------------------------------------------------------
-- Modified keys where your meaning differs from v4's
------------------------------------------------------------------

hl.unbind("SUPER + SHIFT + B")   -- was: Browser
o.bind("SUPER + SHIFT + B", "Browser (private)", "google-chrome-stable --incognito")

hl.unbind("SUPER + SHIFT + G")   -- was: Signal
o.bind("SUPER + SHIFT + G", "WhatsApp", { webapp = "https://web.whatsapp.com/", focus = true })

hl.unbind("SUPER + SHIFT + S")   -- was: Google Maps
o.bind("SUPER + SHIFT + S", "Screenshot of region", "omarchy-capture-screenshot")

hl.unbind("SUPER + ALT + G")     -- was: Move active window out of group
o.bind("SUPER + ALT + G", "Google Messages",
  { webapp = "https://messages.google.com/web/conversations", focus = true })

------------------------------------------------------------------
-- Additions
------------------------------------------------------------------

-- From your default/hypr/bindings/utilities.conf edit.
o.bind("SUPER + CTRL + SHIFT + P", "Screen record a region",
  "omarchy-capture-screenrecording --stop-recording || omarchy-menu toggle trigger.capture.screenrecord")

------------------------------------------------------------------
-- macOS-style workspace switching
------------------------------------------------------------------

-- CTRL + arrows switch workspaces, matching macOS "move left/right a space".
-- Both were unbound in Hyprland, so no hl.unbind is needed.
--
-- Trade-off: Hyprland binds are global and intercept before apps, so this
-- takes CTRL + LEFT/RIGHT away from word-wise cursor motion. macOS resolves
-- this the same way -- word motion lives on OPTION + arrows there -- so
-- ~/.zshrc-local maps ALT + LEFT/RIGHT to backward-word/forward-word.
--
-- SUPER + TAB / SUPER + SHIFT + TAB still switch workspaces too.
o.bind("CTRL + LEFT", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
o.bind("CTRL + RIGHT", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
