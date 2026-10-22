-- Round state, team eligibility and rewards are owned by this server module.
local Players = game:GetService("Players")

local RoundService = {}

function RoundService.Start(ctx)
	local config = ctx.Config
	local rules = ctx.RoundRules
	assert(rules, "RoundService requires ctx.RoundRules")
	local round = ctx.Round
	local random = Random.new()
	local minimumPlayers = math.max(2, config.MinPlayers)
	local frozen = {}
	local lastRewardedRound = -1

	local function now()
		return workspace:GetServerTimeNow()
	end

	local function isPresent(player)
		return player.Parent == Players and ctx.PlayerState[player] ~= nil
	end

	local function humanoidOf(player)
		local character = player.Character
		return character and character:FindFirstChildOfClass("Humanoid")
	end

	local function teleport(player, target)
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			character:PivotTo(target)
			local root = character:FindFirstChild("HumanoidRootPart")
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
	end

	local function unlock(player)
		local saved = frozen[player]
		if saved then
			local humanoid = saved.Humanoid
			if humanoid.Parent then
				humanoid.WalkSpeed = saved.WalkSpeed
				humanoid.JumpPower = saved.JumpPower
				humanoid.JumpHeight = saved.JumpHeight
				humanoid.AutoRotate = saved.AutoRotate
			end
			frozen[player] = nil
		end
	end

	local function lock(player)
		local humanoid = humanoidOf(player)
		if humanoid then
			unlock(player)
			frozen[player] = {
				Humanoid = humanoid,
				WalkSpeed = humanoid.WalkSpeed,
				JumpPower = humanoid.JumpPower,
				JumpHeight = humanoid.JumpHeight,
				AutoRotate = humanoid.AutoRotate,
			}
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
			humanoid.JumpHeight = 0
			humanoid.AutoRotate = false
		end
	end

	local function setTeam(player, role)
		local key = if role == "Ghost" then "Ghosts" elseif role == "Hunter" then "Hunters" else "Lobby"
		local team = ctx.Teams[key] or ctx.Teams[role]
		if team then
			player.Team = team
			player.Neutral = false
		end
	end

	local function readyPlayers()
		local ready = {}
		for player in ctx.PlayerState do
			local humanoid = humanoidOf(player)
			if isPresent(player) and ctx.PlayerState[player].PreparedCharacter == player.Character
				and humanoid and humanoid.Health > 0
				and player.Character:FindFirstChild("HumanoidRootPart") then
				table.insert(ready, player)
			end
		end
		return ready
	end

	local function resetPlayer(player, resetRole)
		local state = ctx.PlayerState[player]
		if not state then
			return
		end
		unlock(player)
		state.Alive = false
		ctx.ResetPlayer(player)
		if resetRole then
			state.Role = "Lobby"
			state.RoundId = nil
		end
		setTeam(player, "Lobby")
		teleport(player, ctx.Spawns.Lobby)
	end

	local function phase(name, seconds, message)
		round.Phase = name
		round.EndsAt = if seconds > 0 then now() + seconds else 0
		round.Message = message
		if name ~= "Results" then
			round.Winner = ""
		end
		ctx.Broadcast()
	end

	function ctx.GetAliveCounts()
		local ghosts, hunters = 0, 0
		for player, state in ctx.PlayerState do
			if isPresent(player) and state.Alive and state.RoundId == round.Id then
				if state.Role == "Ghost" then
					ghosts += 1
				elseif state.Role == "Hunter" then
					hunters += 1
				end
			end
		end
		return ghosts, hunters
	end

	function ctx.Eliminate(player)
		local state = ctx.PlayerState[player]
		if not state or not state.Alive or state.RoundId ~= round.Id
			or (round.Phase ~= "Hide" and round.Phase ~= "Hunt") then
			return false
		end
		resetPlayer(player, false)
		ctx.Broadcast()
		return true
	end

	function ctx.CaptureGhost(hunter, ghost)
		local hunterState = ctx.PlayerState[hunter]
		local ghostState = ctx.PlayerState[ghost]
		if round.Phase ~= "Hunt" or not isPresent(hunter) or not isPresent(ghost)
			or not hunterState.Alive or hunterState.Role ~= "Hunter" or hunterState.RoundId ~= round.Id
			or not ghostState.Alive or ghostState.Role ~= "Ghost" or ghostState.RoundId ~= round.Id then
			return false
		end
		-- The caller must first validate its own shot/line of sight on the server.
		if not ctx.Eliminate(ghost) then
			return false
		end
		hunterState.Captures += 1
		ctx.Award(hunter, "Captures", 1)
		ctx.Award(hunter, "Coins", config.CaptureReward)
		ctx.Broadcast()
		return true
	end

	function ctx.HandleJoiningPlayer(player)
		resetPlayer(player, true)
		ctx.Broadcast()
	end

	function ctx.HandleCharacter(player, character)
		-- Character resets never grant a second life in the same round.
		if not isPresent(player) or player.Character ~= character then
			return
		end
		ctx.Eliminate(player)
		unlock(player)
		setTeam(player, "Lobby")
		teleport(player, ctx.Spawns.Lobby)
		ctx.Broadcast()
	end

	local function waitCountdown(check)
		local previousSecond = -1
		while now() < round.EndsAt do
			local result = check()
			if result ~= nil then
				return result
			end
			local second = math.ceil(round.EndsAt - now())
			if second ~= previousSecond then
				previousSecond = second
				ctx.Broadcast()
			end
			task.wait(0.2)
		end
		return nil
	end

	local function activeWinner(expired)
		local ghosts, hunters = ctx.GetAliveCounts()
		return rules.getWinner(ghosts, hunters, expired)
	end

	local function assignRound(participants)
		for index = #participants, 2, -1 do
			local other = random:NextInteger(1, index)
			participants[index], participants[other] = participants[other], participants[index]
		end
		local ghostCount = rules.chooseGhostCount(#participants)
		for index, player in participants do
			local state = ctx.PlayerState[player]
			if state and isPresent(player) then
				state.Role = if index <= ghostCount then "Ghost" else "Hunter"
				ctx.ResetPlayer(player)
				state.Captures = 0
				state.Alive = true
				state.RoundId = round.Id
				setTeam(player, state.Role)
				local humanoid = humanoidOf(player)
				if humanoid then
					humanoid.Health = humanoid.MaxHealth
				end
				if state.Role == "Ghost" then
					local spawns = ctx.Spawns.Ghosts
					teleport(player, spawns[((index - 1) % #spawns) + 1])
				else
					teleport(player, ctx.Spawns.Lobby)
					lock(player)
				end
			end
		end
	end

	local function releaseHunters()
		local index = 0
		for player, state in ctx.PlayerState do
			if isPresent(player) and state.Alive and state.Role == "Hunter" and state.RoundId == round.Id then
				index += 1
				unlock(player)
				local spawns = ctx.Spawns.Hunters
				teleport(player, spawns[((index - 1) % #spawns) + 1])
			end
		end
	end

	local function finishRound(winner)
		round.Winner = winner
		-- No remote or death callback can award a round. This loop finishes it once.
		if lastRewardedRound ~= round.Id then
			lastRewardedRound = round.Id
			for player, state in ctx.PlayerState do
				local won = (winner == "Ghosts" and state.Role == "Ghost")
					or (winner == "Hunters" and state.Role == "Hunter")
				if isPresent(player) and state.RoundId == round.Id and won then
					ctx.Award(player, "Wins", 1)
					ctx.Award(player, "Coins", config.WinReward)
				end
			end
		end
		phase("Results", config.ResultsSeconds, if winner == "Draw" then "Round ended in a draw" else winner .. " win!")
		for player in ctx.PlayerState do
			resetPlayer(player, false)
		end
		ctx.Broadcast()
		waitCountdown(function() return nil end)
	end

	Players.PlayerRemoving:Connect(function(player)
		unlock(player)
	end)

	task.spawn(function()
		while true do
			for player in ctx.PlayerState do
				resetPlayer(player, true)
			end
			phase("Lobby", 0, "Waiting for at least " .. minimumPlayers .. " players")
			while #readyPlayers() < minimumPlayers do
				task.wait(1)
				ctx.Broadcast()
			end

			phase("Intermission", config.IntermissionSeconds, "A new shift starts soon")
			local cancelled = waitCountdown(function()
				return if #readyPlayers() < minimumPlayers then "cancel" else nil
			end)
			if cancelled or #readyPlayers() < minimumPlayers then
				continue
			end

			local participants = readyPlayers()
			round.Id += 1
			-- Set phase before assignment so deaths/resets are always handled as live eliminations.
			phase("Hide", config.HideSeconds, "Ghosts: hide. Hunters are held in the lobby.")
			assignRound(participants)
			ctx.Broadcast()
			local winner = waitCountdown(function() return activeWinner(false) end)
			if not winner then
				phase("Hunt", config.HuntSeconds, "Hunters: capture every ghost before time runs out")
				releaseHunters()
				ctx.Broadcast()
				winner = waitCountdown(function() return activeWinner(false) end)
			end
			finishRound(winner or activeWinner(true) or "Draw")
		end
	end)
end

return RoundService
