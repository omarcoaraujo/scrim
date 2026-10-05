# Changelog

## 0.1.1

- `ctx.walk(player, position)`: built-in bot walk with pathfinding and a `MoveTo` fallback, no client query needed. The spec still checks the position on the server.
- Errors logged during a spec are shown in the report.
- Studio windows open minimized on Windows. `--show` keeps them as they are.
- The `example/` walk spec uses `ctx.walk`.

## 0.1.0

First release.

- Library: `scrim.run` and `scrim.start`, with `ctx.ask`, `ctx.eventually`, `ctx.defer` and `ctx.finish`, and a typed `net` wrapper over RemoteEvents.
- CLI: builds the place with Rojo, merges it into a world place, launches Studio, reads the log and exits 0 only when every spec passed.
- Specs are grouped by player count, one Studio session per group.
- Flags: `--specs`, `--place`, `--project`, `--runner`, `--filter` and `--verbose`.
- An `example/` project with one spec.
