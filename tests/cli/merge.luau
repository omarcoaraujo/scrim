local merge = require "@cli/merge"
local roblox = require "@lune/roblox"
local spec = {} :: { [string]: any }

local function place(build: (roblox.DataModel) -> ())
	local game = roblox.Instance.new "DataModel"
	build(game)
	return roblox.serializePlace(game)
end

local function add(parent: roblox.Instance, class: string, name: string)
	local instance = roblox.Instance.new(class :: any)
	instance.Name = name
	instance.Parent = parent
end

function spec.should_keep_the_world_and_replace_the_code()
	local world = place(function(game)
		add(game:GetService "ReplicatedStorage", "Folder", "Map")
		add(game:GetService "ReplicatedStorage", "Folder", "Code")
		add(game:GetService "Workspace", "Part", "Floor")
	end)

	local code = place(function(game)
		add(game:GetService "ReplicatedStorage", "Configuration", "Code")
		add(game:GetService "ServerScriptService", "Folder", "Server")
	end)

	local merged = roblox.deserializePlace(merge.merge(world, code))
	local storage = merged:GetService "ReplicatedStorage"
	local replaced = storage:FindFirstChild "Code"

	assert(storage:FindFirstChild "Map")
	assert(replaced and replaced.ClassName == "Configuration")
	assert(merged:GetService("ServerScriptService"):FindFirstChild "Server")
	assert(merged:GetService("Workspace"):FindFirstChild "Floor")
end

return spec
