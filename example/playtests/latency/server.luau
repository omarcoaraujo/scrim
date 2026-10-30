--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const scrim = require(ReplicatedStorage:WaitForChild "scrim")

--// Constants
const MIN_ROUND_TRIP_MS = 300
const SAMPLES = 5
const SHORT_TIMEOUT = 0.1

--// Functions
const function round_trip_ms(ctx: scrim.context, player: Player): number
	local fastest = math.huge

	for _ = 1, SAMPLES do
		const started = os.clock()
		ctx.ask(player, "echo", true)
		fastest = math.min(fastest, os.clock() - started)
	end

	return fastest * 1000
end

const function run(ctx: scrim.context)
	const player = ctx.players[1]
	const measured = round_trip_ms(ctx, player)
	assert(
		measured >= MIN_ROUND_TRIP_MS,
		`the round trip took {math.floor(measured)} ms, expected at least {MIN_ROUND_TRIP_MS} ms`
	)

	local answers = 0
	ctx.eventually("two answers arrive", function()
		answers += if ctx.ask(player, "echo", true) == true then 1 else 0
		return answers >= 2
	end, SHORT_TIMEOUT)
end

--// End
return {
	name = "latency",
	players = 1,

	ping = 300,
	run = run,
}
