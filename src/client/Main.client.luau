-- GHOST SHIFT client: input, presentation and server-confirmed effects only.
-- Hits, ammunition, cooldowns, captures and rewards are decided by the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local package = ReplicatedStorage:WaitForChild("GhostShift")
local Config = require(package:WaitForChild("Config"))
local remotes = package:WaitForChild("Remotes")
local stateRemote = remotes:WaitForChild("State")
local effectsRemote = remotes:WaitForChild("Effects")
local fireRemote = remotes:WaitForChild("Fire")
local reloadRemote = remotes:WaitForChild("Reload")
local disguiseRemote = remotes:WaitForChild("ToggleDisguise")
local abilityRemote = remotes:WaitForChild("Ability")
local requestRemote = remotes:WaitForChild("RequestState")

local colors = {
	Background = Color3.fromRGB(12, 17, 25),
	Panel = Color3.fromRGB(18, 27, 37),
	Text = Color3.fromRGB(232, 240, 246),
	Muted = Color3.fromRGB(145, 163, 180),
	Hunter = Color3.fromRGB(80, 224, 235),
	Ghost = Color3.fromRGB(189, 146, 255),
	Amber = Color3.fromRGB(255, 192, 91),
}

local function create(className, properties, parent)
	local instance = Instance.new(className)
	for property, value in pairs(properties) do
		instance[property] = value
	end
	instance.Parent = parent
	return instance
end

local function roundCorners(instance, radius)
	create("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, instance)
end

local function outline(instance, color, transparency)
	return create("UIStroke", {
		Color = color or colors.Muted,
		Transparency = transparency or 0.65,
		Thickness = 1,
	}, instance)
end

local screen = create("ScreenGui", {
	Name = "GhostShiftHUD",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, player:WaitForChild("PlayerGui"))

local root = create("Frame", {
	Name = "Root",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
}, screen)

local function text(parent, name, content, position, size, fontSize, color)
	return create("TextLabel", {
		Name = name,
		Text = content,
		Position = position,
		Size = size,
		BackgroundTransparency = 1,
		TextColor3 = color or colors.Text,
		TextSize = fontSize,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = true,
	}, parent)
end

local brand = create("Frame", {
	Name = "StationIdentity",
	Position = UDim2.fromOffset(18, 12),
	Size = UDim2.fromOffset(240, 72),
	BackgroundColor3 = colors.Background,
	BackgroundTransparency = 0.1,
}, root)
roundCorners(brand)
outline(brand, colors.Amber)
text(brand, "Title", "GHOST SHIFT", UDim2.fromOffset(14, 6), UDim2.fromOffset(160, 28), 20)
text(brand, "Station", "NIGHT SERVICE // ABANDONED", UDim2.fromOffset(14, 38), UDim2.fromOffset(210, 21), 10, colors.Muted)
local clock = text(brand, "Clock", "03:17", UDim2.fromOffset(170, 9), UDim2.fromOffset(58, 24), 18, colors.Amber)
clock.TextXAlignment = Enum.TextXAlignment.Right

local phasePanel = create("Frame", {
	Name = "RoundStatus",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 12),
	Size = UDim2.fromOffset(380, 104),
	BackgroundColor3 = colors.Background,
	BackgroundTransparency = 0.1,
}, root)
roundCorners(phasePanel)
outline(phasePanel, colors.Amber)
local phaseLabel = text(phasePanel, "Phase", "WAITING FOR SIGNAL", UDim2.fromOffset(14, 8), UDim2.new(1, -104, 0, 24), 15, colors.Amber)
local timerLabel = text(phasePanel, "Timer", "--:--", UDim2.new(1, -91, 0, 8), UDim2.fromOffset(77, 26), 23)
timerLabel.TextXAlignment = Enum.TextXAlignment.Right
local messageLabel = text(phasePanel, "Message", "Connecting to the station…", UDim2.fromOffset(14, 39), UDim2.new(1, -28, 0, 33), 12, colors.Text)
local remainingLabel = text(phasePanel, "Remaining", "GHOSTS  —     HUNTERS  —", UDim2.fromOffset(14, 76), UDim2.new(1, -28, 0, 18), 10, colors.Muted)

local statusPanel = create("Frame", {
	Name = "PlayerStatus",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 18, 1, -18),
	Size = UDim2.fromOffset(310, 142),
	BackgroundColor3 = colors.Background,
	BackgroundTransparency = 0.1,
}, root)
roundCorners(statusPanel)
local roleOutline = outline(statusPanel, colors.Muted)
local roleLabel = text(statusPanel, "Role", "LOBBY", UDim2.fromOffset(14, 8), UDim2.new(1, -28, 0, 25), 20)
local weaponLabel = text(statusPanel, "Weapon", "Next departure: waiting for players", UDim2.fromOffset(14, 39), UDim2.new(1, -28, 0, 24), 13, colors.Muted)
local detailLabel = text(statusPanel, "Detail", "", UDim2.fromOffset(14, 67), UDim2.new(1, -28, 0, 24), 12)
local sessionLabel = text(statusPanel, "Session", "SESSION  |  COINS 0  |  WINS 0", UDim2.fromOffset(14, 101), UDim2.new(1, -28, 0, 20), 10, colors.Muted)

