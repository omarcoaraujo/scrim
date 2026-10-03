--// Services
const HttpService = game:GetService "HttpService"
const Players = game:GetService "Players"

--// Modules
const context = require "./context"

--// Constants
const RESULT_PREFIX = "[scrim:result] "
const ERROR_PREFIX = "[scrim:error] "
const PLAYERS_TIMEOUT = 60

--// Types
export type spec = { name: string?, players: number?, run: (ctx: context.context) -> () }
export type options = { specs: Instance, players: number? }

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

const function report(passed: number, skipped: number, failures: { failure })
	print(
		RESULT_PREFIX
			.. HttpService:JSONEncode { passed = passed, failed = #failures, skipped = skipped, failures = failures }
	)
end

const function finish(failed: boolean)
	const service = game:GetService "StudioTestService"
	service:EndTest(not failed)
end

const function run(options: options)
	const specs = load(options.specs)

	local needed = 0
	for _, loaded in specs do
		needed = math.max(needed, loaded.spec.players or 1)
	end

	const available = options.players or needed
	const ready, err = pcall(wait_players :: (number) -> any, available)

	if not ready then
		print(ERROR_PREFIX .. tostring(err))
		finish(true)
		return
	end

	local passed = 0
	local skipped = 0
	const failures = {} :: { failure }

	for _, loaded in specs do
		if (loaded.spec.players or 1) > available then
			skipped += 1
			continue
		end

		const ok, message = run_spec(loaded)

		if ok then
			passed += 1
		else
			table.insert(failures, { name = loaded.name, message = message or "failed" })
		end
	end

	report(passed, skipped, failures)
	finish(#failures > 0)
end

--// End
return table.freeze {
	run = run,
}
