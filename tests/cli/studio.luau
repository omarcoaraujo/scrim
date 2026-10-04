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

return spec
