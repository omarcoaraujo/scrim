--// Services
local fs = require "@lune/fs"

--// Types
export type spec = { name: string, folder: string, players: number }
export type group = { players: number, specs: { spec } }

--// Functions
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
	local by_players = {} :: { [number]: group }
	local groups = {} :: { group }

	for _, spec in specs do
		local entry = by_players[spec.players] :: group?

		if not entry then
			local created = { players = spec.players, specs = {} } :: group
			by_players[spec.players] = created

			table.insert(groups, created)
			entry = created
		end

		table.insert((entry :: group).specs, spec)
	end

	table.sort(groups, function(a, b)
		return a.players > b.players
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
		table.insert(found, { name = read_name(source) or entry, folder = folder, players = players })
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

	filter = filter,
	group = group,
	discover = discover,
}
