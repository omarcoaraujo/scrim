--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const scrim = require(ReplicatedStorage:WaitForChild "scrim")
const remotes = require "./remotes"

--// Constants
const SENT = 7

--// Types
type snapshot = { to_one: string, to_all: string, to_list: string, to_others: string }

--// Variables
const heard = {} :: { [Player]: number }

--// Functions
const function on_up(player: Player, value: number)
	heard[player] = value
end

const function run(ctx: scrim.context)
	const first, second = ctx.players[1], ctx.players[2]
	const connection = remotes.up.on_server(on_up)

	const function disconnect()
		connection:disconnect()
	end

	ctx.defer(disconnect)

	remotes.to_one.fire_client(first, 1)
	remotes.to_all.fire_all(2)
	remotes.to_list.fire_list({ second }, 3)
	remotes.to_others.fire_except(first, 4)

	const function matches(player: Player, expected: snapshot)
		const seen = ctx.ask(player, "snapshot") :: snapshot

		for name, value in expected do
			if seen[name] ~= value then return false end
		end

		return true
	end

	const function first_matches()
		return matches(first, { to_one = "1", to_all = "2", to_list = "", to_others = "" })
	end

	const function second_matches()
		return matches(second, { to_one = "", to_all = "2", to_list = "3", to_others = "4" })
	end

	const function server_heard()
		return heard[first] == SENT
	end

	ctx.eventually("the first player gets only fire_client, fire_all", first_matches)
	ctx.eventually("the second player gets fire_all, fire_list, fire_except", second_matches)

	ctx.ask(first, "send", SENT)
	ctx.eventually("the server hears fire_server", server_heard)
end

--// End
return {
	name = "net",
	players = 2,
	run = run,
}
