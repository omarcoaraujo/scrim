--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const scrim = require(ReplicatedStorage:WaitForChild "scrim")

--// End
scrim.start {
	net = require(ReplicatedStorage:WaitForChild("playtests"):WaitForChild("net"):WaitForChild "client"),
}
