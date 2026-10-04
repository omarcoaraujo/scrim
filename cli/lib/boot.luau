--// Services
local serde = require "@lune/serde"

--// Constants
local TEMPLATE = [==[
const HttpService = game:GetService "HttpService"
const StudioTestService = game:GetService "StudioTestService"

const PLAYERS = __PLAYERS__
const ONLY = HttpService:JSONDecode [=[__ONLY__]=]

const ok, result = pcall(StudioTestService.ExecuteMultiplayerTestAsync, StudioTestService, PLAYERS, {
	scrim = true,
	players = PLAYERS,
	only = ONLY,
})

if not ok then
	print("[scrim:error] " .. tostring(result))
elseif typeof(result) ~= "table" then
	print("[scrim:error] the test ended without a summary: " .. tostring(result))
elseif result.error then
	print("[scrim:error] " .. tostring(result.error))
else
	print("[scrim:result] " .. HttpService:JSONEncode(result))
end
]==]

--// Functions
local function render(players: number, names: { string }): string
	local only = serde.encode("json", names)
	assert(not only:find("]=]", 1, true), "spec names cannot contain ]=]")

	return (TEMPLATE:gsub("__PLAYERS__", tostring(players)):gsub("__ONLY__", function()
		return only
	end))
end

--// End
return table.freeze {
	render = render,
}
