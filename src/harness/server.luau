--// Services
const Players = game:GetService "Players"

--// Modules
const context = require "./context"

--// Constants
const PLAYERS_TIMEOUT = 60

--// Types
export type spec = { name: string?, players: number?, run: (ctx: context.context) -> () }
export type options = { specs: Instance, players: number? }

type test_args = { players: number?, only: { string }? }
type failure = { name: string, message: string }
type loaded = { name: string, spec: spec }

--// Functions
const function load(folder: Instance): { loaded }
	const found = {} :: { loaded }

	for _, child in folder:GetChildren() do
		const module = child:FindFirstChild "server"
		if not module or not module:IsA "ModuleScript" then continue end

		const spec = require(module) :: spec
		table.insert(found, { name = spec.name or child.Name, spec = spec })
	end

	table.sort(found, function(a, b)
		return a.name < b.name
	end)

	return found
end

const function wait_players(count: number)
	const deadline = os.clock() + PLAYERS_TIMEOUT
	while #Players:GetPlayers() < count do
		assert(os.clock() < deadline, `expected {count} players, got {#Players:GetPlayers()}`)
		task.wait()
	end
end

const function run_spec(loaded: loaded): (boolean, string?)
	const players = Players:GetPlayers()
	const handle = context.new(loaded.name, table.move(players, 1, loaded.spec.players or 1, 1, {}))

	const ok, err = pcall(loaded.spec.run :: (context.context) -> any, handle.context)
	const errors = handle.teardown()

	if not ok and not context.is_finish(err) then return false, tostring(err) end
	if #errors > 0 then return false, `teardown failed: {table.concat(errors, "; ")}` end

	return true, nil
end

const function finish(result: { [string]: any })
	game:GetService("StudioTestService"):EndTest(result)
end

const function test_args(): test_args
	return game:GetService("StudioTestService"):GetTestArgs() or {}
end

const function select(specs: { loaded }, group: number?, only: { string }?): { loaded }
	const names = {} :: { [string]: true }

	if only then
		for _, name in only do
			names[name] = true
		end
	end

	const selected = {} :: { loaded }

	for _, loaded in specs do
		if group and (loaded.spec.players or 1) ~= group then continue end
		if only and not names[loaded.name] then continue end

		table.insert(selected, loaded)
	end

	return selected
end

const function run(options: options)
	const args = test_args()
	const group = options.players or args.players
	const specs = select(load(options.specs), group, args.only)
	local needed = 0

	for _, loaded in specs do
		needed = math.max(needed, loaded.spec.players or 1)
	end

	const ready, err = pcall(wait_players :: (number) -> any, group or needed)
	if not ready then
		finish { error = tostring(err) }
		return
	end

	const passes = {} :: { string }
	const failures = {} :: { failure }

	for _, loaded in specs do
		const ok, message = run_spec(loaded)

		if ok then
			table.insert(passes, loaded.name)
		else
			table.insert(failures, { name = loaded.name, message = message or "failed" })
		end
	end

	finish { passed = #passes, failed = #failures, passes = passes, failures = failures }
end

--// End
return table.freeze {
	run = run,
}
