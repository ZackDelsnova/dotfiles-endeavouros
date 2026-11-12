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
			enabled = false,
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
