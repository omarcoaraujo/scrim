# Example

A baseplate and one spec, `walk`, that tells a bot to walk 50 studs and checks on the server that it got there.

```sh
lune run make_world
scrim --place world.rbxl
```

`make_world` writes `world.rbxl`, a baseplate with a spawn. Run it once. Run `scrim` from this folder, because the CLI reads `default.project.json` and `playtests/` from the current directory.

| File | What it does |
|---|---|
| `playtests/walk/server.luau` | The spec, decides pass or fail |
| `run_specs.server.luau` | Runs the specs in the server |
| `start_client.client.luau` | Starts the client |
