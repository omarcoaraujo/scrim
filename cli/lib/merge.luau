--// Services
local roblox = require "@lune/roblox"

--// Constants
local CONTAINERS = { "ReplicatedStorage", "ReplicatedFirst", "ServerScriptService", "ServerStorage" }

--// Functions
local function replace(target: roblox.Instance, source: roblox.Instance)
	for _, child in source:GetChildren() do
		local stale = target:FindFirstChild(child.Name)
		if stale then stale:Destroy() end
		child:Clone().Parent = target
	end
end

local function merge(world_file: string, code_file: string): string
	local world = roblox.deserializePlace(world_file)
	local code = roblox.deserializePlace(code_file)

	for _, name in CONTAINERS do
		replace(world:GetService(name), code:GetService(name))
	end

	local world_scripts = world:GetService("StarterPlayer"):FindFirstChild "StarterPlayerScripts"
	local code_scripts = code:GetService("StarterPlayer"):FindFirstChild "StarterPlayerScripts"

	if world_scripts and code_scripts then replace(world_scripts, code_scripts) end
	return roblox.serializePlace(world)
end

--// End
return table.freeze {
	merge = merge,
}
