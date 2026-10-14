--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const scrim = require(ReplicatedStorage:WaitForChild "scrim")

--// Constants
const MIN_FPS = 25

--// Functions
const function run(ctx: scrim.context)
	const player = ctx.players[1]
	const fps = ctx.ask(player, "fps") :: number
	assert(fps >= MIN_FPS, `the client ran at {math.floor(fps)} fps, expected at least {MIN_FPS}`)
end

--// End
return {
	name = "fps",
	players = 1,
	
	fps = 30,
	run = run,
}