local detectorPanel = create("Frame", {
	Name = "Detector",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -18, 0, 12),
	Size = UDim2.fromOffset(220, 72),
	BackgroundColor3 = colors.Background,
	BackgroundTransparency = 0.1,
	Visible = false,
}, root)
roundCorners(detectorPanel)
outline(detectorPanel, colors.Hunter)
text(detectorPanel, "Name", "SPECTRAL DETECTOR", UDim2.fromOffset(12, 7), UDim2.new(1, -24, 0, 18), 10, colors.Hunter)
local detectorLabel = text(detectorPanel, "Signal", "NO SIGNAL", UDim2.fromOffset(12, 27), UDim2.new(1, -24, 0, 20), 13)
local detectorTrack = create("Frame", {
	Position = UDim2.fromOffset(12, 56),
	Size = UDim2.new(1, -24, 0, 3),
	BorderSizePixel = 0,
	BackgroundColor3 = colors.Panel,
}, detectorPanel)
local detectorBar = create("Frame", {
	Size = UDim2.fromScale(0, 1),
	BorderSizePixel = 0,
	BackgroundColor3 = colors.Hunter,
}, detectorTrack)

local crosshair = create("Frame", {
	Name = "Crosshair",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(32, 32),
	BackgroundTransparency = 1,
	Visible = false,
}, root)
for _, geometry in ipairs({ { 15, 1, 2, 8 }, { 15, 23, 2, 8 }, { 1, 15, 8, 2 }, { 23, 15, 8, 2 }, { 15, 15, 2, 2 } }) do
	create("Frame", {
		Position = UDim2.fromOffset(geometry[1], geometry[2]),
		Size = UDim2.fromOffset(geometry[3], geometry[4]),
		BackgroundColor3 = colors.Hunter,
		BorderSizePixel = 0,
	}, crosshair)
end
local hitMarker = text(root, "HitMarker", "×", UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(64, 64), 48, colors.Amber)
hitMarker.AnchorPoint = Vector2.new(0.5, 0.5)
hitMarker.TextXAlignment = Enum.TextXAlignment.Center
hitMarker.Visible = false

local controls = create("Frame", {
	Name = "ActionButtons",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -18, 1, -22),
	Size = UDim2.fromOffset(280, 126),
	BackgroundTransparency = 1,
}, root)
create("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Bottom,
	Padding = UDim.new(0, 7),
}, controls)

local function actionButton(name, label, order, color)
	local button = create("TextButton", {
		Name = name,
		Text = label,
		Size = UDim2.fromOffset(216, 36),
		BackgroundColor3 = colors.Background,
		BackgroundTransparency = 0.08,
		TextColor3 = color,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		LayoutOrder = order,
		AutoButtonColor = true,
		Visible = false,
	}, controls)
	roundCorners(button, 7)
	outline(button, color, 0.35)
	return button
