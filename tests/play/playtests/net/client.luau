--// Modules
const remotes = require "./remotes"

--// Variables
const received = {
	to_one = {},
	to_all = {},
	to_list = {},
	to_others = {},
} :: { [string]: { number } }

--// Functions
const function on_to_one(value: number)
	table.insert(received.to_one, value)
end

const function on_to_all(value: number)
	table.insert(received.to_all, value)
end

const function on_to_list(value: number)
	table.insert(received.to_list, value)
end

const function on_to_others(value: number)
	table.insert(received.to_others, value)
end

const function snapshot(): { [string]: string }
	const copy = {} :: { [string]: string }

	for name, values in received do
		copy[name] = table.concat(values, ",")
	end

	return copy
end

const function send(value: number)
	remotes.up.fire_server(value)
end

--// Listeners
remotes.to_one.on_client(on_to_one)
remotes.to_all.on_client(on_to_all)
remotes.to_list.on_client(on_to_list)
remotes.to_others.on_client(on_to_others)

--// End
return {
	snapshot = snapshot,
	send = send,
}
