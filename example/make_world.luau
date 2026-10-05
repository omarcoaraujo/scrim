--// Services
local fs = require "@lune/fs"
local process = require "@lune/process"
local roblox = require "@lune/roblox"

--// Constants
local OUTPUT = process.args[1] or "world.rbxl"
local WALL_Z = 25
local WALL_HEIGHT = 20
local WALLS = {
	{ from = -100, to = 20 },
	{ from = 40, to = 100 },
}

--// Functions
local function add_wall(parent, from, to)
	local wall = roblox.Instance.new "Part"
	wall.Name = "Wall"
	wall.Anchored = true
	wall.Size = roblox.Vector3.new(to - from, WALL_HEIGHT, 2)
	wall.CFrame = roblox.CFrame.new((from + to) / 2, WALL_HEIGHT / 2, WALL_Z)
	wall.Parent = parent
end

local function main()
	local game = roblox.Instance.new "DataModel"

	local baseplate = roblox.Instance.new "Part"
	baseplate.Name = "Baseplate"
	baseplate.Anchored = true
	baseplate.Size = roblox.Vector3.new(512, 20, 512)
	baseplate.CFrame = roblox.CFrame.new(0, -10, 0)
	baseplate.Parent = game:GetService "Workspace"

	local spawn_point = roblox.Instance.new "SpawnLocation"
	spawn_point.Anchored = true
	spawn_point.Size = roblox.Vector3.new(6, 1, 6)
	spawn_point.CFrame = roblox.CFrame.new(0, 0.5, 0)
	spawn_point.Parent = game:GetService "Workspace"

	for _, wall in WALLS do
		add_wall(game:GetService "Workspace", wall.from, wall.to)
	end

	local scripts = roblox.Instance.new "StarterPlayerScripts"
	scripts.Parent = game:GetService "StarterPlayer"

	fs.writeFile(OUTPUT, roblox.serializePlace(game))
end

--// End
main()
