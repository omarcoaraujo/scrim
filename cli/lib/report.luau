--// Modules
local result = require "./result"
local tint = require "@pkg/tint"

--// Functions
local function indent(text: string): string
	return (text:gsub("[^\r\n]+", "      %0"))
end

local function plural(count: number, word: string): string
	return `{count} {word}{if count == 1 then "" else "s"}`
end

local function header(players: number, specs: number): string
	return tint.dim(`▸ {plural(players, "player")} · {plural(specs, "spec")}`)
end

local function lines(outcome: result.outcome): string
	local out = {} :: { string }

	if outcome.summary then
		for _, name in outcome.summary.passes do
			table.insert(out, `  {tint.green "✓"} {name}`)
		end

		for _, failure in outcome.summary.failures do
			table.insert(out, `  {tint.red "✗"} {failure.name}`)
			table.insert(out, tint.dim(indent(failure.message)))
		end

		for _, logged in outcome.summary.errors do
			table.insert(out, `  {tint.yellow "!"} {logged.name} logged errors`)
			table.insert(out, tint.dim(indent(logged.message)))
		end
	end

	if outcome.status == "error" or outcome.status == "missing" then
		table.insert(out, `  {tint.red "✗"} {tint.red(outcome.message or outcome.status)}`)
	end

	return table.concat(out, "\n")
end

local function total(outcome: result.outcome): string
	local passed = if outcome.summary then outcome.summary.passed else 0
	local failed = if outcome.summary then outcome.summary.failed else 0
	local text = `{passed} passed, {failed} failed`

	if outcome.status == "passed" then return tint.green.bold(`✓ {text}`) end
	if outcome.status == "failed" then return tint.red.bold(`✗ {text}`) end

	return tint.red.bold(`✗ {text}, {outcome.status}`)
end

--// End
return table.freeze {
	header = header,
	lines = lines,
	total = total,
}
