--// Services
local fs = require "@lune/fs"

--// Types
export type spec = {
	name: string,
	folder: string,

	players: number,
	fps: number?,

	ping: number?,
	jitter: number?,
}

export type group = {
	players: number,
	fps: number?,
	ping: number,

	jitter: number,
	specs: { spec },
}

--// Functions
local function read_number(source: string, key: string): number?
	local value = source:match(`%f[%w_]{key}%s*=%s*(%d+%.?%d*)%s*[,}\r\n]`)
	return if value then tonumber(value) else nil
end

local function read_fps(source: string): number?
	return read_number(source, "fps")
end

local function read_ping(source: string): number?
	return read_number(source, "ping")
end

local function read_jitter(source: string): number?
	return read_number(source, "jitter")
end

local function read_players(source: string): (number?, string?)
	local value = source:match "%f[%w_]players%s*=%s*([^=][^,}\r\n]*)"

	if not value then return 1, nil end
	local literal = value:match "^%s*(%d+)%s*$"

	if not literal then return nil, `players must be a number literal, got "{value:match "^%s*(.-)%s*$"}"` end
	return tonumber(literal), nil
end

local function read_name(source: string): string?
	return source:match '%f[%w_]name%s*=%s*"([^"]+)"'
end

local function filter(specs: { spec }, substring: string?): { spec }
	if not substring then return specs end
	local matched = {}

	for _, spec in specs do
		if spec.name:find(substring, 1, true) then table.insert(matched, spec) end
	end

	return matched
end

local function group(specs: { spec }): { group }
	local by_key = {} :: { [string]: group }
	local groups = {} :: { group }

	for _, spec in specs do
		local key = `{spec.players}/{spec.ping or 0}/{spec.jitter or 0}`
		local entry = by_key[key] :: group?

		if not entry then
			local created = {
				players = spec.players,
				ping = spec.ping or 0,

				jitter = spec.jitter or 0,
				specs = {},
			} :: group

			by_key[key] = created
			table.insert(groups, created)
			entry = created
		end

		table.insert((entry :: group).specs, spec)
		if spec.fps then (entry :: group).fps = math.max((entry :: group).fps or 0, spec.fps) end
	end

	table.sort(groups, function(a, b)
		if a.players ~= b.players then return a.players > b.players end
		if a.ping ~= b.ping then return a.ping < b.ping end
		return a.jitter < b.jitter
	end)

	return groups
end

local function discover(root: string, substring: string?): ({ spec }?, string?)
	if not fs.isDir(root) then return nil, `specs folder not found: {root}` end
	local found = {} :: { spec }

	for _, entry in fs.readDir(root) do
		local folder = `{root}/{entry}`
		local path = `{folder}/server.luau`
		if not fs.isDir(folder) or not fs.isFile(path) then continue end

		local source = fs.readFile(path)
		local players, err = read_players(source)

		if not players then return nil, `{entry}: {err}` end
		table.insert(found, {
			name = read_name(source) or entry,
			folder = folder,
			players = players,

			fps = read_fps(source),
			ping = read_ping(source),
			jitter = read_jitter(source),
		})
	end

	if #found == 0 then return nil, `no specs found in {root}` end
	local matched = filter(found, substring)

	if #matched == 0 then return nil, `no spec matches "{substring}"` end
	table.sort(matched, function(a, b)
		return a.name < b.name
	end)

	return matched, nil
end

--// End
return table.freeze {
	read_players = read_players,
	read_name = read_name,
	read_fps = read_fps,

	read_ping = read_ping,
	read_jitter = read_jitter,

	filter = filter,
	group = group,
	discover = discover,
}
