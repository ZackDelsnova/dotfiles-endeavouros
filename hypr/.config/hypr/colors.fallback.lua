-- Fallback palette: Catppuccin Mocha (neutral dark).
-- COMMITTED. Loaded by hyprland.lua only when the matugen-generated colors.lua is missing or broken,
-- so a fresh clone boots with readable defaults. Keys must match templates/hyprland.lua.template.
-- Border/shadow alphas match the hand-tuned originals: active 0x33, inactive 0x11, shadow 0x44.
return {
	active_border = "rgba(b4befe33)", -- lavender
	inactive_border = "rgba(b4befe11)", -- lavender
	shadow = "rgba(11111b44)", -- crust

	primary = "#b4befe", -- lavender
	secondary = "#cba6f7", -- mauve
	tertiary = "#f9e2af", -- yellow
	surface = "#1e1e2e", -- base
	on_surface = "#cdd6f4", -- text
	outline = "#6c7086", -- overlay0
	error = "#f38ba8", -- red
}
