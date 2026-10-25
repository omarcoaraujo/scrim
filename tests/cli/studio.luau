local studio = require "@cli/studio"

local spec = {} :: { [string]: any }

function spec.should_resolve_a_relative_path_against_the_cwd()
	assert(studio.absolute("C:/game/", "build/place.rbxl") == "C:/game/build/place.rbxl")
	assert(studio.absolute("/home/game", "./build/place.rbxl") == "/home/game/build/place.rbxl")
end

function spec.should_keep_an_absolute_path()
	assert(studio.absolute("C:/game", [[D:\out\place.rbxl]]) == [[D:\out\place.rbxl]])
	assert(studio.absolute("/home/game", "/tmp/place.rbxl") == "/tmp/place.rbxl")
end

function spec.should_pass_the_launch_flags()
	local args = studio.arguments("place.rbxl", "boot.luau", "output.log")

	assert(
		table.concat(args, " ")
			== "--task RunScript --localPlaceFile place.rbxl --runScriptFile boot.luau --outputFile output.log --quitAfterExecution"
	)
end

function spec.should_run_the_hider_script_without_a_profile_and_with_the_boot_script()
	local args = studio.hider_arguments("C:/game/build/hide.ps1", "C:/game/build/boot.luau")
	assert(
		table.concat(args, " ")
			== "-NoProfile -ExecutionPolicy Bypass -File C:/game/build/hide.ps1 C:/game/build/boot.luau"
	)
end

function spec.should_launch_the_reaper_with_the_boot_script_and_pid_file()
	local args = studio.reaper_arguments("C:/game/build/reap.ps1", "C:/game/build/boot.luau", "C:/game/build/reap.pid")
	assert(
		table.concat(args, " ")
			== "-NoProfile -ExecutionPolicy Bypass -File C:/game/build/reap.ps1 -Launch -BootScript C:/game/build/boot.luau -PidFile C:/game/build/reap.pid"
	)
end

function spec.should_sweep_the_studios_spawned_by_the_launched_one()
	local args = studio.sweep_arguments("C:/game/build/reap.ps1", 9680)
	assert(table.concat(args, " ") == "-NoProfile -ExecutionPolicy Bypass -File C:/game/build/reap.ps1 -SweepId 9680")
end

function spec.should_keep_the_pid_file_next_to_the_reaper()
	assert(studio.pid_file "C:/game/build/reap.ps1" == "C:/game/build/reap.pid")
end

function spec.should_read_the_launched_studio_id_from_the_pid_file()
	assert(studio.root_id "9680\r\n" == 9680)
	assert(studio.root_id "" == nil)
end

function spec.should_raise_the_cap_to_four_times_the_wanted_fps()
	assert(studio.framerate_cap(30) == 120)
end

function spec.should_replace_only_the_framerate_cap_setting()
	local settings = '<int name="Other">5</int>\n<int name="FramerateCap">-1</int>'
	assert(studio.with_framerate_cap(settings, 120) == '<int name="Other">5</int>\n<int name="FramerateCap">120</int>')
end

function spec.should_leave_settings_without_a_cap_alone()
	assert(studio.with_framerate_cap('<int name="Other">5</int>', 120) == nil)
end

return spec
