-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Ported from monitors.conf

hl.env("GDK_SCALE", "2")

hl.monitor({ output = "",     mode = "preferred", position = "auto", scale = "auto" })
hl.monitor({ output = "DP-1", mode = "preferred", position = "auto", scale = 1.6 })
hl.monitor({ output = "DP-3", mode = "3440x1440@143.99Hz", position = "0x0", scale = 1.25, transform = 0 })

-- Pin Hyprland to the AMD iGPU on this hybrid laptop (RTX 4070 Max-Q + AMD).
-- Ported from the legacy hyprland.conf; Omarchy's nvidia.lua does not set this.
hl.env("AQ_DRM_DEVICES", "/dev/dri/amd-igpu")

hl.monitor({ output = "eDP-2", mode = "2880x1800@120.00Hz", position = "2048x0", scale = 2, transform = 0 })
