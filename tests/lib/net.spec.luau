--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const net = require "../scrim/net"

--// Variables
const spec = {} :: { [string]: () -> () }

--// Functions
const function expect_error(callback: () -> (), fragment: string)
	const ok, err = pcall(callback)

	assert(not ok, "expected an error")
	assert(string.find(tostring(err), fragment, 1, true), `expected "{fragment}" in "{err}"`)
end

function spec.should_create_the_remote_on_the_server()
	const remotes = net.remotes({ ping = net.event<<(number)>>() }, "lib_create")
	const connection = remotes.ping.on_server(function() end)

	assert(ReplicatedStorage:FindFirstChild("SCRIM_REMOTES"):FindFirstChild "lib_create.ping")
	connection:disconnect()
end

function spec.should_create_every_remote_when_the_definition_is_built()
	net.remotes({ idle = net.event<<()>>() }, "lib_eager")
	assert(ReplicatedStorage:FindFirstChild("SCRIM_REMOTES"):FindFirstChild "lib_eager.idle")
end

function spec.should_reject_client_only_calls_on_the_server()
	const remotes = net.remotes({ ping = net.event<<(number)>>() }, "lib_side")

	expect_error(function()
		remotes.ping.fire_server(1)
	end, "client-only")

	expect_error(function()
		remotes.ping.on_client(function() end)
	end, "client-only")
end

function spec.should_reject_a_bad_definition()
	expect_error(function()
		net.remotes({ ping = 1 } :: any, "lib_bad")
	end, "must be an event")
end

function spec.should_prefix_nested_events_with_the_namespace()
	const remotes = net.remotes({ group = { inner = net.event<<()>>() } }, "lib_nested")
	remotes.group.inner.fire_all()
	assert(ReplicatedStorage:FindFirstChild("SCRIM_REMOTES"):FindFirstChild "lib_nested.group.inner")
end

--// End
return spec
