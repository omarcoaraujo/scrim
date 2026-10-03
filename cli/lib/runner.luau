--// Modules
local args = require "./args"
local specs = require "./specs"

--// Types
export type runner = (group: specs.group, options: args.options) -> string

--// Functions
local function studio(group: specs.group, options: args.options): string
	return "[scrim:error] studio runner not implemented yet"
end

local function cloud(group: specs.group, options: args.options): string
	return "[scrim:error] cloud runner not implemented yet"
end

local function get(name: string): runner
	return if name == "cloud" then cloud else studio
end

--// End
return table.freeze {
	get = get,
}
