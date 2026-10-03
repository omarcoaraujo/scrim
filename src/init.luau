--// Modules
const net = require "@self/net"
const client = require "@self/harness/client"
const context = require "@self/harness/context"
const server = require "@self/harness/server"

--// Types
export type context = context.context
export type spec = server.spec
export type queries = client.queries

--// End
return table.freeze {
	net = net,
	run = server.run,
	start = client.start,
}
