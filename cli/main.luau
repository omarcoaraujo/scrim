--// Services
local process = require "@lune/process"
local serde = require "@lune/serde"

--// Modules
local args = require "@cli/args"
local report = require "@cli/report"
local result = require "@cli/result"
local runner = require "@cli/runner"
local specs = require "@cli/specs"

--// Functions
local function decode(text: string)
	return serde.decode("json", text)
end

local function fail(message: string)
	print(`error: {message}`)
	process.exit(1)
end

local function main()
	local options, args_err = args.parse(process.args)
	if not options then return fail(args_err or "bad arguments") end

	local found, specs_err = specs.discover(options.specs, options.filter)
	if not found then return fail(specs_err or "no specs") end

	local run = runner.get(options.runner)
	local outcomes = {} :: { result.outcome }

	for _, group in specs.group(found) do
		print(report.header(group.players, #group.specs))

		local log = run(group, options)
		if options.verbose then print(log) end

		local outcome = result.parse(log, decode)
		table.insert(outcomes, outcome)
		print(report.lines(outcome))
	end

	local combined = result.combine(outcomes)
	print(`\n{report.total(combined)}`)
	process.exit(result.exit_code(combined))
end

main()
