local result = require "@cli/result"
local serde = require "@lune/serde"

local spec = {} :: { [string]: any }

local function decode(text: string)
	return serde.decode("json", text)
end

function spec.should_pass_when_nothing_failed()
	local outcome = result.parse(
		'[scrim] running\n[scrim:result] {"passed":2,"failed":0,"passes":["a","b"],"failures":[]}\n',
		decode
	)

	assert(outcome.status == "passed")
	assert(outcome.summary and outcome.summary.passed == 2)
	assert(outcome.summary and outcome.summary.passes[2] == "b")
	assert(result.exit_code(outcome) == 0)
end

function spec.should_fail_and_keep_the_failures()
	local log = '[scrim:result] {"passed":1,"failed":1,"failures":[{"name":"x","message":"boom"}]}'
	local outcome = result.parse(log, decode)

	assert(outcome.status == "failed")
	assert(outcome.summary and outcome.summary.failures[1].message == "boom")
	assert(result.exit_code(outcome) == 1)
end

function spec.should_report_an_error_line_over_a_result()
	local outcome = result.parse('[scrim:result] {"passed":1,"failed":0}\n[scrim:error] no players', decode)

	assert(outcome.status == "error" and outcome.message == "no players")
	assert(result.exit_code(outcome) == 1)
end

function spec.should_flag_a_missing_result()
	local outcome = result.parse("[scrim] running\n", decode)

	assert(outcome.status == "missing")
	assert(result.exit_code(outcome) == 1)
end

function spec.should_flag_unreadable_json()
	local outcome = result.parse("[scrim:result] {nope", decode)
	assert(outcome.status == "error")
end

function spec.should_sum_the_groups()
	local first = result.parse('[scrim:result] {"passed":2,"failed":0,"failures":[]}', decode)
	local second =
		result.parse('[scrim:result] {"passed":1,"failed":1,"failures":[{"name":"x","message":"boom"}]}', decode)
	local combined = result.combine { first, second }

	assert(combined.status == "failed")
	assert(combined.summary and combined.summary.passed == 3 and combined.summary.failed == 1)
	assert(#combined.summary.failures == 1)
	assert(result.exit_code(combined) == 1)
end

function spec.should_pass_only_when_every_group_passed()
	local ok = result.parse('[scrim:result] {"passed":1,"failed":0,"failures":[]}', decode)

	assert(result.combine({ ok, ok }).status == "passed")
	assert(result.exit_code(result.combine { ok, ok }) == 0)
end

function spec.should_fail_when_a_group_errored()
	local ok = result.parse('[scrim:result] {"passed":1,"failed":0,"failures":[]}', decode)
	local broken = result.parse("[scrim:error] no players", decode)
	local combined = result.combine { ok, broken }

	assert(combined.status == "error" and combined.message == "no players")
	assert(result.exit_code(combined) == 1)
end

function spec.should_fail_without_any_group()
	assert(result.exit_code(result.combine {}) == 1)
end

return spec