end

local fireButton = actionButton("Shoot", "CLICK  /  CAPTURE PULSE", 1, colors.Hunter)
local reloadButton = actionButton("Reload", "R  /  RELOAD", 2, colors.Hunter)
local unhideButton = actionButton("Unhide", "Q  /  LEAVE DISGUISE", 3, colors.Ghost)
local sprintButton = actionButton("Sprint", "F  /  PHASE SPRINT", 4, colors.Ghost)

local state = {
	phase = "Lobby",
	role = "Lobby",
	alive = false,
	endsAt = 0,
	reloadUntil = 0,
	abilityReadyAt = 0,
	ammo = 0,
	magazine = 6,
	disguised = false,
}
local originalCameraMode = player.CameraMode
local originalMouseEnabled = UserInputService.MouseIconEnabled
local firstPersonActive = false
local promptCache = {}
local lastLocalFire = 0
local touchEnabled = UserInputService.TouchEnabled

local function isActiveGhost()
	return state.role == "Ghost" and state.alive == true and (state.phase == "Hide" or state.phase == "Hunt")
end

local function isActiveHunter()
	return state.role == "Hunter" and state.alive == true and state.phase == "Hunt"
end

local function isDisguisePrompt(prompt)
	local parent = prompt.Parent
	return parent ~= nil and parent:IsA("BasePart") and parent:GetAttribute("GhostShiftProp") == true
end

local function refreshPrompts()
	for prompt in pairs(promptCache) do
		if prompt.Parent then
			prompt.Enabled = isActiveGhost() and state.disguised ~= true
		else
			promptCache[prompt] = nil
		end
	end
end

local function observePrompt(instance)
	if instance:IsA("ProximityPrompt") and isDisguisePrompt(instance) then
		promptCache[instance] = true
		instance.Enabled = isActiveGhost() and state.disguised ~= true
	end
end
for _, instance in ipairs(workspace:GetDescendants()) do
	observePrompt(instance)
end
workspace.DescendantAdded:Connect(observePrompt)

local function shoot()
	if not isActiveHunter() then
		return
	end
	local now = workspace:GetServerTimeNow()
	if (state.reloadUntil or 0) > now or (state.ammo or 0) <= 0 then
		return
	end
	local interval = Config.Weapons.Pulse.FireInterval
	if now - lastLocalFire < interval then
		return
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	lastLocalFire = now
	-- Only a direction is sent. The server chooses the origin and performs the raycast.
	local viewport = camera.ViewportSize
	local aim = camera:ViewportPointToRay(viewport.X * 0.5, viewport.Y * 0.5)
	fireRemote:FireServer(aim.Direction)
end

local function reload()
	if isActiveHunter() then
		reloadRemote:FireServer()
	end
end

local function unhide()
	if isActiveGhost() and state.disguised == true then
		disguiseRemote:FireServer()
	end
end

local function sprint()
	if isActiveGhost() and (state.abilityReadyAt or 0) <= workspace:GetServerTimeNow() then
		abilityRemote:FireServer()
	end
end

fireButton.Activated:Connect(shoot)
reloadButton.Activated:Connect(reload)
unhideButton.Activated:Connect(unhide)
sprintButton.Activated:Connect(sprint)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or UserInputService:GetFocusedTextBox() then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
		shoot()
	elseif input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonX then
		reload()
	elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonB then
		unhide()
	elseif input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonY then
		sprint()
	end
end)

local phaseNames = {
	Lobby = "WAITING FOR PLAYERS",
	Intermission = "NEXT DEPARTURE",
	Hide = "HIDE PHASE",
	Hunt = "THE HUNT IS LIVE",
	Results = "SHIFT COMPLETE",
}

