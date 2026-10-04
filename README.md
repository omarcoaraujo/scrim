# scrim

Integration testing for Roblox games, driven by bots.

A spec runs inside a real multiplayer Studio session. The server drives the test and asks each client to act through named queries. The server decides pass or fail, so a client is never trusted to report its own result.

- `src/` is the library, installed in your game (target `roblox`).
- `cli/` is a Lune CLI that builds the place, launches Studio, reads the log and sets the exit code.

## Install

The library comes from pesde:

```sh
pesde add omarcoaraujo/scrim
pesde install
```

The CLI needs [Lune](https://github.com/lune-org/lune), [Rojo](https://github.com/rojo-rbx/rojo) and Roblox Studio. Tools are pinned in `rokit.toml`.

## Writing a spec

A spec is a folder with two files.

`playtests/walk/server.luau` decides what happens:

```luau
return {
	name = "walk",
	players = 1,
	run = function(ctx)
		const player = ctx.players[1]

		ctx.ask(player, "walk_to", Vector3.new(0, 0, 50))
		ctx.eventually("player reaches the goal", function()
			return player.Character.PrimaryPart.Position.Z > 45
		end)
	end,
}
```

`playtests/walk/client.luau` returns the queries the server can ask:

```luau
return {
	walk_to = function(position: Vector3)
		-- move the local character
	end,
}
```

The context offers:

| Call | What it does |
|---|---|
| `ctx.players` | The players of this spec |
| `ctx.ask(player, query, ...)` | Runs a client query and returns its answer (30s timeout) |
| `ctx.eventually(label, predicate, timeout?)` | Polls until the predicate is truthy (10s by default) |
| `ctx.defer(cleanup)` | Registers a cleanup, run in reverse order even when the spec fails |
| `ctx.finish()` | Ends the spec early as a pass |

A spec fails by erroring. `players` defaults to 1.

## Wiring it in the game

A server script runs the specs, and a client script registers the queries by spec name:

```luau
-- server
const scrim = require(path.to.scrim)
scrim.run { specs = path.to.playtests }
```

```luau
-- client
const scrim = require(path.to.scrim)
scrim.start {
	walk = require(path.to.playtests.walk.client),
}
```

The project must expose the specs and these scripts through a Rojo `default.project.json` at the root.

## Running

```sh
export ROBLOX_API_KEY=...   # scope legacy-asset:manage, only needed when --place is an id
lune run cli/main --place world.rbxl
```

Flags, no config file:

| Flag | Meaning |
|---|---|
| `--specs <dir>` | Folder with the specs, `./playtests` by default; it must exist |
| `--place <file or id>` | The world place. A file is used as is; an id is downloaded through Open Cloud |
| `--runner studio\|cloud` | `studio` by default. `cloud` is not implemented yet |
| `--filter <text>` | Runs only the specs whose name contains the text |
| `--verbose` | Also prints the raw Studio log |

The CLI reads each spec's `players`, groups the specs by player count and opens one Studio session per group, from the largest group to the smallest. It exits 0 only when every spec passed.

## Development

```sh
stylua src cli tests                                     # format
luau-lsp analyze --sourcemap=sourcemap.json src cli     # type-check
lune run tests/cli                                       # CLI specs
```

## License

MIT
