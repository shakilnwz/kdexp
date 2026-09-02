-- Personal layout, decoration, and window rules.
-- Active/inactive border and shadow colors come from the active Omarchy theme.

hl.config({
	cursor = {
		no_warps = true,
		warp_on_change_workspace = 0,
	},

	general = {
		gaps_in = 0,
		gaps_out = 0,
		border_size = 1,
		layout = "scrolling",
	},

	decoration = {
		rounding = 10,

		blur = {
			enabled = true,
			size = 5,
			passes = 2,
			new_optimizations = true,
			vibrancy = 0.2,
			ignore_opacity = false,
		},

		shadow = {
			enabled = true,
			range = 16,
			render_power = 4,
			color = hl.get_config("general.col.active_border"),
			color_inactive = hl.get_config("general.col.inactive_border"),
		},
	},

	scrolling = {
		fullscreen_on_one_column = true,
		column_width = 1,
		focus_fit_method = 1,
		follow_focus = true,
		follow_min_visible = 0.1,
	},
})

-- Match workspace transitions to the window-focus timing.
hl.animation({ leaf = "workspaces", enabled = true, speed = 3.79, bezier = "easeOutQuint", style = "slide" })

----------------------
---- WINDOW RULES ----
----------------------

hl.window_rule({
	name = "keepass-window",
	match = { class = "org.keepassxc.KeePassXC" },
	float = true,
	pin = true,
})

hl.window_rule({
	name = "floating-window",
	match = { float = true },
	border_size = 2,
	rounding = 4,
	center = true,
})

hl.window_rule({
	name = "modal-window",
	match = { modal = true },
	border_size = 2,
	rounding = 4,
	float = true,
	center = true,
})

hl.window_rule({
	name = "tiled-window",
	match = { float = false },
	rounding = 0,
	no_shadow = true,
})

-------------------------
---- SLIDE FOCUS HELPER -
-------------------------

function slide_focus(step)
	local active_window = hl.get_active_window()
	if active_window == nil then
		return
	end

	local windows = {}
	for _, window in ipairs(hl.get_windows({ monitor = active_window.monitor, mapped = true })) do
		if window.workspace ~= nil and not window.workspace.special and not window.hidden then
			table.insert(windows, window)
		end
	end

	table.sort(windows, function(a, b)
		if a.workspace.id ~= b.workspace.id then
			return a.workspace.id < b.workspace.id
		end

		local a_at = type(a.at) == "table" and a.at or {}
		local b_at = type(b.at) == "table" and b.at or {}
		if (a_at.x or 0) ~= (b_at.x or 0) then
			return (a_at.x or 0) < (b_at.x or 0)
		end
		return (a_at.y or 0) < (b_at.y or 0)
	end)

	local current_index
	for index, window in ipairs(windows) do
		if window.address == active_window.address then
			current_index = index
			break
		end
	end
	if current_index == nil then
		return
	end

	local target = windows[(current_index - 1 + step) % #windows + 1]
	if target.workspace.id ~= active_window.workspace.id then
		hl.dispatch(hl.dsp.focus({ workspace = target.workspace, on_current_monitor = true }))
	end
	hl.dispatch(hl.dsp.focus({ window = target }))
end
