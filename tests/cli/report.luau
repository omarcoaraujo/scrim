local report = require "@cli/report"

local spec = {} :: { [string]: any }

local function plain(text: string)
	return (text:gsub("\27%[[%d;]*m", ""))
end

function spec.should_list_passes_and_failures()
	local text = plain(report.lines {
		status = "failed",
		summary = {
			passed = 1,
			failed = 1,
			passes = { "walk" },
			failures = { { name = "duel", message = "boom\nat line 3" } },
		},
	})

	assert(text == "  ✓ walk\n  ✗ duel\n      boom\n      at line 3")
end

function spec.should_show_the_error_of_a_broken_session()
	local text = plain(report.lines { status = "error", message = "expected 3 players, got 1" })
	assert(text == "  ✗ expected 3 players, got 1")
end

function spec.should_summarise_the_total()
	local summary = { passed = 2, failed = 1, passes = {}, failures = {} }

	assert(plain(report.total { status = "failed", summary = summary }) == "✗ 2 passed, 1 failed")
	assert(plain(report.total { status = "passed", summary = summary }) == "✓ 2 passed, 1 failed")
	assert(plain(report.total { status = "missing", message = "x" }) == "✗ 0 passed, 0 failed, missing")
end

function spec.should_pluralise_the_group_header()
	assert(plain(report.header(1, 1)) == "▸ 1 player · 1 spec")
	assert(plain(report.header(3, 2)) == "▸ 3 players · 2 specs")
end

return spec
