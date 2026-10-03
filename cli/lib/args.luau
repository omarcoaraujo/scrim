--// Types
type runner = "studio" | "cloud"
export type options = {
	specs: string,
	place: string?,

	runner: runner,
	filter: string?,
	verbose: boolean,
}

--// Constants
local DEFAULT_SPECS = "./playtests"
local VALUE_FLAGS = { specs = true, place = true, runner = true, filter = true }
local RUNNERS = { studio = true, cloud = true }

--// Functions
local function split(argument: string): (string?, string?)
	local name, value = argument:match "^%-%-([%w%-]+)=(.*)$"
	if name then return name, value end
	return argument:match "^%-%-([%w%-]+)$", nil
end

local function parse(argv: { string }): (options?, string?)
	local options = { specs = DEFAULT_SPECS, runner = "studio", verbose = false } :: options
	local values = {} :: { [string]: string }
	local index = 1

	while index <= #argv do
		local name, inline = split(argv[index])
		if not name then return nil, `unexpected argument "{argv[index]}"` end

		if name == "verbose" then
			if inline then return nil, "--verbose takes no value" end
			options.verbose = true
		elseif VALUE_FLAGS[name] then
			local value = inline
			if not value then
				index += 1
				value = argv[index]
			end

			if not value or value:sub(1, 2) == "--" then return nil, `--{name} needs a value` end
			values[name] = value
		else
			return nil, `unknown flag --{name}`
		end

		index += 1
	end

	if values.runner and not RUNNERS[values.runner] then
		return nil, `--runner must be studio or cloud, got "{values.runner}"`
	end

	options.specs = values.specs or options.specs
	options.place = values.place

	options.runner = (values.runner or options.runner) :: runner
	options.filter = values.filter

	return options, nil
end

--// End
return table.freeze {
	parse = parse,
}
