--// Modules
const net = require "../net"

--// End
return net.remotes({
	ready = net.event<<()>>(),
	ask = net.event<<(number, string, { any })>>(),
	answered = net.event<<(number, boolean, any)>>(),
}, "scrim")
