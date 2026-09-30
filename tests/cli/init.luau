local result = require "@cli/result"
local serde = require "@lune/serde"

local tint = require "@pkg/tint"
local spec = {} :: { [string]: any }

local function decode(text: string)
	return serde.decode("json", text)
end

function spec.should_pass_when_nothing_failed()
	local outcome =
		result.parse('[scrim] running\n[scrim:result] {"passed":2,"failed":0,"skipped":1,"failures":[]}\n', decode)

	assert(outcome.status == "passed")
	assert(outcome.summary and outcome.summary.passed == 2 and outcome.summary.skipped == 1)
	assert(result.exit_code(outcome) == 0)
end

function spec.should_fail_and_keep_the_failures()
	local log = '[scrim:result] {"passed":1,"failed":1,"skipped":0,"failures":[{"name":"x","message":"boom"}]}'
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

local function is_test(name: string, value: any)
	return typeof(value) == "function" and name:sub(1, 7) == "should_"
end

local function get_sorted_keys()
	local keys = {}

	for key, value in spec do
		if is_test(key, value) then table.insert(keys, key) end
	end

	table.sort(keys)
	return keys
end

local keys = get_sorted_keys()
local total = #keys
local failed = 0

for _, name in keys do
	local success, errorMessage = pcall(spec[name])

	if not success then
		failed += 1
		print(`  {tint.red.bold "✗"} {tint.dim(name)} {tint.red(errorMessage)}`)
	end
end

if failed > 0 then error(`\n{tint.red.bold(`✗ {failed}/{total} tests failed!`)}`) end
print(`{tint.green.bold(`✓ {total}/{total}`)} all tests passed! \n`)
