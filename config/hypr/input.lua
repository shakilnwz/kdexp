-- Personal input configuration & trackpad gestures.

hl.config({
	input = {
		-- Change speed of keyboard repeat.
		repeat_rate = 50,
		repeat_delay = 200,

		-- Increase sensitivity for mouse/trackpad (default: 0).
		sensitivity = 1,

		touchpad = {
			-- Use natural (inverse) scrolling.
			natural_scroll = true,

			-- Use two-finger clicks for right-click instead of lower-right corner.
			clickfinger_behavior = false,

			-- Control the speed of your scrolling.
			scroll_factor = 1.5,

			-- Enable the touchpad while typing.
			disable_while_typing = true,
		},
	},
})

-- 3-finger swipe to move focus between windows (workspace-agnostic & monitor-aware)
hl.gesture({
	fingers = 3,
	direction = "left",
	action = function()
		if type(slide_focus) == "function" then
			slide_focus(1)
		end
	end,
})

hl.gesture({
	fingers = 3,
	direction = "right",
	action = function()
		if type(slide_focus) == "function" then
			slide_focus(-1)
		end
	end,
})

hl.gesture({
	fingers = 3,
	direction = "up",
	action = function()
		if type(slide_focus) == "function" then
			slide_focus(-1)
		end
	end,
})

hl.gesture({
	fingers = 3,
	direction = "down",
	action = function()
		if type(slide_focus) == "function" then
			slide_focus(1)
		end
	end,
})

-- 4-finger horizontal swipe: continuous 1:1 workspace switching
hl.gesture({
	fingers = 4,
	direction = "horizontal",
	action = "workspace",
})
