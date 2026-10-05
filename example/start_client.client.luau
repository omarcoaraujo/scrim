--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const scrim = require(ReplicatedStorage:WaitForChild "scrim")
const playtests = ReplicatedStorage:WaitForChild "playtests"
const walk = require(playtests:WaitForChild("walk"):WaitForChild "client")

--// End
scrim.start {
	walk = walk,
}
