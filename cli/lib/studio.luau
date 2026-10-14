--// Services
local datetime = require "@lune/datetime"
local fs = require "@lune/fs"
local process = require "@lune/process"

--// Constants
local MAC_EXECUTABLE = "/Applications/RobloxStudio.app/Contents/MacOS/RobloxStudio"
local WINDOWS_EXECUTABLE = "RobloxStudioBeta.exe"
local STUDIO_SETTINGS_FILE = "GlobalBasicSettings_13_Studio.xml"
local UNFOCUSED_FRAMERATE_DIVISOR = 4
local DEFAULT_FPS = 15
local WINDOW_TYPE = [==[
public delegate bool WindowVisitor(IntPtr window, IntPtr state);

[DllImport("user32.dll")] static extern bool EnumWindows(WindowVisitor visitor, IntPtr state);
[DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr window, out uint processId);
[DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr window);
[DllImport("user32.dll")] static extern bool ShowWindow(IntPtr window, int command);
[DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr window, out Rect rect);
[DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr window, IntPtr after, int x, int y, int width, int height, uint flags);
[DllImport("user32.dll", EntryPoint = "GetWindowLongW")] static extern int GetStyle(IntPtr window, int index);
[DllImport("user32.dll", EntryPoint = "SetWindowLongW")] static extern int SetStyle(IntPtr window, int index, int value);

public struct Rect { public int Left, Top, Right, Bottom; }

const int SW_HIDE = 0;
const int SW_SHOW_NO_ACTIVATE = 4;
const int GWL_EXSTYLE = -20;
const int WS_EX_TOOLWINDOW = 0x80;
const int WS_EX_APPWINDOW = 0x40000;
const int OFF_SCREEN = -32000;
const uint SWP_NOSIZE = 0x1;
const uint SWP_NOZORDER = 0x4;
const uint SWP_NOACTIVATE = 0x10;

static bool IsOffScreen(IntPtr window) {
	Rect rect;
	GetWindowRect(window, out rect);
	return rect.Left <= OFF_SCREEN;
}

static void MoveOffScreen(IntPtr window) {
	ShowWindow(window, SW_HIDE);
	int style = GetStyle(window, GWL_EXSTYLE);
	SetStyle(window, GWL_EXSTYLE, (style | WS_EX_TOOLWINDOW) & ~WS_EX_APPWINDOW);
	SetWindowPos(window, IntPtr.Zero, OFF_SCREEN, OFF_SCREEN, 0, 0, SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
	ShowWindow(window, SW_SHOW_NO_ACTIVATE);
}

public static void HideWindowsOf(uint[] processIds) {
	EnumWindows(delegate(IntPtr window, IntPtr state) {
		uint owner;
		GetWindowThreadProcessId(window, out owner);
		if (Array.IndexOf(processIds, owner) >= 0 && IsWindowVisible(window) && !IsOffScreen(window)) {
			MoveOffScreen(window);
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

local function framerate_cap(fps: number): number
	return fps * UNFOCUSED_FRAMERATE_DIVISOR
end

local function with_framerate_cap(settings: string, cap: number): string?
	local updated, count = settings:gsub('(<int name="FramerateCap">)%-?%d+(</int>)', `%1{cap}%2`)
	return if count > 0 then updated else nil
end

local function settings_path(): string?
	if process.os ~= "windows" then return nil end
	local path = `{process.env.LOCALAPPDATA or ""}/Roblox/{STUDIO_SETTINGS_FILE}`
	return if fs.isFile(path) then path else nil
end

local function raise_framerate_cap(fps: number?): string?
	local path = settings_path()
	if not path then return nil end

	local original = fs.readFile(path)
	local raised = with_framerate_cap(original, framerate_cap(fps or DEFAULT_FPS))

	if not raised then return nil end
	fs.writeFile(path, raised)

	return original
end

local function restore_settings(original: string?)
	local path = settings_path()
	if original and path then fs.writeFile(path, original) end
end

local function launch(place: string, boot: string, output: string, hider: string?, fps: number?): string?
	local program = executable()
	if not program then return "Roblox Studio is not installed" end

	local since = datetime.now().unixTimestampMillis
	local watcher = if hider then start_hider(hider, since) else nil
	local original_settings = raise_framerate_cap(fps)

	local cwd = process.cwd
	local result = process.exec(program, arguments(absolute(cwd, place), absolute(cwd, boot), absolute(cwd, output)))

	restore_settings(original_settings)
	if watcher then watcher:kill() end
	if result.ok then return nil end

	return `Studio exited with code {result.code}: {result.stderr}`
end

--// End
return table.freeze {
	absolute = absolute,
	arguments = arguments,

	hider_arguments = hider_arguments,
	framerate_cap = framerate_cap,

	with_framerate_cap = with_framerate_cap,
	launch = launch,
}
