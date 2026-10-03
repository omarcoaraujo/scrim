--// Services
local net = require "@lune/net"
local serde = require "@lune/serde"

--// Types
type response = { ok: boolean, statusCode: number, statusMessage: string, body: string }
export type request = (options: { url: string, headers: { [string]: string }? }) -> response

--// Constants
local DELIVERY_URL = "https://apis.roblox.com/asset-delivery-api/v1/assetId/"

--// Functions
local function decode(text: string): any
	return serde.decode("json", text)
end

local function failure(label: string, res: response): string
	return `{label} failed ({res.statusCode}): {res.statusMessage}`
end

local function download(api_key: string, place_id: number, send: request?): (string?, string?)
	local request = send or (net.request :: any) :: request
	local located = request { url = DELIVERY_URL .. place_id, headers = { ["x-api-key"] = api_key } }
	if not located.ok then return nil, failure("place lookup", located) end

	local ok, body = pcall(decode, located.body)
	if not ok or type(body) ~= "table" or type(body.location) ~= "string" then
		return nil, "place lookup returned no download location"
	end

	local file = request { url = body.location }
	if not file.ok then return nil, failure("place download", file) end

	return file.body, nil
end

--// End
return table.freeze {
	download = download,
}
