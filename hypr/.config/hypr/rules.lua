-- window rules

hl.window_rule({
	name = "float-dialogs",
	match = {
		class = "^(pavucontrol|blueman-manager|nm-connection-editor|firefox|org\\.gnome\\.Nautilus|thunar)",
		title = ".*(Settings|Preferences|Properties).*|^Open File$|^Save As$",
	},
	float = false,
	rounding = 15,
	border_size = 2,
	no_blur = false,
})

hl.window_rule({
	name = "center-float",
	match = { float = true },
	center = true,
})
