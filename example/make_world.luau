--// Services
local fs = require "@lune/fs"
local process = require "@lune/process"
local roblox = require "@lune/roblox"

--// Constants
local OUTPUT = process.args[1] or "world.rbxl"

--// Functions
local function main()
	local game = roblox.Instance.new "DataModel"

	local baseplate = roblox.Instance.new "Part"
	baseplate.Name = "Baseplate"
	baseplate.Anchored = true
	baseplate.Size = roblox.Vector3.new(512, 20, 512)
	baseplate.Position = roblox.Vector3.new(0, -10, 0)
	baseplate.Parent = game:GetService "Workspace"

	local spawn_point = roblox.Instance.new "SpawnLocation"
	spawn_point.Anchored = true
	spawn_point.Size = roblox.Vector3.new(6, 1, 6)
	spawn_point.Position = roblox.Vector3.new(0, 0.5, 0)
	spawn_point.Parent = game:GetService "Workspace"

	local scripts = roblox.Instance.new "StarterPlayerScripts"
	scripts.Parent = game:GetService "StarterPlayer"

	fs.writeFile(OUTPUT, roblox.serializePlace(game))
end

--// End
main()
