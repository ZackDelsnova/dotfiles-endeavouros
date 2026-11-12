-- general

hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 20,
		border_size = 1,
		col = {
			active_border = colors.active_border, -- was "rgba(ffffff33)"; set by hyprland.lua
			inactive_border = colors.inactive_border, -- was "rgba(ffffff11)"
		},
		layout = "dwindle",
		allow_tearing = true,
	},

	decoration = {
		rounding = 12,
		active_opacity = 1.0,
		inactive_opacity = 0.95,

		shadow = {
			enabled = true,
			range = 15,
			render_power = 3,
			color = colors.shadow, -- was "rgba(00000044)"
			offset = { 0, 0 },
		},

		blur = {
			enabled = true,
			size = 8,
			passes = 3,
			new_optimizations = true,
			xray = false,
		},
	},

	animations = {
		enabled = true,
	},

	misc = {
		disable_autoreload = false,
		mouse_move_enables_dpms = false,
	},
})

-- glass: blur behind translucent layer surfaces.
-- Namespaces verified with `hyprctl layers` (mako's layer is "notifications", not "mako";
-- the picker sets WlrLayershell.namespace = "hyprquickpaper" in shell.qml).
-- ignore_alpha 0.5: pixels below 50% opacity are not blurred, so fully transparent
-- regions (e.g. gaps between picker cards) don't smear the desktop.
for _, ns in ipairs({ "waybar", "wofi", "notifications", "hyprquickpaper" }) do
	hl.layer_rule({
		name = "glass-" .. ns,
		match = { namespace = "^" .. ns .. "$" },
		blur = true,
		ignore_alpha = 0.5,
	})
end
