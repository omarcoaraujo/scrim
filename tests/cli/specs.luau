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

function spec.should_read_a_literal_fps()
	assert(specs.read_fps 'return { name = "fps", fps = 30, run = run }' == 30)
	assert(specs.read_fps "return { players = 2 }" == nil)
	assert(specs.read_fps "const fps = ctx.ask(player, 'fps')" == nil)
end

function spec.should_group_with_the_highest_fps()
	local all = {
		{ name = "a", folder = "a", players = 1, fps = 30 },
		{ name = "b", folder = "b", players = 1, fps = 60 },
		{ name = "c", folder = "c", players = 1 },
	}

	assert(specs.group(all)[1].fps == 60)
end

function spec.should_read_a_literal_ping_and_jitter()
	local source = 'return { name = "lag", ping = 300, jitter = 40.5, run = run }'

	assert(specs.read_ping(source) == 300)
	assert(specs.read_jitter(source) == 40.5)
	
	assert(specs.read_ping "return { players = 2 }" == nil)
	assert(specs.read_ping "const ping = ctx.ask(player, 'ping')" == nil)
end

function spec.should_group_by_network_conditions()
	local all = {
		{ name = "a", folder = "a", players = 1 },
		{ name = "b", folder = "b", players = 1, ping = 300 },
		{ name = "c", folder = "c", players = 1, ping = 300 },
		{ name = "d", folder = "d", players = 1, ping = 300, jitter = 40 },
	}
	
	local groups = specs.group(all)

	assert(#groups == 3)
	assert(groups[1].ping == 0 and #groups[1].specs == 1)
	
	assert(groups[2].ping == 300 and groups[2].jitter == 0 and #groups[2].specs == 2)
	assert(groups[3].jitter == 40)
end

return spec
