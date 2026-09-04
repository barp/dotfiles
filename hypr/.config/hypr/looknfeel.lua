-- Ported from looknfeel.conf

hl.config({
  general = {
    gaps_in     = 5,
    gaps_out    = 5,
    border_size = 0,
    layout      = "dwindle",

    col = {
      active_border   = "rgba(707070ff)",
      inactive_border = "rgba(d0d0d0ff)",
    },
  },

  decoration = {
    rounding         = 12,
    active_opacity   = 1.0,
    inactive_opacity = 0.9,

    shadow = {
      enabled      = true,
      range        = 30,
      render_power = 5,
      offset       = "0 5",
      color        = "rgba(00000070)",
    },
  },
})

hl.layer_rule({ name = "no-anim-quickshell", match = { namespace = "^(quickshell)$" }, no_anim = true })

o.window("^(jetbrains-.)$", { match = { title = "^win(.)" }, no_initial_focus = true })
o.window("Emulator",        { float = true })

-- Inactive windows opacity
o.window({ float = false, focus = false }, { opacity = "0.9 0.9" })

o.window("^(Alacritty)$",   { opacity = 0.95 })

-- GNOME apps
o.window("^(org\\.gnome\\.)", { rounding = 12, border_size = 0 })

o.window("^(org\\.gnome\\.Nautilus)$",   { float = true })
o.window("^(org\\.gnome\\.Calculator)$", { float = true })

o.window("^(chrome-app\\.zoom.*)$", { opacity = 1 })

-- Unreal engine graph editor
local unreal = { class = "^(UnrealEditor)$", title = "^\\w*$" }
o.window(unreal, { no_initial_focus = true })
o.window(unreal, { no_anim = true })