local function updateState()
	local ghost = isActiveGhost()
	local hunter = isActiveHunter()
	local roleColor = if state.role == "Ghost" then colors.Ghost elseif state.role == "Hunter" then colors.Hunter else colors.Muted
	phaseLabel.Text = phaseNames[state.phase] or tostring(state.phase)
	messageLabel.Text = type(state.message) == "string" and state.message or ""
	remainingLabel.Text = string.format("GHOSTS  %d     HUNTERS  %d     ROUND  %d", state.ghostsAlive or 0, state.huntersAlive or 0, state.roundId or 0)
	roleLabel.Text = if state.role == "Ghost" then "GHOST" elseif state.role == "Hunter" then "HUNTER" else "LOBBY / SPECTATOR"
	roleLabel.TextColor3 = roleColor
	roleOutline.Color = roleColor
	sessionLabel.Text = string.format("SESSION ONLY  |  COINS %d  |  WINS %d", state.coins or 0, state.wins or 0)
	crosshair.Visible = hunter
	detectorPanel.Visible = hunter
	fireButton.Visible = hunter
	reloadButton.Visible = hunter
	unhideButton.Visible = ghost and state.disguised == true
	sprintButton.Visible = ghost
	if hunter ~= firstPersonActive then
		firstPersonActive = hunter
		player.CameraMode = if hunter then Enum.CameraMode.LockFirstPerson else originalCameraMode
		UserInputService.MouseIconEnabled = if hunter then false else originalMouseEnabled
	end
	if state.role == "Hunter" then
		detailLabel.Text = string.format("CAPTURES %d   |   %s", state.captures or 0, if hunter then "Keep your aim steady." else "Wait for the hide phase to end.")
	elseif ghost then
		weaponLabel.Text = if state.disguised then "DISGUISED  /  Keep moving to escape" else "Find a prop and press E to disguise"
		detailLabel.Text = "Hunters track your spectral signal."
	else
		weaponLabel.Text = "You join the next available round."
		detailLabel.Text = "Minimum 2 players. Watch the departure board."
	end
	local distance = state.detectorDistance
	if type(distance) == "number" and distance == distance and distance >= 0 and distance < math.huge then
		detectorLabel.Text = string.format("SIGNAL  /  %d STUDS", math.floor(distance + 0.5))
		detectorBar.Size = UDim2.fromScale(math.clamp(1 - distance / (Config.DetectorRange or 90), 0.03, 1), 1)
	else
		detectorLabel.Text = "NO SIGNAL"
		detectorBar.Size = UDim2.fromScale(0, 1)
	end
	refreshPrompts()
end

local function updateTimers()
	local now = workspace:GetServerTimeNow()
	local remaining = math.max(0, math.ceil((state.endsAt or 0) - now))
	timerLabel.Text = if state.phase == "Lobby" then "--:--" else string.format("%02d:%02d", math.floor(remaining / 60), remaining % 60)
	if state.role == "Hunter" then
		local reloadRemaining = math.max(0, (state.reloadUntil or 0) - now)
		if reloadRemaining > 0 then
			weaponLabel.Text = string.format("RELOADING  %.1fs", reloadRemaining)
		else
			weaponLabel.Text = string.format("CAPTURE PULSE   %d / %d", state.ammo or 0, state.magazine or 6)
		end
	end
	if isActiveGhost() then
		local cooldown = math.max(0, math.ceil((state.abilityReadyAt or 0) - now))
		sprintButton.Text = if cooldown > 0 then string.format("SPRINT READY IN  %ds", cooldown) else (if touchEnabled then "PHASE SPRINT" else "F  /  PHASE SPRINT")
	end
	if touchEnabled then
		fireButton.Text = "CAPTURE PULSE"
		reloadButton.Text = "RELOAD"
		unhideButton.Text = "LEAVE DISGUISE"
	end
end

