-- Server-owned disguise, pulse weapon, reload and ghost sprint.
-- Clients send intentions only. No client supplies a hit, origin, ammo or reward.
local Players = game:GetService("Players")

local GameplayService = {}

local function now()
	return workspace:GetServerTimeNow()
end

local function finiteVector(value)
	return typeof(value) == "Vector3"
		and value.X == value.X and value.Y == value.Y and value.Z == value.Z
		and math.abs(value.X) < 1e6 and math.abs(value.Y) < 1e6 and math.abs(value.Z) < 1e6
end

function GameplayService.Start(ctx)
	local controls = {}
	local function controlFor(player)
		if not controls[player] then
			controls[player] = { Epoch = 0, ReloadToken = 0, Requests = {}, Hidden = {}, SprintUntil = 0 }
		end
		return controls[player]
	end

	local function gate(player, action, interval)
		if not ctx.PlayerState[player] then return false end
		local control = controlFor(player)
		local timestamp = now()
		if timestamp - (control.Requests[action] or -math.huge) < interval then
			return false
		end
		control.Requests[action] = timestamp
		return true
	end

	local function livingCharacter(player)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
			return character, humanoid, root
		end
		return nil, nil, nil
	end

	local function eligibleGhost(player)
		local state = ctx.PlayerState[player]
		return state and state.Role == "Ghost" and state.Alive
			and (ctx.Round.Phase == "Hide" or ctx.Round.Phase == "Hunt")
	end

	local function eligibleHunter(player)
		local state = ctx.PlayerState[player]
		return state and state.Role == "Hunter" and state.Alive and ctx.Round.Phase == "Hunt"
	end

	local function removeDisguise(player)
		local control = controls[player]
		local state = ctx.PlayerState[player]
		if state and state.Disguise then
			state.Disguise:Destroy()
			state.Disguise = nil
		end
		if control then
			for instance, transparency in control.Hidden do
				if instance.Parent then
					instance.Transparency = transparency
				end
			end
			control.Hidden = {}
		end
	end

	local function hidePart(player, instance)
		local state = ctx.PlayerState[player]
		if not state or not state.Disguise or instance == state.Disguise or instance:IsDescendantOf(state.Disguise) then
			return
		end
		if instance:IsA("BasePart") or instance:IsA("Decal") then
			local hidden = controlFor(player).Hidden
			if hidden[instance] == nil then
				hidden[instance] = instance.Transparency
			end
			instance.Transparency = 1
		end
	end

	local function restoreSpeed(player)
		local state = ctx.PlayerState[player]
		local _, humanoid = livingCharacter(player)
		if state and humanoid then
			humanoid.WalkSpeed = if state.Role == "Ghost" then ctx.Config.GhostSpeed else ctx.Config.HunterSpeed
		end
	end

	ctx.ResetPlayer = function(player)
		local control = controlFor(player)
		control.Epoch += 1
		control.ReloadToken += 1
		control.SprintUntil = 0
		removeDisguise(player)
		local state = ctx.PlayerState[player]
		if state then
			state.Ammo = ctx.Config.Weapons.Pulse.Magazine
			state.ReloadUntil = 0
			state.LastFire = 0
			state.AbilityReadyAt = 0
		end
		restoreSpeed(player)
	end

	ctx.PrepareCharacter = function(player, character)
		if not ctx.PlayerState[player] then
			return
		end
		local control = controlFor(player)
		if control.DeathConnection then control.DeathConnection:Disconnect() end
		if control.DescendantConnection then control.DescendantConnection:Disconnect() end
		ctx.ResetPlayer(player)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if player.Character ~= character or not ctx.PlayerState[player] or not humanoid or not humanoid:IsA("Humanoid") then
			return
		end
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		restoreSpeed(player)
		control.DescendantConnection = character.DescendantAdded:Connect(function(instance)
			hidePart(player, instance)
		end)
		control.DeathConnection = humanoid.Died:Connect(function()
			if player.Character ~= character or not ctx.PlayerState[player] then return end
			ctx.ResetPlayer(player)
			if ctx.Eliminate then
				ctx.Eliminate(player)
			else
				ctx.PlayerState[player].Alive = false
				ctx.Broadcast()
			end
		end)
	end

	ctx.CleanupPlayer = function(player)
		local control = controls[player]
		if control then
			ctx.ResetPlayer(player)
			if control.DeathConnection then control.DeathConnection:Disconnect() end
			if control.DescendantConnection then control.DescendantConnection:Disconnect() end
			controls[player] = nil
		end
	end

	local function disguise(player, prop)
		if not gate(player, "Disguise", 0.7) or not eligibleGhost(player) then return end
		if not prop:IsDescendantOf(ctx.Props) or prop:GetAttribute("GhostShiftProp") ~= true then return end
		local character, humanoid, root = livingCharacter(player)
		if not character or (root.Position - prop.Position).Magnitude > ctx.Config.DisguiseDistance then return end
		local head = character:FindFirstChild("Head")
		local origin = if head and head:IsA("BasePart") then head.Position else root.Position
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { character }
		local obstruction = workspace:Raycast(origin, prop.Position - origin, params)
		if obstruction and obstruction.Instance ~= prop then return end
		removeDisguise(player)
		local visual = prop:Clone()
		visual.Name = "GhostDisguise"
		visual:SetAttribute("GhostShiftOwnerUserId", player.UserId)
		for _, descendant in visual:GetDescendants() do
			if descendant:IsA("ProximityPrompt") or descendant:IsA("BaseScript") or descendant:IsA("ModuleScript") then
				descendant:Destroy()
			end
		end
		-- A cylinder's local Y size is not its world-space height after rotation.
		local rotation = prop.CFrame.Rotation
		local height = math.abs(rotation.RightVector.Y) * visual.Size.X
			+ math.abs(rotation.UpVector.Y) * visual.Size.Y
			+ math.abs(rotation.LookVector.Y) * visual.Size.Z
		local rootToFloor = humanoid.HipHeight + root.Size.Y / 2
		if humanoid.RigType == Enum.HumanoidRigType.R6 then
			-- R6 HipHeight omits the leg, unlike the R15 standing-height formula.
			local leg = character:FindFirstChild("Left Leg") or character:FindFirstChild("Right Leg")
			rootToFloor += if leg and leg:IsA("BasePart") then leg.Size.Y else 2
		end
		local offset = -rootToFloor + height / 2
		visual.CFrame = root.CFrame * CFrame.new(0, offset, 0) * prop.CFrame.Rotation
		visual.Anchored = false
		visual.CanCollide = false
		visual.CanTouch = false
		visual.CanQuery = true
		visual.Massless = true
		local state = ctx.PlayerState[player]
		state.Disguise = visual
		visual.Parent = character
		for _, descendant in character:GetDescendants() do
			hidePart(player, descendant)
		end
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = visual
		weld.Parent = visual
		ctx.Broadcast()
	end

	local connectedProps = setmetatable({}, { __mode = "k" })
	local function connectProp(prop)
		if not prop:IsA("BasePart") or prop:GetAttribute("GhostShiftProp") ~= true or connectedProps[prop] then return end
		connectedProps[prop] = true
		local prompt = prop:FindFirstChildOfClass("ProximityPrompt")
		if not prompt then
			prompt = Instance.new("ProximityPrompt")
			prompt.Name = "GhostDisguisePrompt"
			prompt.ActionText = "Possess"
			prompt.ObjectText = prop.Name
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.HoldDuration = 0.25
			prompt.MaxActivationDistance = 8
			prompt.RequiresLineOfSight = true
			prompt.Parent = prop
		end
		prompt.Triggered:Connect(function(player) disguise(player, prop) end)
	end
	for _, prop in ctx.Props:GetDescendants() do connectProp(prop) end
	ctx.Props.DescendantAdded:Connect(connectProp)

	ctx.Remotes.ToggleDisguise.OnServerEvent:Connect(function(player)
		local state = ctx.PlayerState[player]
		if not state or state.Role ~= "Ghost" or not state.Disguise or not gate(player, "ToggleDisguise", 0.4) then return end
		removeDisguise(player)
		ctx.Broadcast()
	end)

	ctx.Remotes.Fire.OnServerEvent:Connect(function(player, direction)
		if not gate(player, "FireRequest", 0.04) or not eligibleHunter(player) or not finiteVector(direction) then return end
		local magnitude = direction.Magnitude
		if magnitude < 0.01 or magnitude > 1e4 then return end
		local state = ctx.PlayerState[player]
		local weapon = ctx.Config.Weapons.Pulse
		local timestamp = now()
		if timestamp - state.LastFire < weapon.FireInterval or state.ReloadUntil > timestamp or state.Ammo <= 0 then return end
		local character, _, root = livingCharacter(player)
		if not character then return end
		local head = character:FindFirstChild("Head")
		local origin = if head and head:IsA("BasePart") then head.Position else root.Position
		local ignored = { character }
		-- Query only the visible disguise, never the invisible humanoid silhouette.
		for ghost, ghostState in ctx.PlayerState do
			if ghostState.Disguise and controls[ghost] then
				for hidden in controls[ghost].Hidden do
					if hidden:IsA("BasePart") and hidden.Parent then table.insert(ignored, hidden) end
				end
			end
		end
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = ignored
		local ray = direction.Unit * weapon.Range
		local result = workspace:Raycast(origin, ray, params)
		local position = if result then result.Position else origin + ray
		state.LastFire = timestamp
		state.Ammo -= 1
		ctx.Remotes.Effects:FireAllClients({ kind = "Shot", origin = origin, position = position, playerId = player.UserId })
		if result and ctx.CaptureGhost then
			local ancestor = result.Instance
			local target
			while ancestor and ancestor ~= workspace do
				if ancestor:IsA("Model") then
					target = Players:GetPlayerFromCharacter(ancestor)
					if target then break end
				end
				ancestor = ancestor.Parent
			end
			if target and target ~= player and eligibleGhost(target) then
				ctx.CaptureGhost(player, target)
				if ctx.PlayerState[target] and not ctx.PlayerState[target].Alive then
					ctx.Remotes.Effects:FireAllClients({ kind = "Capture", position = position, playerId = player.UserId, targetId = target.UserId })
				end
			end
		end
		ctx.Broadcast()
	end)

	ctx.Remotes.Reload.OnServerEvent:Connect(function(player)
		if not gate(player, "Reload", 0.3) or not eligibleHunter(player) then return end
		local state = ctx.PlayerState[player]
		local weapon = ctx.Config.Weapons.Pulse
		if state.Ammo >= weapon.Magazine or state.ReloadUntil > now() then return end
		local _, humanoid = livingCharacter(player)
		if not humanoid then return end
		local control = controlFor(player)
		control.ReloadToken += 1
		local token, epoch = control.ReloadToken, control.Epoch
		state.ReloadUntil = now() + weapon.ReloadSeconds
		ctx.Broadcast()
		ctx.Remotes.Effects:FireClient(player, { kind = "Reload", playerId = player.UserId })
		task.delay(weapon.ReloadSeconds, function()
			if controls[player] ~= control or control.Epoch ~= epoch or control.ReloadToken ~= token then return end
			if ctx.PlayerState[player] ~= state or not eligibleHunter(player) then return end
			state.Ammo = weapon.Magazine
			state.ReloadUntil = 0
			ctx.Broadcast()
		end)
	end)

	ctx.Remotes.Ability.OnServerEvent:Connect(function(player)
		if not gate(player, "Ability", 0.3) or not eligibleGhost(player) then return end
		local state = ctx.PlayerState[player]
		local timestamp = now()
		if state.AbilityReadyAt > timestamp then return end
		local _, humanoid = livingCharacter(player)
		if not humanoid then return end
		local control = controlFor(player)
		local epoch = control.Epoch
		state.AbilityReadyAt = timestamp + ctx.Config.SprintCooldown
		control.SprintUntil = timestamp + ctx.Config.SprintSeconds
		humanoid.WalkSpeed = ctx.Config.SprintSpeed
		ctx.Broadcast()
		ctx.Remotes.Effects:FireClient(player, { kind = "Sprint", playerId = player.UserId })
		task.delay(ctx.Config.SprintSeconds, function()
			if controls[player] == control and control.Epoch == epoch then restoreSpeed(player) end
		end)
	end)

	ctx.DetectorDistance = function(player)
		if not eligibleHunter(player) then return nil end
		local _, _, root = livingCharacter(player)
		if not root then return nil end
		local nearest = math.huge
		for ghost in ctx.PlayerState do
			if eligibleGhost(ghost) then
				local _, _, targetRoot = livingCharacter(ghost)
				if targetRoot then nearest = math.min(nearest, (root.Position - targetRoot.Position).Magnitude) end
			end
		end
		return if nearest <= ctx.Config.DetectorRange then math.floor(nearest) else nil
	end
end

return GameplayService
