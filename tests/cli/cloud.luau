local cloud = require "@cli/cloud"

local spec = {} :: { [string]: any }

local function reply(ok: boolean, body: string, code: number?)
	return { ok = ok, statusCode = code or if ok then 200 else 500, statusMessage = "status", body = body }
end

function spec.should_follow_the_location_to_the_file()
	local urls = {}
	local keys = {}

	local function send(options: { url: string, headers: { [string]: string }? })
		table.insert(urls, options.url)
		table.insert(keys, options.headers and options.headers["x-api-key"])
		return if #urls == 1 then reply(true, '{"location":"https://cdn/file"}') else reply(true, "RBXL")
	end

	local bytes, err = cloud.download("key", 42, send)

	assert(bytes == "RBXL" and err == nil)
	assert(urls[1] == "https://apis.roblox.com/asset-delivery-api/v1/assetId/42" and urls[2] == "https://cdn/file")
	assert(keys[1] == "key" and keys[2] == nil)
end

function spec.should_report_a_failed_lookup()
	local bytes, err = cloud.download("key", 42, function()
		return reply(false, "", 403)
	end)

	assert(bytes == nil and err == "place lookup failed (403): status")
end

function spec.should_report_a_lookup_without_location()
	local bytes, err = cloud.download("key", 42, function()
		return reply(true, "{}")
	end)

	assert(bytes == nil and err == "place lookup returned no download location")
end

function spec.should_report_a_failed_download()
	local calls = 0
	local bytes, err = cloud.download("key", 42, function()
		calls += 1
		return if calls == 1 then reply(true, '{"location":"https://cdn/file"}') else reply(false, "", 404)
	end)

	assert(bytes == nil and err == "place download failed (404): status")
end

return spec
