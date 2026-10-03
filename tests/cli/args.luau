local args = require "@cli/args"

local spec = {} :: { [string]: any }

function spec.should_use_defaults_without_flags()
	local options = args.parse {}

	assert(options)
	assert(options.specs == "./playtests")

	assert(options.runner == "studio")
	assert(options.verbose == false)
	assert(options.place == nil and options.filter == nil)
end

function spec.should_read_every_flag()
	local options =
		args.parse { "--specs", "tests", "--place", "123", "--runner", "cloud", "--filter", "walk", "--verbose" }

	assert(options)
	assert(options.specs == "tests")
	assert(options.place == "123")

	assert(options.runner == "cloud")
	assert(options.filter == "walk")
	assert(options.verbose == true)
end

function spec.should_accept_equals_syntax()
	local options = args.parse { "--filter=walk", "--runner=cloud" }
	assert(options and options.filter == "walk" and options.runner == "cloud")
end

function spec.should_reject_an_unknown_flag()
	local options, err = args.parse { "--players", "2" }
	assert(not options and err == "unknown flag --players")
end

function spec.should_reject_a_flag_without_value()
	local _, missing = args.parse { "--place" }
	local _, swallowed = args.parse { "--filter", "--verbose" }

	assert(missing == "--place needs a value")
	assert(swallowed == "--filter needs a value")
end

function spec.should_reject_a_bad_runner()
	local options, err = args.parse { "--runner", "docker" }
	assert(not options and err == '--runner must be studio or cloud, got "docker"')
end

function spec.should_reject_a_positional_argument()
	local options, err = args.parse { "playtests" }
	assert(not options and err == 'unexpected argument "playtests"')
end

return spec
