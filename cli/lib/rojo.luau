--// Services
local process = require "@lune/process"

--// Functions
local function build(project: string, output: string): string?
	local result = process.exec("rojo", { "build", project, "--output", output })
	if result.ok then return nil end
	return `rojo build failed: {result.stderr}`
end

--// End
return table.freeze {
	build = build,
}
