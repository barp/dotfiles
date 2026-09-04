-- Ported from autostart.conf
-- Dropped: "dms run" (adopting omarchy-shell instead)

-- Disabled 2026-08-23: superseded by Omarchy 4 builtin clamshell handling
-- (switch:on/off:Lid Switch binds + omarchy-hyprland-monitor-watch).
-- o.exec_on_start("/etc/acpi/check-lid-on-startup.sh")
o.launch_on_start("fcitx5")
