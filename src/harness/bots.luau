--// Services
const PathfindingService = game:GetService "PathfindingService"
const Players = game:GetService "Players"

--// Constants
const NAMESPACE = "scrim"
const AGENT = { AgentCanJump = true }

--// Types
export type queries = { [string]: (...any) -> any }

--// Functions
const function humanoid_of_local_player(): Humanoid
	const player = Players.LocalPlayer
	const character = player.Character or player.CharacterAdded:Wait()
	return character:WaitForChild "Humanoid" :: Humanoid
end

const function step(humanoid: Humanoid, waypoint: PathWaypoint): boolean
	if waypoint.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
	humanoid:MoveTo(waypoint.Position)
	return humanoid.MoveToFinished:Wait()
end

const function walk_to(position: Vector3): boolean
	const humanoid = humanoid_of_local_player()
	const path = PathfindingService:CreatePath(AGENT)
	const computed = pcall(path.ComputeAsync, path, (humanoid.RootPart :: BasePart).Position, position)

	if not computed or path.Status ~= Enum.PathStatus.Success then
		humanoid:MoveTo(position)
		return humanoid.MoveToFinished:Wait()
	end

	for _, waypoint in path:GetWaypoints() do
		if not step(humanoid, waypoint) then return false end
	end

	return true
end

--// End
return table.freeze {
	namespace = NAMESPACE,
	queries = table.freeze {
		walk_to = walk_to,
	} :: queries,
}
