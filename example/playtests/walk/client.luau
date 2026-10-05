--// Services
const Players = game:GetService "Players"

--// Functions
const function walk_to(position: Vector3): boolean
	const player = Players.LocalPlayer
	const character = player.Character or player.CharacterAdded:Wait()
	const humanoid = character:WaitForChild "Humanoid" :: Humanoid

	humanoid:MoveTo(position)
	return humanoid.MoveToFinished:Wait()
end

--// End
return {
	walk_to = walk_to,
}
