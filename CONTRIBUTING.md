# Contributing

Thanks for helping with Scrim.

## Setup

The tools are pinned in `rokit.toml`:

```sh
rokit install
cd cli && pesde install
```

## Layout

| Folder | What lives there |
|---|---|
| `src/` | The library, installed in the game (target `roblox`) |
| `cli/` | The Lune CLI that builds the place, launches Studio and reads the log (target `luau`) |
| `tests/cli/` | CLI specs, written with [Tint](https://github.com/omarcoaraujo/tint) style output and run by Lune |
| `tests/lib/` | Library specs, run inside Studio |
| `example/` | A small project that runs one spec end to end |

## Checks

```sh
stylua src cli tests example
lune run tests/cli
luau-lsp analyze --definitions=globalTypes.d.luau --sourcemap=sourcemap.json --ignore "**/luau_packages/**" src cli
```

`sourcemap.json` comes from `rojo sourcemap default.project.json --output sourcemap.json`, and `globalTypes.d.luau` from the [luau-lsp repository](https://github.com/JohnnyMorganz/luau-lsp/blob/main/scripts/globalTypes.d.luau).

The library specs need Studio:

```sh
rojo build test.project.json --output build/tests.rbxl
run-in-roblox --place build/tests.rbxl --script tests/lib/run.server.luau
```

Two things no spec reaches, so check them in a real Studio session when you touch them: behavior that depends on real replication, and the Studio launch flags. The `example/` project is the quickest way.

## Rules

- The library is generic. Nothing from a specific game belongs in `src/`.
- A spec fails by erroring, and `teardown` runs even then.
- The log protocol is the contract between the library and the CLI. The library ends the test with `StudioTestService:EndTest`, `cli/lib/boot.luau` prints it as `[scrim:result]` or `[scrim:error]`, and `cli/lib/result.luau` parses those lines. Change all three together, and keep `tests/cli` in sync.
- The CLI exits 0 only when every spec passed.
- Never trust the client in a query answer. The client reports what it sees, the spec decides on the server.

## Commits

Angular conventions (`feat`, `fix`, `docs`, `test`, `refactor`, `chore`, `ci`), subject line only.
