--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const scrim = require(ReplicatedStorage:WaitForChild "scrim")

--// End
scrim.run { specs = ReplicatedStorage:WaitForChild "playtests" }
