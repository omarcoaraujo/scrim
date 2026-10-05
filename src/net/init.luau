--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"
const RunService = game:GetService "RunService"

--// Constants
const FOLDER = "SCRIM_REMOTES"
const WAIT_TIMEOUT = 30

--// Types
export type connection = { disconnect: (self: connection) -> () }
type descriptor = { [any]: any, __scrim_event: true }

export type event<T...> = {
	on_server: ((player: Player, T...) -> ()) -> connection,
	on_client: ((T...) -> ()) -> connection,

	fire_server: (T...) -> (),
	fire_client: (player: Player, T...) -> (),
	fire_all: (T...) -> (),
	fire_list: (players: { Player }, T...) -> (),
	fire_except: (player: Player, T...) -> (),
}

--// Variables
const is_server = RunService:IsServer()
local folder = nil :: Folder?

--// Functions
const function get_folder()
	if folder then return folder end
	if not is_server then
		folder = ReplicatedStorage:WaitForChild(FOLDER, WAIT_TIMEOUT)
		return assert(folder, "scrim remotes folder was not replicated")
	end

	const created = ReplicatedStorage:FindFirstChild(FOLDER) or Instance.new "Folder"
	created.Name = FOLDER
	created.Parent = ReplicatedStorage

	folder = created
	return created
end

const function get_remote(path: string)
	const parent = get_folder()

	if is_server then
		const existing = parent:FindFirstChild(path)
		if existing then return existing :: RemoteEvent end

		const remote = Instance.new "RemoteEvent"
		remote.Name = path
		remote.Parent = parent

		return remote
	end

	return assert(parent:WaitForChild(path, WAIT_TIMEOUT), `scrim net: remote "{path}" never replicated`) :: RemoteEvent
end

const function wrap(signal: RBXScriptConnection)
	return {
		disconnect = function()
			signal:Disconnect()
		end,
	}
end

const function build_event(path: string): event<...any>
	local cached: RemoteEvent? = nil

	const function remote()
		if not cached then cached = get_remote(path) end
		return cached :: RemoteEvent
	end

	if is_server then remote() end

	const function server_only(what: string)
		assert(is_server, `scrim net: {path}.{what} is server-only`)
	end

	const function client_only(what: string)
		assert(not is_server, `scrim net: {path}.{what} is client-only`)
	end

	return {
		on_server = function(handler)
			server_only "on_server"
			return wrap(remote().OnServerEvent:Connect(handler))
		end,

		on_client = function(handler)
			client_only "on_client"
			return wrap(remote().OnClientEvent:Connect(handler))
		end,

		fire_server = function(...)
			client_only "fire_server"
			remote():FireServer(...)
		end,

		fire_client = function(player, ...)
			server_only "fire_client"
			remote():FireClient(player, ...)
		end,

		fire_all = function(...)
			server_only "fire_all"
			remote():FireAllClients(...)
		end,

		fire_list = function(players, ...)
			server_only "fire_list"

			for _, player in players do
				remote():FireClient(player, ...)
			end
		end,

		fire_except = function(except, ...)
			server_only "fire_except"

			for _, player in game:GetService("Players"):GetPlayers() do
				if player ~= except then remote():FireClient(player, ...) end
			end
		end,
	}
end

const function event<T...>(): event<T...>
	return { __scrim_event = true } :: any
end

const function resolve(definition: { [any]: any }, prefix: string)
	for key, value in definition do
		assert(type(key) == "string", "scrim net: remote names must be strings")
		const path = if prefix == "" then key else `{prefix}.{key}`

		if type(value) ~= "table" then error(`scrim net: "{path}" must be an event or a table of events`) end
		if value.__scrim_event then
			definition[key] = build_event(path)
		else
			resolve(value, path)
		end
	end

	return table.freeze(definition)
end

const function remotes<T>(definition: T, namespace: string?): T
	return resolve(definition :: any, namespace or "") :: any
end

--// End
return table.freeze {
	event = event,
	remotes = remotes,
}
