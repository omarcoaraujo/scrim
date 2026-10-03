--// Modules
const remotes = require "./remotes"

--// Types
export type queries = { [string]: (...any) -> any }

--// Variables
local specs = {} :: { [string]: queries }

--// Functions
const function answer(id: number, path: string, args: { any })
	const spec_name, query_name = string.match(path, "^(.-)/(.+)$")
	const queries = if spec_name then specs[spec_name] else nil
	const query = if queries and query_name then queries[query_name] else nil

	if not query then
		remotes.answered.fire_server(id, false, `no client query "{path}"`)
		return
	end

	const ok, value = pcall(query, table.unpack(args))
	remotes.answered.fire_server(id, ok, if ok then value else tostring(value))
end

const function on_ask(id: number, path: string, args: { any })
	task.spawn(answer, id, path, args)
end

const function start(registered: { [string]: queries })
	specs = registered

	remotes.ask.on_client(on_ask)
	remotes.ready.fire_server()
end

--// End
return table.freeze {
	start = start,
}
