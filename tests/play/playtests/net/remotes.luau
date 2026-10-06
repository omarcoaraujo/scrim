--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const scrim = require(ReplicatedStorage:WaitForChild "scrim")

--// Constants
const NAMESPACE = "net_spec"

--// End
return scrim.net.remotes({
	to_one = scrim.net.event<<(number)>>(),
	to_all = scrim.net.event<<(number)>>(),
	to_list = scrim.net.event<<(number)>>(),
	to_others = scrim.net.event<<(number)>>(),
	up = scrim.net.event<<(number)>>(),
}, NAMESPACE)
