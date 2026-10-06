--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const scrim = require(ReplicatedStorage:WaitForChild "scrim")

--// Constants
const GOAL = Vector3.new(0, 3, 15)
const HOME = Vector3.new(0, 3, 0)
const MAX_DISTANCE = 6
const SHORT_TIMEOUT = 0.05

--// Functions
const function run(ctx: scrim.context)
	const player = ctx.players[1]

	const function has_character()
		return player.Character ~= nil and player.Character.PrimaryPart ~= nil
	end

	const function distance_to(position: Vector3): number
		const here = player.Character.PrimaryPart.Position
		return (Vector3.new(here.X, 0, here.Z) - Vector3.new(position.X, 0, position.Z)).Magnitude
	end

	ctx.eventually("the character spawns", has_character)

	assert(ctx.walk(player, GOAL) == true, "the bot should report that it arrived")
	assert(distance_to(GOAL) < MAX_DISTANCE, "the server does not see the player at the goal")

	const ok, message = pcall(ctx.walk, player, HOME, SHORT_TIMEOUT)
	assert(not ok, "a walk past its timeout should fail")
	assert(string.find(tostring(message), "timed out", 1, true), "the timeout should be reported")
end

--// End
return {
	name = "walk",
	players = 1,
	run = run,
}
