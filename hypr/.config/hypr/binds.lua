-- keybinds

local mod = "SUPER" -- windows main modifier

-- screenshot and recordin stuffs
local screenshotDir = os.getenv("HOME") .. "/Pictures/Screenshots"
local recordingDir = os.getenv("HOME") .. "/Videos/Screenrecording"

hl.env("HYPRSHOT_DIR", screenshotDir)

local fullScreenSS = "hyprshot -m output -z"
local windowSS = "hyprshot -m window -z"
local areaSS = "hyprshot -m region -z"

-- exec_cmd already runs through a shell, so no `sh -c` wrapper (its single quotes broke the
-- inner notify-send quoting). wf-recorder blocks until stopped, so it is backgrounded and the
-- "started" notification fires right away. Cancelling slurp (Esc) aborts without recording.
local toggleRecording = string.format(
	"if pgrep -x wf-recorder >/dev/null; then "
		.. "pkill -INT -x wf-recorder; "
		.. "notify-send 'Screen Recorder' 'Recording stopped and saved successfully' -i video-x-generic; "
		.. "else "
		.. "mkdir -p '%s' && "
		.. "notify-send 'Screen Recorder' 'Select an area to start recording...' -i video-x-generic && "
		.. 'geom="$(slurp)" && '
		.. '{ wf-recorder --audio -g "$geom" '
		.. '-f "%s/recording-$(date +%%Y-%%m-%%d_%%H-%%M-%%S).mp4" & } && '
		.. "notify-send 'Screen Recorder' 'Recording started' -i video-x-generic; "
		.. "fi",
	recordingDir,
	recordingDir
)

-- closing
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + Q", hl.dsp.window.kill())
-- logout
hl.bind(
	mod .. " + M",
	hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
)

-- lock
hl.bind(mod .. " + N", hl.dsp.exec_cmd("hyprlock"), { release = true }) -- SUPER+N locks (SUPER+L is focus right)

-- wallpaper
hl.bind(mod .. " + W", hl.dsp.exec_cmd("quickshell -c hyprquickpaper"))

-- apps
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(mod .. " + SHIFT + E", hl.dsp.exec_cmd("kitty yazi"))
hl.bind(mod .. " + D", hl.dsp.exec_cmd("pkill wofi || wofi --show drun"), { release = true })

-- screenshot and recordin
hl.bind(mod .. " + S", hl.dsp.exec_cmd(fullScreenSS))
hl.bind("" .. "Print", hl.dsp.exec_cmd(fullScreenSS))

-- Frozen area screenshot (SUPER + SHIFT + S or SHIFT + Print)
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd(areaSS))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(areaSS))

-- Optional: Active Window screenshot (SUPER + ALT + S)
hl.bind(mod .. " + ALT + S", hl.dsp.exec_cmd(windowSS))

-- Toggle recording (SUPER + ALT + R)
hl.bind(mod .. " + ALT + R", hl.dsp.exec_cmd(toggleRecording))

-- split (dwindle only)
hl.bind(mod .. " + P", hl.dsp.layout("togglesplit"))
-- float
hl.bind(mod .. " + F", hl.dsp.window.float({ action = "toggle" }))

-- move focus arrow keys + hjkl
hl.bind(mod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + down", hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mod + [0-9]
-- Move active window to a workspace with mod + SHIFT + [0-9]
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Move/resize windows with mod + LMB/RMB and dragging
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
