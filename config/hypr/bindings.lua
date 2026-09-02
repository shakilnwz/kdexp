-- Personal keybindings — theme-independent, always active.

hl.bind("SUPER + Q", hl.dsp.window.close(), { description = "Close active window" })
hl.bind(
	"SUPER + ALT + Return",
	hl.dsp.exec_cmd('uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)" zsh -c "herdr"'),
	{ description = "Herdr" }
)
hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd("omarchy-launch-tui lazydocker"), { description = "Docker" })
hl.bind(
	"SUPER + SHIFT + ALT + O",
	hl.dsp.exec_cmd('omarchy-launch-or-focus ^obsidian$ "uwsm-app -- obsidian"'),
	{ description = "Obsidian" }
)
hl.bind(
	"SUPER + SHIFT + O",
	hl.dsp.exec_cmd("uwsm-app -- xdg-terminal-exec zsh -c vnote"),
	{ description = "Vnote" }
)
hl.bind("SUPER + SHIFT + slash", hl.dsp.exec_cmd("uwsm-app -- KeePassXC"), { description = "Passwords" })
hl.bind(
	"SUPER + backslash",
	hl.dsp.exec_cmd("uwsm-app -- xdg-terminal-exec zsh -c herdr-sessionizer"),
	{ description = "Herdr sessionizer" }
)
hl.bind(
	"SUPER + ALT + backslash",
	hl.dsp.exec_cmd("uwsm-app -- xdg-terminal-exec zsh -c 'herdr-sessionizer --dual'"),
	{ description = "Herdr Dual" }
)
hl.bind(
	"SUPER + SHIFT + backslash",
	hl.dsp.exec_cmd("uwsm-app -- xdg-terminal-exec zsh -c tmux-sessionizer"),
	{ description = "Tmux sessionizer" }
)
hl.bind(
	"XF86Display",
	hl.dsp.exec_cmd("cycle-display"),
	{ description = "Cycle display" }
)

-- Move active window with SUPER + SHIFT + arrow keys
hl.bind("SUPER + SHIFT + Left", hl.dsp.window.move({ direction = "left" }), { description = "Move window left" })
hl.bind("SUPER + SHIFT + Right", hl.dsp.window.move({ direction = "right" }), { description = "Move window right" })
hl.bind("SUPER + SHIFT + Up", hl.dsp.window.move({ direction = "up" }), { description = "Move window up" })
hl.bind("SUPER + SHIFT + Down", hl.dsp.window.move({ direction = "down" }), { description = "Move window down" })

-- Unbind Omarchy defaults for mouse wheel workspace switching and use slide_focus instead
hl.unbind("SUPER + mouse_up")
hl.unbind("SUPER + mouse_down")

hl.bind("SUPER + mouse_up", function()
	if type(slide_focus) == "function" then
		slide_focus(-1)
	end
end, { description = "Previous window on current monitor" })

hl.bind("SUPER + mouse_down", function()
	if type(slide_focus) == "function" then
		slide_focus(1)
	end
end, { description = "Next window on current monitor" })
