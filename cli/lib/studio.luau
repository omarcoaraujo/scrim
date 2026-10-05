--// Services
local fs = require "@lune/fs"
local process = require "@lune/process"
local task = require "@lune/task"

--// Constants
local MAC_EXECUTABLE = "/Applications/RobloxStudio.app/Contents/MacOS/RobloxStudio"
local WINDOWS_EXECUTABLE = "RobloxStudioBeta.exe"
local MINIMIZER_HEAD_START = 1
local MINIMIZER_SCRIPT = [==[
$existing = @(Get-Process RobloxStudioBeta -ErrorAction SilentlyContinue | ForEach-Object Id)
Add-Type -Name Window -Namespace Studio -MemberDefinition '[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr handle, int command);'
$minimized = @{}
while ($true) {
	foreach ($process in Get-Process RobloxStudioBeta -ErrorAction SilentlyContinue) {
		if ($existing -contains $process.Id) { continue }
		$handle = $process.MainWindowHandle
		if ($handle -eq [IntPtr]::Zero -or $minimized.ContainsKey($handle)) { continue }
		[Studio.Window]::ShowWindow($handle, 7) | Out-Null
		$minimized[$handle] = $true
	}
	Start-Sleep -Milliseconds 100
}
]==]

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

local function minimizer_arguments(script: string): { string }
	return { "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script }
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

local function start_minimizer(script: string): process.ChildProcess?
	if process.os ~= "windows" then return nil end

	fs.writeFile(script, MINIMIZER_SCRIPT)
	local child =
		process.create("powershell.exe", minimizer_arguments(absolute(process.cwd, script)), { stdio = "none" })
	task.wait(MINIMIZER_HEAD_START)

	return child
end

local function launch(place: string, boot: string, output: string, minimizer: string?): string?
	local program = executable()
	if not program then return "Roblox Studio is not installed" end

	local watcher = if minimizer then start_minimizer(minimizer) else nil
	local cwd = process.cwd
	local result = process.exec(program, arguments(absolute(cwd, place), absolute(cwd, boot), absolute(cwd, output)))
	if watcher then watcher:kill() end

	if result.ok then return nil end
	return `Studio exited with code {result.code}: {result.stderr}`
end

--// End
return table.freeze {
	absolute = absolute,
	arguments = arguments,
	minimizer_arguments = minimizer_arguments,
	launch = launch,
}
