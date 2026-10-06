# Scrim

Integration testing for Roblox games, driven by bots.

[![Check](https://github.com/omarcoaraujo/scrim/actions/workflows/check.yml/badge.svg)](https://github.com/omarcoaraujo/scrim/actions/workflows/check.yml) [![Release](https://github.com/omarcoaraujo/scrim/actions/workflows/release.yml/badge.svg)](https://github.com/omarcoaraujo/scrim/actions/workflows/release.yml)

---

## Features

- Specs run inside a real multiplayer Studio session, with real replication
- The server drives the test and asks each client to act through named queries
- The server decides pass or fail, a client is never trusted to report its own result
- A spec fails by erroring, and `defer` cleanups run in reverse order even then
- CLI that builds the place, launches Studio, reads the log and sets the exit code
- Specs are grouped by player count, one Studio session per group

## Installation

The library comes from pesde. Add it to your `pesde.toml`:

```toml
[dependencies]
scrim = { name = "omarcoaraujo/scrim", version = "^0.1.0" }
```

The CLI comes from the [releases](https://github.com/omarcoaraujo/scrim/releases). With [Rokit](https://github.com/rojo-rbx/rokit):

```sh
rokit add omarcoaraujo/scrim
```

It also needs [Rojo](https://github.com/rojo-rbx/rojo) and Roblox Studio.

## Usage

### Writing a spec

A spec is a folder with two files. `playtests/walk/server.luau` decides what happens:

```lua
return {
	name = "walk",
	players = 1,
	run = function(ctx)
		const player = ctx.players[1]

		ctx.walk(player, Vector3.new(0, 3, 50))
		ctx.eventually("the player reaches the goal", function()
			return player.Character.PrimaryPart.Position.Z > 45
		end)
	end,
}
```

`playtests/walk/client.luau` returns the queries the server can ask:

```lua
return {
	walk_to = function(position: Vector3)
		-- move the local character
	end,
}
```

`players` defaults to 1.

### Context

| Call | What it does |
|---|---|
| `ctx.players` | The players of this spec |
| `ctx.ask(player, query, ...)` | Runs a client query and returns its answer (30s timeout) |
| `ctx.walk(player, position, timeout?)` | Built-in: the bot walks to the position with pathfinding, returns whether it arrived. `timeout` defaults to 60s. The spec still checks the position on the server |
| `ctx.eventually(label, predicate, timeout?)` | Polls until the predicate is truthy (10s by default) |
| `ctx.defer(cleanup)` | Registers a cleanup, run in reverse order even when the spec fails |
| `ctx.finish()` | Ends the spec early as a pass |

### Wiring it in the game

A server script runs the specs:

```lua
const scrim = require(path.to.scrim)

scrim.run { specs = path.to.playtests }
```

A client script registers the queries by spec name:

```lua
const scrim = require(path.to.scrim)

scrim.start {
	walk = require(path.to.playtests.walk.client),
}
```

Expose the specs and both scripts through a Rojo project, `default.project.json` unless you pass `--project`. A complete project is in [`example/`](example).

### Running

```sh
scrim --place world.rbxl
```

| Flag | Meaning |
|---|---|
| `--specs <dir>` | Folder with the specs, `./playtests` by default |
| `--place <file or id>` | The world place. A file is used as is, an id is downloaded through Open Cloud |
| `--project <file>` | The Rojo project with the specs and scripts, `default.project.json` by default |
| `--runner studio` | Where the session runs. Only `studio` exists |
| `--filter <text>` | Runs only the specs whose name contains the text |
| `--verbose` | Also prints the raw Studio log |
| `--show` | Leaves the Studio windows as they open. By default they are minimized (Windows) so the bots play in the background |

Downloading a place by id needs `ROBLOX_API_KEY` with the `legacy-asset:manage` scope.

The CLI exits 0 only when every spec passed. A missing, unreadable or errored result counts as a failure.

## Limitations

- Scrim is pre-1.0, so the API can still change between minor versions.
- Sessions run in Roblox Studio on your machine, which needs to be installed.
- To run it in CI you need a runner with Studio installed, such as a self-hosted one.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT
