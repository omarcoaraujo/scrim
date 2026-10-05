--// Services
const Players = game:GetService "Players"
const RunService = game:GetService "RunService"

--// Modules
const bots = require "./bots"
const remotes = require "./remotes"

--// Constants
const ASK_TIMEOUT = 30
const EVENTUALLY_TIMEOUT = 10

--// Types
export type context = {
	players: { Player },
	ask: (player: Player, query: string, ...any) -> any,
	walk: (player: Player, position: Vector3) -> boolean,

	eventually: (label: string, predicate: () -> any, timeout: number?) -> (),
	defer: (cleanup: () -> ()) -> (),
	finish: () -> never,
}

export type handle = { context: context, teardown: () -> { string } }
type pending = { thread: thread, player: Player }

--// Variables
local next_id = 0
const waiting = {} :: { [number]: pending }

const ready = {} :: { [Player]: true }
const finished = table.freeze {}

--// Functions
const function is_finish(value: any)
	return value == finished
end

const function wait_ready(players: { Player })
	const deadline = os.clock() + ASK_TIMEOUT

	for _, player in players do
		while not ready[player] do
			assert(player.Parent, `{player.Name} left before the client was ready`)
			assert(os.clock() < deadline, `client of {player.Name} never became ready`)
			task.wait()
		end
	end
end

const function expire(id: number, message: string)
	const entry = waiting[id]
	if not entry then return end

	waiting[id] = nil
	task.spawn(entry.thread, false, message)
end

const function on_ready(player: Player)
	ready[player] = true
end

const function on_answered(player: Player, id: number, ok: boolean, value: any)
	const entry = waiting[id]
	if not entry or entry.player ~= player then return end

	waiting[id] = nil
	task.spawn(entry.thread, ok, value)
end

const function on_player_removing(player: Player)
	ready[player] = nil
end

const function new(spec_name: string, players: { Player }): handle
	wait_ready(players)
	const cleanups = {} :: { () -> () }

	const function request(player: Player, path: string, query: string, ...: any): any
		next_id += 1
		const id = next_id

		waiting[id] = { thread = coroutine.running(), player = player }
		remotes.ask.fire_client(player, id, path, { ... })

		task.delay(ASK_TIMEOUT, expire, id, `ask "{query}" to {player.Name} timed out after {ASK_TIMEOUT}s`)
		const ok, value = coroutine.yield()

		if not ok then error(value, 0) end
		return value
	end

	const function ask(player: Player, query: string, ...: any): any
		return request(player, `{spec_name}/{query}`, query, ...)
	end

	const function walk(player: Player, position: Vector3): boolean
		return request(player, `{bots.namespace}/walk_to`, "walk_to", position)
	end

	const function eventually(label: string, predicate: () -> any, timeout: number?)
		const limit = timeout or EVENTUALLY_TIMEOUT
		const deadline = os.clock() + limit

		while not predicate() do
			if os.clock() >= deadline then error(`"{label}" did not happen within {limit}s`, 0) end
			RunService.Heartbeat:Wait()
		end
	end

	const function defer(cleanup: () -> ())
		table.insert(cleanups, cleanup)
	end

	const function finish(): never
		error(finished, 0)
	end

	const function teardown()
		const errors = {}

		for index = #cleanups, 1, -1 do
			const ok, err = pcall(cleanups[index] :: () -> any)
			if not ok then table.insert(errors, tostring(err)) end
		end

		table.clear(cleanups)
		return errors
	end

	return {
		context = {
			players = players,

			ask = ask,
			walk = walk,
			eventually = eventually,

			defer = defer,
			finish = finish,
		},

		teardown = teardown,
	}
end

--// Listeners
if RunService:IsServer() then
	remotes.ready.on_server(on_ready)
	remotes.answered.on_server(on_answered)
	Players.PlayerRemoving:Connect(on_player_removing)
end

--// End
return table.freeze {
	new = new,
	is_finish = is_finish,
}
