--// Services
local datetime = require "@lune/datetime"
local fs = require "@lune/fs"
local process = require "@lune/process"

--// Constants
local MAC_EXECUTABLE = "/Applications/RobloxStudio.app/Contents/MacOS/RobloxStudio"
local WINDOWS_EXECUTABLE = "RobloxStudioBeta.exe"
local WINDOW_TYPE = [==[
public delegate bool WindowVisitor(IntPtr window, IntPtr state);

[DllImport("user32.dll")] static extern bool EnumWindows(WindowVisitor visitor, IntPtr state);
[DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr window, out uint processId);
[DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr window);
[DllImport("user32.dll")] static extern bool ShowWindow(IntPtr window, int command);

const int SW_HIDE = 0;
public static void HideWindowsOf(uint[] processIds) {
	EnumWindows(delegate(IntPtr window, IntPtr state) {
		uint owner;
		GetWindowThreadProcessId(window, out owner);
		if (Array.IndexOf(processIds, owner) >= 0 && IsWindowVisible(window)) {
			ShowWindow(window, SW_HIDE);
		}
		return true;
	}, IntPtr.Zero);
}
]==]

local HIDER_SCRIPT = [==[
param([long]$Since)

$launchedAt = [DateTimeOffset]::FromUnixTimeMilliseconds($Since).LocalDateTime

Add-Type -Name Native -Namespace Studio -MemberDefinition @'
]==] .. WINDOW_TYPE .. [==[
'@

function Get-StudioProcessIds {
	$studios = Get-Process RobloxStudioBeta -ErrorAction SilentlyContinue
	$launched = $studios | Where-Object { $_.StartTime -ge $launchedAt }
	return [uint32[]]@($launched | ForEach-Object { $_.Id })
}

while ($true) {
	$processIds = Get-StudioProcessIds
	if ($processIds.Count -gt 0) {
		[Studio.Native]::HideWindowsOf($processIds)
	}
	Start-Sleep -Milliseconds 20
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

local function hider_arguments(script: string, since: number): { string }
	return { "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script, tostring(since) }
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

local function start_hider(script: string, since: number): process.ChildProcess?
	if process.os ~= "windows" then return nil end
	fs.writeFile(script, HIDER_SCRIPT)
	return process.create("powershell.exe", hider_arguments(absolute(process.cwd, script), since), { stdio = "none" })
end

local function launch(place: string, boot: string, output: string, hider: string?): string?
	local program = executable()
	if not program then return "Roblox Studio is not installed" end

	local since = datetime.now().unixTimestampMillis
	local watcher = if hider then start_hider(hider, since) else nil

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

	hider_arguments = hider_arguments,
	launch = launch,
}
