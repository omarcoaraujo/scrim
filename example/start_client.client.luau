--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const scrim = require(ReplicatedStorage:WaitForChild "scrim")

--// End
scrim.start {
	echo = require(ReplicatedStorage:WaitForChild("playtests"):WaitForChild("echo"):WaitForChild "client"),
}
