-- Dual-monitor setup: external HDMI-A-2 above laptop eDP-1.
-- Run `hyprctl monitors all` to list current outputs and supported modes.

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- External 1920x1080 display (HDMI-A-2) on top of the laptop display (60Hz, 1x scale)
hl.monitor({
	output = "HDMI-A-2",
	mode = "1920x1080@60",
	position = "auto-up",
	scale = omarchy_monitor_scale,
})

-- Laptop built-in display (eDP-1)
hl.monitor({
	output = "eDP-1",
	mode = "1920x1080@60",
	position = "auto-down",
	scale = omarchy_monitor_scale,
})

-- Fallback for any other display
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto-up",
	scale = omarchy_monitor_scale,
})
