--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const scrim = require(ReplicatedStorage:WaitForChild "scrim")

--// Constants
const WORD = "scrim"
const MAX_DRIFT = 1

--// Functions
const function run(ctx: scrim.context)
	const player = ctx.players[1]

	const function has_character()
		return player.Character ~= nil and player.Character.PrimaryPart ~= nil
	end

	const function failure_of(query: string): string
		const ok, message = pcall(ctx.ask, player, query)
		assert(not ok, `"{query}" should have failed`)
		return tostring(message)
	end

	ctx.eventually("the character spawns", has_character)

	assert(ctx.ask(player, "echo", WORD) == WORD, "the client did not echo the word")
	assert(string.find(failure_of "missing", "no client query", 1, true), "an unknown query should be reported")
	assert(string.find(failure_of "explode", "boom", 1, true), "a query error should reach the server")

	const reported = ctx.ask(player, "position") :: Vector3
	const actual = player.Character.PrimaryPart.Position
	assert((reported - actual).Magnitude < MAX_DRIFT, "the client position does not match the server")
end

--// End
return {
	name = "echo",
	players = 1,
	run = run,
}
