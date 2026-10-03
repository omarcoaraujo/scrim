--// Types
type status = "passed" | "failed" | "error" | "missing"
type decode = (string) -> any

export type failure = { name: string, message: string }
export type summary = { passed: number, failed: number, passes: { string }, failures: { failure } }
export type outcome = { status: status, summary: summary?, message: string? }

--// Constants
local RESULT_PREFIX = "[scrim:result] "
local ERROR_PREFIX = "[scrim:error] "

--// Functions
local function after(line: string, prefix: string): string?
	if line:sub(1, #prefix) ~= prefix then return nil end
	return line:sub(#prefix + 1)
end

local function parse(log: string, decode: decode): outcome
	local payload = nil :: string?

	for line in log:gmatch "[^\r\n]+" do
		local failure = after(line, ERROR_PREFIX)
		if failure then return { status = "error", message = failure } end
		payload = after(line, RESULT_PREFIX) or payload
	end

	if not payload then return { status = "missing", message = "Studio exited without a result" } end
	local ok, value = pcall(decode, payload)

	if not ok or type(value) ~= "table" then return { status = "error", message = `unreadable result: {payload}` } end
	local summary = {
		passed = value.passed or 0,
		failed = value.failed or 0,
		passes = value.passes or {},
		failures = value.failures or {},
	}

	return {
		status = if summary.failed == 0 then "passed" else "failed",
		summary = summary,
	}
end

local function combine(outcomes: { outcome }): outcome
	local summary = { passed = 0, failed = 0, passes = {}, failures = {} } :: summary
	local messages = {} :: { string }

	for _, outcome in outcomes do
		if outcome.summary then
			summary.passed += outcome.summary.passed
			summary.failed += outcome.summary.failed
			table.move(outcome.summary.passes, 1, #outcome.summary.passes, #summary.passes + 1, summary.passes)
			table.move(outcome.summary.failures, 1, #outcome.summary.failures, #summary.failures + 1, summary.failures)
		end

		if outcome.status == "error" or outcome.status == "missing" then
			table.insert(messages, outcome.message or outcome.status)
		end
	end

	if #outcomes == 0 then return { status = "missing", message = "no session ran" } end
	if #messages > 0 then return { status = "error", summary = summary, message = table.concat(messages, "; ") } end

	return { status = if summary.failed == 0 then "passed" else "failed", summary = summary }
end

local function exit_code(outcome: outcome)
	return if outcome.status == "passed" then 0 else 1
end

--// End
return table.freeze {
	parse = parse,
	combine = combine,
	exit_code = exit_code,
}
