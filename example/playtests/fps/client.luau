--// Services
const RunService = game:GetService "RunService"

--// Constants
const SAMPLE_SECONDS = 2

--// Variables
local frames = 0

--// Functions
const function count_frame()
	frames += 1
end

const function fps(): number
	frames = 0
	const connection = RunService.RenderStepped:Connect(count_frame)
	task.wait(SAMPLE_SECONDS)
	
	connection:Disconnect()
	return frames / SAMPLE_SECONDS
end

--// End
return {
	fps = fps,
}
