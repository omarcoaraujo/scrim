local specs = require "@cli/specs"
local spec = {} :: { [string]: any }

function spec.should_default_to_one_player()
	assert(specs.read_players 'return { name = "walk", run = function() end }' == 1)
end

function spec.should_read_a_literal_player_count()
	assert(specs.read_players 'return {\n\tname = "duel",\n\tplayers = 3,\n\trun = run,\n}' == 3)
	assert(specs.read_players "return { players = 2 }" == 2)
end

function spec.should_reject_a_non_literal_player_count()
	local players, err = specs.read_players "return { players = COUNT, run = run }"
	assert(players == nil and err == 'players must be a number literal, got "COUNT"')
end

function spec.should_ignore_player_comparisons()
	assert(specs.read_players "if ctx.players == 2 then end" == 1)
end

function spec.should_read_the_spec_name()
	assert(specs.read_name 'return { name = "walk", players = 2 }' == "walk")
	assert(specs.read_name "return { players = 2 }" == nil)
end

function spec.should_filter_by_substring()
	local all = {
		{ name = "walk/forward", folder = "a", players = 1 },
		{ name = "walk/back", folder = "b", players = 1 },
		{ name = "duel", folder = "c", players = 2 },
	}

	assert(#specs.filter(all, "walk") == 2)
	assert(#specs.filter(all, "nope") == 0)
	assert(#specs.filter(all, nil) == 3)
end

function spec.should_group_largest_first()
	local all = {
		{ name = "a", folder = "a", players = 1 },
		{ name = "b", folder = "b", players = 3 },
		{ name = "c", folder = "c", players = 1 },
		{ name = "d", folder = "d", players = 2 },
	}
	local groups = specs.group(all)

	assert(#groups == 3)
	assert(groups[1].players == 3 and groups[2].players == 2 and groups[3].players == 1)
	assert(#groups[3].specs == 2)
end

return spec
