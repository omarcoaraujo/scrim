--// Modules
const context = require "../scrim/harness/context"

--// Variables
const spec = {} :: { [string]: () -> () }

--// Functions
const function expect_error(callback: () -> (), fragment: string)
	const ok, err = pcall(callback)

	assert(not ok, "expected an error")
	assert(string.find(tostring(err), fragment, 1, true), `expected "{fragment}" in "{err}"`)
end

function spec.should_run_the_cleanups_in_reverse_order()
	const handle = context.new("order", {})
	const order = {} :: { number }

	for index = 1, 3 do
		handle.context.defer(function()
			table.insert(order, index)
		end)
	end

	assert(#handle.teardown() == 0)
	assert(table.concat(order, ",") == "3,2,1")
end

function spec.should_keep_tearing_down_after_a_failing_cleanup()
	const handle = context.new("failing", {})
	local ran = false

	handle.context.defer(function()
		ran = true
	end)
	handle.context.defer(function()
		error("boom", 0)
	end)

	const errors = handle.teardown()

	assert(ran)
	assert(#errors == 1 and errors[1] == "boom")
end

function spec.should_clear_the_cleanups_after_teardown()
	const handle = context.new("clear", {})
	local count = 0

	handle.context.defer(function()
		count += 1
	end)
	handle.teardown()
	handle.teardown()

	assert(count == 1)
end

function spec.should_finish_with_the_sentinel()
	const handle = context.new("finish", {})
	const ok, err = pcall(handle.context.finish)

	assert(not ok and context.is_finish(err))
	assert(not context.is_finish "something else")
end

function spec.should_return_when_the_predicate_becomes_true()
	const handle = context.new("eventually", {})
	local ticks = 0

	handle.context.eventually("third tick", function()
		ticks += 1
		return ticks >= 3
	end)

	assert(ticks == 3)
end

function spec.should_error_with_the_label_when_it_never_happens()
	const handle = context.new("timeout", {})

	expect_error(function()
		handle.context.eventually("never", function()
			return false
		end, 0.1)
	end, '"never" did not happen within 0.1s')
end

--// End
return spec