local function responsiveLayout()
	local camera = workspace.CurrentCamera
	local width = camera and camera.ViewportSize.X or 1280
	if camera then
		-- The HUD respects Studio's top bar inset. Aim markers still belong to
		-- the camera's exact viewport centre used by ViewportPointToRay.
		local centre = camera.ViewportSize / 2 - root.AbsolutePosition
		crosshair.Position = UDim2.fromOffset(centre.X, centre.Y)
		hitMarker.Position = UDim2.fromOffset(centre.X, centre.Y)
	end
	local compact = width < 900
	brand.Visible = not compact
	detectorPanel.Position = if compact then UDim2.new(1, -12, 0, 126) else UDim2.new(1, -18, 0, 12)
	detectorPanel.Size = UDim2.fromOffset(if compact then 185 else 220, 72)
	phasePanel.Size = UDim2.fromOffset(math.min(380, width - 24), 104)
	statusPanel.Position = UDim2.new(0, 12, 1, -12)
	statusPanel.Size = UDim2.fromOffset(if width < 650 then 245 else 310, 142)
	controls.Position = UDim2.new(1, -12, 1, if width < 650 then -170 else -18)
	for _, button in ipairs({ fireButton, reloadButton, unhideButton, sprintButton }) do
		button.Size = UDim2.fromOffset(if compact then 180 else 216, if touchEnabled then 43 else 36)
	end
end

local function finiteVector(value)
	return typeof(value) == "Vector3"
		and value.X == value.X and value.Y == value.Y and value.Z == value.Z
		and math.abs(value.X) < 1e6 and math.abs(value.Y) < 1e6 and math.abs(value.Z) < 1e6
end

local function effectPart(name, position, size, color)
	return create("Part", {
		Name = name,
		Anchored = true,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		CastShadow = false,
		Material = Enum.Material.Neon,
		Color = color,
		Size = size,
		Position = position,
	}, workspace)
end

effectsRemote.OnClientEvent:Connect(function(effect)
	if type(effect) ~= "table" then
		return
	end
	if effect.kind == "Shot" and finiteVector(effect.origin) and finiteVector(effect.position) then
		local distance = (effect.position - effect.origin).Magnitude
		if distance <= 0.01 or distance > 1000 then
			return
		end
		local beam = effectPart("GhostShiftPulse", (effect.origin + effect.position) / 2, Vector3.new(0.07, 0.07, distance), colors.Hunter)
		beam.CFrame = CFrame.lookAt((effect.origin + effect.position) / 2, effect.position)
		TweenService:Create(beam, TweenInfo.new(0.14), { Transparency = 1 }):Play()
		Debris:AddItem(beam, 0.2)
		local spark = effectPart("GhostShiftImpact", effect.position, Vector3.new(0.28, 0.28, 0.28), colors.Hunter)
		spark.Shape = Enum.PartType.Ball
		TweenService:Create(spark, TweenInfo.new(0.18), { Size = Vector3.new(1.1, 1.1, 1.1), Transparency = 1 }):Play()
		Debris:AddItem(spark, 0.22)
	elseif effect.kind == "Capture" and finiteVector(effect.position) then
		local burst = effectPart("GhostShiftCapture", effect.position, Vector3.new(1, 1, 1), colors.Ghost)
		burst.Shape = Enum.PartType.Ball
		burst.Transparency = 0.25
		TweenService:Create(burst, TweenInfo.new(0.5), { Size = Vector3.new(7, 7, 7), Transparency = 1 }):Play()
		Debris:AddItem(burst, 0.6)
		if effect.playerId == player.UserId then
			hitMarker.Visible = true
			task.delay(0.22, function()
				hitMarker.Visible = false
			end)
		end
	end
end)

stateRemote.OnClientEvent:Connect(function(snapshot)
	if type(snapshot) ~= "table" then
		return
	end
	state = snapshot
	updateState()
	updateTimers()
end)

local uiElapsed = 0
RunService.Heartbeat:Connect(function(delta)
	uiElapsed += delta
	if uiElapsed >= 0.1 then
		uiElapsed = 0
		updateTimers()
		responsiveLayout()
	end
end)

player.CharacterAdded:Connect(function()
	requestRemote:FireServer()
end)
updateState()
updateTimers()
responsiveLayout()
requestRemote:FireServer()
