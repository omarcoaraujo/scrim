--// Services
local fs = require "@lune/fs"
local process = require "@lune/process"

--// Constants
local MAC_EXECUTABLE = "/Applications/RobloxStudio.app/Contents/MacOS/RobloxStudio"
local WINDOWS_EXECUTABLE = "RobloxStudioBeta.exe"

--// Functions
local function absolute(cwd: string, path: string): string
	if path:match "^%a:[/\\]" or path:sub(1, 1) == "/" then return path end
	local base = cwd:gsub("[/\\]+$", "")
	return `{base}/{path:gsub("^%./", "")}`
end

local function arguments(place: string, boot: string, output: string): { string }
	return {
		"--task",
		"RunScript",
		"--localPlaceFile",
		place,
		"--runScriptFile",
		boot,
		"--outputFile",
		output,
		"--quitAfterExecution",
	}
end

local function modified(path: string): number
	local date = fs.metadata(path).modifiedAt
	return if date then date.unixTimestamp else 0
end

local function newest_windows(): string?
	local root = `{process.env.LOCALAPPDATA or ""}/Roblox/Versions`
	if not fs.isDir(root) then return nil end

	local found, stamp = nil :: string?, -1

	for _, version in fs.readDir(root) do
		local path = `{root}/{version}/{WINDOWS_EXECUTABLE}`
		if not fs.isFile(path) or modified(path) <= stamp then continue end

		found, stamp = path, modified(path)
	end

	return found
end

local function executable(): string?
	if process.os == "windows" then return newest_windows() end
	if process.os == "macos" and fs.isFile(MAC_EXECUTABLE) then return MAC_EXECUTABLE end

	return nil
end

local function launch(place: string, boot: string, output: string): string?
	local program = executable()
	if not program then return "Roblox Studio is not installed" end

	local cwd = process.cwd
	local result = process.exec(program, arguments(absolute(cwd, place), absolute(cwd, boot), absolute(cwd, output)))

	if result.ok then return nil end
	return `Studio exited with code {result.code}: {result.stderr}`
end

--// End
return table.freeze {
	absolute = absolute,
	arguments = arguments,
	launch = launch,
}
