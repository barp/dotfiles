-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- Video decode: use Mesa's radeonsi VA-API driver on the AMD iGPU instead of
-- the nvidia-vaapi-driver shim that Omarchy's default/hypr/nvidia.lua selects.
-- That shim (libva-nvidia-driver 0.0.17) deadlocks on H.264 here, which froze
-- H.264 video in Chrome/Slack (Patreon, X, Vimeo) while VP9/AV1 sites like
-- YouTube kept working. NVIDIA's own decode paths (NVDEC/cuvid/VDPAU) are fine,
-- so this is a shim bug, not a driver bug. Chrome already renders on the AMD
-- node (--render-node-override=/dev/dri/renderD129), which radeonsi decodes
-- H.264/VP9/AV1 on correctly.
-- Only VA-API video decode is affected: Vulkan/OpenGL/CUDA and games are not
-- (__GLX_VENDOR_LIBRARY_NAME stays "nvidia").
hl.env("LIBVA_DRIVER_NAME", "radeonsi")
