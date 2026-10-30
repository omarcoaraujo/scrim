--// Constants
const MS_PER_SECOND = 1000
const JITTER_DIRECTIONS = 2

--// Functions
const function allowance(ping: number?, jitter: number?): number
	return ((ping or 0) + (jitter or 0) * JITTER_DIRECTIONS) / MS_PER_SECOND
end

--// End
return table.freeze {
	allowance = allowance,
}
