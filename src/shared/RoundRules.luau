-- Pure round decisions. The server owns the inputs and applies every result.
local RoundRules = {}

function RoundRules.chooseGhostCount(playerCount: number): number
	if playerCount < 2 then
		return 0
	end
	return math.clamp(math.floor(playerCount / 2), 1, playerCount - 1)
end

function RoundRules.getWinner(ghostsAlive: number, huntersAlive: number, timeExpired: boolean): string?
	if ghostsAlive <= 0 and huntersAlive <= 0 then
		return "Draw"
	elseif ghostsAlive <= 0 then
		return "Hunters"
	elseif huntersAlive <= 0 or timeExpired then
		return "Ghosts"
	end
	return nil
end

return RoundRules
