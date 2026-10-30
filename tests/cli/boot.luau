local boot = require "@cli/boot"

local spec = {} :: { [string]: any }

function spec.should_embed_the_player_count_and_the_spec_names()
	local script = boot.render(3, { "walk", "duel/win" })

	assert(script:find("const PLAYERS = 3", 1, true))
	assert(script:find('[=[["walk","duel/win"]]=]', 1, true))
end

function spec.should_leave_no_placeholder()
	local script = boot.render(1, { "a" }, 300, 40)

	assert(not script:find("__PLAYERS__", 1, true))
	assert(not script:find("__ONLY__", 1, true))

	assert(not script:find("__DELAY__", 1, true))
	assert(not script:find("__JITTER__", 1, true))
end

function spec.should_split_the_ping_between_both_directions()
	assert(boot.one_way_delay(300) == 150)
	assert(boot.one_way_delay(nil) == 0)
end

function spec.should_embed_the_delay_and_the_jitter()
	local script = boot.render(1, { "a" }, 300, 40)
	assert(script:find("const DELAY_MS = 150", 1, true))
	assert(script:find("const JITTER_MS = 40", 1, true))
end

function spec.should_default_to_no_added_latency()
	local script = boot.render(1, { "a" })
	assert(script:find("const DELAY_MS = 0", 1, true))
	assert(script:find("const JITTER_MS = 0", 1, true))
end

function spec.should_reject_a_name_that_breaks_the_string()
	local ok = pcall(boot.render, 1, { "bad]=]name" })
	assert(not ok)
end

return spec
