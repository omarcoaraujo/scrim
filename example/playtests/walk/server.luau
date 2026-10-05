--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const scrim = require(ReplicatedStorage:WaitForChild "scrim")

--// Constants
const GOAL = Vector3.new(0, 3, 50)
const REACHED_Z = 45

--// Functions
const function run(ctx: scrim.context)
	const player = ctx.players[1]

	const function has_character()
		return player.Character ~= nil and player.Character.PrimaryPart ~= nil
	end

	const function reached_goal()
		return player.Character.PrimaryPart.Position.Z > REACHED_Z
	end

	ctx.eventually("the character spawns", has_character)
	ctx.ask(player, "walk_to", GOAL)
	ctx.eventually("the player reaches the goal", reached_goal)
end

--// End
return {
	name = "walk",
	players = 1,
	run = run,
}
