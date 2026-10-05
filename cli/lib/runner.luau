--// Services
local fs = require "@lune/fs"
local process = require "@lune/process"

--// Modules
local args = require "./args"
local boot = require "./boot"
local cloud = require "./cloud"
local merge = require "./merge"
local rojo = require "./rojo"
local specs = require "./specs"
local studio = require "./studio"

--// Types
export type runner = (group: specs.group, options: args.options) -> string

--// Constants
local DIRECTORY = "build/scrim"
local KEY_VARIABLE = "ROBLOX_API_KEY"

--// Variables
local world = nil :: string?

--// Functions
local function failure(message: string): string
	return `[scrim:error] {message}`
end

local function load_world(place: string?): (string?, string?)
	if world then return world, nil end
	if not place then return nil, "--place is required" end

	if fs.isFile(place) then
		world = fs.readFile(place)
		return world, nil
	end

	local id = tonumber(place)
	if not id then return nil, `--place must be a file or a place id, got "{place}"` end

	local key = process.env[KEY_VARIABLE]
	if not key then return nil, `{KEY_VARIABLE} is not set, it needs the legacy-asset:manage scope` end

	local bytes, err = cloud.download(key, id)
	world = bytes

	return bytes, err
end

local function build_place(options: args.options): string?
	local bytes, err = load_world(options.place)
	if not bytes then return err end

	local code_path = `{DIRECTORY}/code.rbxl`
	local build_err = rojo.build(options.project, code_path)
	
	if build_err then return build_err end
	local ok, merged = pcall(merge.merge, bytes, fs.readFile(code_path))

	if not ok then return `could not merge the place: {merged}` end
	fs.writeFile(`{DIRECTORY}/place.rbxl`, merged)
	
	return nil
end

local function studio_runner(group: specs.group, options: args.options): string
	fs.writeDir(DIRECTORY)

	local build_err = build_place(options)
	if build_err then return failure(build_err) end

	local names = {}
	for _, spec in group.specs do
		table.insert(names, spec.name)
	end

	local output = `{DIRECTORY}/output.log`
	fs.writeFile(`{DIRECTORY}/boot.luau`, boot.render(group.players, names))
	if fs.isFile(output) then fs.removeFile(output) end

	local launch_err = studio.launch(`{DIRECTORY}/place.rbxl`, `{DIRECTORY}/boot.luau`, output)
	if launch_err then return failure(launch_err) end

	if not fs.isFile(output) then return failure "Studio exited without an output file" end
	return fs.readFile(output)
end

local function cloud_runner(group: specs.group, options: args.options): string
	return failure "cloud runner not implemented yet"
end

local function get(name: string): runner
	return if name == "cloud" then cloud_runner else studio_runner
end

--// End
return table.freeze {
	get = get,
}
