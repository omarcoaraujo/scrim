--// Services
local serde = require "@lune/serde"

--// Constants
local TEMPLATE = [==[
const HttpService = game:GetService "HttpService"
const StudioTestService = game:GetService "StudioTestService"

const PLAYERS = __PLAYERS__
const ONLY = HttpService:JSONDecode [=[__ONLY__]=]
const PING_MS = __PING__
const DELAY_MS = __DELAY__
const JITTER_MS = __JITTER__

const network = settings().Network
const original_inbound_delay = network.InboundNetworkMinDelayMs
const original_outbound_delay = network.OutboundNetworkMinDelayMs
const original_inbound_jitter = network.InboundNetworkJitterMs
const original_outbound_jitter = network.OutboundNetworkJitterMs

network.InboundNetworkMinDelayMs = DELAY_MS
network.OutboundNetworkMinDelayMs = DELAY_MS
network.InboundNetworkJitterMs = JITTER_MS
network.OutboundNetworkJitterMs = JITTER_MS

const ok, result = pcall(StudioTestService.ExecuteMultiplayerTestAsync, StudioTestService, PLAYERS, {
	scrim = true,
	players = PLAYERS,
	only = ONLY,
	ping = PING_MS,
	jitter = JITTER_MS,
})

network.InboundNetworkMinDelayMs = original_inbound_delay
network.OutboundNetworkMinDelayMs = original_outbound_delay
network.InboundNetworkJitterMs = original_inbound_jitter
network.OutboundNetworkJitterMs = original_outbound_jitter

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
local function one_way_delay(ping: number?): number
	return (ping or 0) / 2
end

local function render(players: number, names: { string }, ping: number?, jitter: number?): string
	local only = serde.encode("json", names)
	assert(not only:find("]=]", 1, true), "spec names cannot contain ]=]")

	return (
		TEMPLATE:gsub("__PLAYERS__", tostring(players))
			:gsub("__PING__", tostring(ping or 0))
			:gsub("__DELAY__", tostring(one_way_delay(ping)))
			:gsub("__JITTER__", tostring(jitter or 0))
			:gsub("__ONLY__", function()
				return only
			end)
	)
end

--// End
return table.freeze {
	one_way_delay = one_way_delay,
	render = render,
}
