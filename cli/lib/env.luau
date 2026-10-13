--// Services
local fs = require "@lune/fs"
local process = require "@lune/process"

--// Constants
local FILE = ".env"

--// Functions
local function unquote(value: string): string
	local quote = value:sub(1, 1)
	if (quote == '"' or quote == "'") and value:sub(-1) == quote and #value >= 2 then return value:sub(2, -2) end
	return value
end

local function parse(content: string): { [string]: string }
	local values = {} :: { [string]: string }

	for line in content:gmatch "[^\r\n]+" do
		local name, value = line:match "^%s*export%s+([%w_]+)%s*=%s*(.-)%s*$"

		if not name then
			name, value = line:match "^%s*([%w_]+)%s*=%s*(.-)%s*$"
		end

		if not name or not value then continue end
		values[name] = unquote(value)
	end

	return values
end

local function get(name: string, content: string?): string?
	local from_process = process.env[name]
	if from_process and from_process ~= "" then return from_process end

	local text = content
	if not text and fs.isFile(FILE) then text = fs.readFile(FILE) end
	if not text then return nil end

	local value = parse(text)[name]
	if value == "" then return nil end

	return value
end

--// End
return table.freeze {
	parse = parse,
	get = get,
}
