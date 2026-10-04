local boot = require "@cli/boot"

local spec = {} :: { [string]: any }

function spec.should_embed_the_player_count_and_the_spec_names()
	local script = boot.render(3, { "walk", "duel/win" })

	assert(script:find("const PLAYERS = 3", 1, true))
	assert(script:find('[=[["walk","duel/win"]]=]', 1, true))
end

function spec.should_leave_no_placeholder()
	local script = boot.render(1, { "a" })

	assert(not script:find("__PLAYERS__", 1, true))
	assert(not script:find("__ONLY__", 1, true))
end

function spec.should_reject_a_name_that_breaks_the_string()
	local ok = pcall(boot.render, 1, { "bad]=]name" })
	assert(not ok)
end

return spec
