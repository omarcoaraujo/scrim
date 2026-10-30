--// Modules
const context = require "../scrim/harness/context"
const latency = require "../scrim/harness/latency"

--// Variables
const spec = {} :: { [string]: () -> () }

--// Functions
function spec.should_allow_the_ping_plus_the_jitter_of_both_directions()
	assert(latency.allowance(300, 40) == 0.38)
	assert(latency.allowance(300, nil) == 0.3)
end

function spec.should_allow_nothing_without_latency()
	assert(latency.allowance(nil, nil) == 0)
	assert(latency.allowance(0, 0) == 0)
end

function spec.should_wait_the_allowance_on_top_of_the_eventually_timeout()
	const handle = context.new("slow", {}, 0.2)
	const started = os.clock()

	const ok = pcall(handle.context.eventually, "never", function()
		return false
	end, 0.1)

	assert(not ok)
	assert(os.clock() - started >= 0.3)
end

function spec.should_not_count_the_time_a_predicate_spends_when_there_is_latency()
	const handle = context.new("reading", {}, 0.05)
	local reads = 0

	handle.context.eventually("fourth read", function()
		reads += 1
		task.wait(0.1)
		return reads >= 4
	end, 0.1)

	assert(reads == 4)
end

--// End
return spec
