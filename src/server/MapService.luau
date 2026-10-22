-- Procedural baseline station: no external models, asset IDs, or embedded scripts.
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local MapService = {}

local COLORS = {
	Concrete = Color3.fromRGB(47, 52, 64),
	Wall = Color3.fromRGB(36, 41, 53),
	Metal = Color3.fromRGB(74, 85, 98),
	Dark = Color3.fromRGB(20, 25, 34),
	Cyan = Color3.fromRGB(77, 225, 237),
	Violet = Color3.fromRGB(177, 124, 245),
	Amber = Color3.fromRGB(255, 190, 94),
	White = Color3.fromRGB(224, 232, 238),
}

local function part(parent, name, size, position, color, material)
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.CFrame = CFrame.new(position)
	item.Color = color
	item.Material = material or Enum.Material.Concrete
	item.Anchored = true
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Parent = parent
	return item
end

local function sign(parent, name, position, size, text, textColor, face)
	local board = part(parent, name, size, position, COLORS.Dark, Enum.Material.Metal)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "StationSign"
	gui.Face = face or Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(1200, 280)
	gui.LightInfluence = 0
	gui.PixelsPerStud = 50
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = textColor or COLORS.White
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = gui
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 20)
	padding.PaddingRight = UDim.new(0, 20)
	padding.PaddingTop = UDim.new(0, 15)
	padding.PaddingBottom = UDim.new(0, 15)
	padding.Parent = label
	return board
end

local function lamp(parent, name, position, color, brightness, range)
	local fixture = part(parent, name, Vector3.new(5, 0.35, 1.4), position, color, Enum.Material.Neon)
	fixture.CanCollide = false
	fixture.CanTouch = false
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness
	light.Range = range
	light.Shadows = true
	light.Parent = fixture
	return fixture
end

local function prop(parent, name, kind, size, position, color, material)
	local item = part(parent, name, size, position, color, material)
	item:SetAttribute("GhostShiftProp", true)
	item:SetAttribute("DisguiseKind", kind)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "DisguisePrompt"
	prompt.ActionText = "Possess"
	prompt.ObjectText = kind
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = true
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Parent = item
	return item
end

local function bench(parent, position, color)
	part(parent, "BenchSeat", Vector3.new(10, 0.6, 2.8), position + Vector3.new(0, 1.8, 0), color, Enum.Material.Metal)
	part(parent, "BenchBack", Vector3.new(10, 2.5, 0.45), position + Vector3.new(0, 3.2, 1.2), color, Enum.Material.Metal)
	for _, x in {-3.6, 3.6} do
		part(parent, "BenchLeg", Vector3.new(0.5, 1.7, 2.2), position + Vector3.new(x, 0.85, 0), COLORS.Metal, Enum.Material.Metal)
	end
end

local function buildStation(model, props)
	local architecture = Instance.new("Folder")
	architecture.Name = "Architecture"
	architecture.Parent = model
	local details = Instance.new("Folder")
	details.Name = "StationDetails"
	details.Parent = model

	-- Level floor keeps capture line-of-sight and avatar movement predictable.
	part(architecture, "StationFloor", Vector3.new(140, 1, 100), Vector3.new(0, -0.5, 0), COLORS.Concrete)
	part(architecture, "NorthWall", Vector3.new(140, 21, 1), Vector3.new(0, 10.5, -50), COLORS.Wall)
	part(architecture, "SouthWall", Vector3.new(140, 21, 1), Vector3.new(0, 10.5, 50), COLORS.Wall)
	part(architecture, "WestWall", Vector3.new(1, 21, 100), Vector3.new(-70, 10.5, 0), COLORS.Wall)
	part(architecture, "EastWall", Vector3.new(1, 21, 100), Vector3.new(70, 10.5, 0), COLORS.Wall)
	part(architecture, "StationRoof", Vector3.new(141, 1, 101), Vector3.new(0, 21.5, 0), COLORS.Wall)

	-- The tracks are static scenery at floor level, not a damaging train system.
	part(details, "TrackBed", Vector3.new(136, 0.08, 12), Vector3.new(0, 0.04, 30), COLORS.Dark, Enum.Material.Slate)
	for x = -64, 64, 5 do
		part(details, "Sleeper", Vector3.new(0.6, 0.16, 10), Vector3.new(x, 0.12, 30), Color3.fromRGB(74, 64, 57), Enum.Material.Wood)
	end
	for _, z in {27, 33} do
		part(details, "Rail", Vector3.new(135, 0.25, 0.3), Vector3.new(0, 0.26, z), COLORS.Metal, Enum.Material.Metal)
	end
	for _, z in {22.8, 37.2} do
		part(details, "PlatformSafetyLine", Vector3.new(134, 0.06, 0.45), Vector3.new(0, 0.05, z), COLORS.Amber, Enum.Material.Neon)
	end

	for _, x in {-48, -16, 16, 48} do
		for _, z in {-18, 16} do
			part(architecture, "StationPillar", Vector3.new(3, 21, 3), Vector3.new(x, 10.5, z), COLORS.Metal)
			part(details, "PillarBand", Vector3.new(3.08, 0.28, 3.08), Vector3.new(x, 5.5, z), COLORS.Cyan, Enum.Material.Neon)
		end
	end
	for _, x in {-48, -16, 16, 48} do
		lamp(details, "HallLamp", Vector3.new(x, 18.7, -4), COLORS.Cyan, 1.7, 35)
		lamp(details, "PlatformLamp", Vector3.new(x, 18.7, 40), COLORS.Violet, 1.2, 29)
	end

	for _, x in {-42, -10, 25} do
		bench(details, Vector3.new(x, 0, -34), COLORS.Metal)
	end
	for _, x in {-40, 4, 42} do
		bench(details, Vector3.new(x, 0, 8), Color3.fromRGB(62, 74, 82))
	end
	-- Cover creates several routes without sealing off either side of the hall.
	part(details, "TicketCounter", Vector3.new(18, 4.5, 4), Vector3.new(42, 2.25, -39), COLORS.Wall)
	part(details, "TicketCounterGlass", Vector3.new(18, 3.5, 0.2), Vector3.new(42, 6.25, -40.7), Color3.fromRGB(104, 143, 151), Enum.Material.Glass).Transparency = 0.45
	part(details, "NoticeBoard", Vector3.new(14, 5, 0.6), Vector3.new(-43, 6, -49), COLORS.Metal, Enum.Material.Metal)

	sign(details, "StationTitle", Vector3.new(0, 14, -49.25), Vector3.new(31, 4, 0.4), "GHOST SHIFT  /  LAST DEPARTURE", COLORS.Cyan, Enum.NormalId.Back)
	sign(details, "FrozenClock", Vector3.new(0, 8.5, -49.1), Vector3.new(10, 3, 0.5), "03:17", COLORS.Amber, Enum.NormalId.Back)
	sign(details, "PlatformSign", Vector3.new(0, 13, 48.9), Vector3.new(31, 3.5, 0.4), "PLATFORM 03  /  SERVICE SUSPENDED", COLORS.Violet)
	sign(details, "WaitingSign", Vector3.new(-43, 6, -48.5), Vector3.new(13, 4.3, 0.2), "DO NOT FOLLOW THE LIGHTS", COLORS.White, Enum.NormalId.Back)

	local crates = {
		Vector3.new(-57, 1.5, -36), Vector3.new(-54, 1.5, -6),
		Vector3.new(-24, 1.5, -22), Vector3.new(8, 1.5, -25),
		Vector3.new(54, 1.5, -12), Vector3.new(30, 1.5, 42),
	}
	for index, position in crates do
		prop(props, "FreightCrate" .. index, "Freight crate", Vector3.new(3, 3, 3), position, Color3.fromRGB(100, 82, 61), Enum.Material.WoodPlanks)
	end
	local luggage = {
		Vector3.new(-36, 0.9, -36), Vector3.new(-7, 0.9, -32),
		Vector3.new(28, 0.9, -30), Vector3.new(-37, 0.9, 11),
		Vector3.new(9, 0.9, 10), Vector3.new(51, 0.9, 39),
	}
	for index, position in luggage do
		prop(props, "LostLuggage" .. index, "Lost luggage", Vector3.new(2.5, 1.8, 1.5), position, index % 2 == 0 and COLORS.Violet or Color3.fromRGB(68, 94, 102), Enum.Material.Fabric)
	end
	for index, position in {Vector3.new(-61, 1.5, 42), Vector3.new(58, 1.5, -37), Vector3.new(22, 1.5, 2)} do
		local bin = prop(props, "WasteBin" .. index, "Station bin", Vector3.new(2.1, 3, 2.1), position, Color3.fromRGB(61, 83, 79), Enum.Material.Metal)
		bin.Shape = Enum.PartType.Cylinder
		bin.Size = Vector3.new(3, 2.1, 2.1)
		bin.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2)
	end
	prop(props, "SupplyCase", "Supply case", Vector3.new(3.5, 2.3, 2.3), Vector3.new(-4, 1.15, 43), COLORS.Metal, Enum.Material.Metal)

	-- Vending machine is scenery; only deliberately modest props are possessable.
	local vending = part(details, "VendingMachine", Vector3.new(4.5, 7, 3.5), Vector3.new(62, 3.5, -41), COLORS.Wall, Enum.Material.Metal)
	sign(details, "VendingDisplay", vending.Position + Vector3.new(0, 1, 1.8), Vector3.new(3.4, 3.4, 0.15), "OUT\nOF\nSERVICE", COLORS.Amber, Enum.NormalId.Back)

	return architecture, details
end

local function buildLobby(model)
	local lobby = Instance.new("Folder")
	lobby.Name = "SafeLobby"
	lobby.Parent = model
	local center = Vector3.new(112, 0, 0)
	part(lobby, "LobbyFloor", Vector3.new(38, 1, 38), center + Vector3.new(0, -0.5, 0), COLORS.Concrete)
	part(lobby, "LobbyRoof", Vector3.new(39, 1, 39), center + Vector3.new(0, 16.5, 0), COLORS.Wall)
	for _, x in {-19, 19} do
		part(lobby, "LobbySideWall", Vector3.new(1, 16, 38), center + Vector3.new(x, 8, 0), COLORS.Wall)
	end
	for _, z in {-19, 19} do
		part(lobby, "LobbyEndWall", Vector3.new(38, 16, 1), center + Vector3.new(0, 8, z), COLORS.Wall)
	end
	lamp(lobby, "LobbyLight", center + Vector3.new(0, 13, 0), COLORS.Cyan, 2.4, 35)
	sign(lobby, "LobbyTitle", center + Vector3.new(0, 11, -18.2), Vector3.new(27, 3.2, 0.3), "GHOST SHIFT  /  03:17", COLORS.Cyan, Enum.NormalId.Back)
	sign(lobby, "LobbyInstructions", center + Vector3.new(0, 6, -18), Vector3.new(28, 5, 0.3), "WAITING ROOM\nGhosts: E possess / Q release / F sprint\nHunters: click capture / R reload", COLORS.White, Enum.NormalId.Back)
	bench(lobby, center + Vector3.new(-9, 0, 10), COLORS.Metal)
	bench(lobby, center + Vector3.new(5, 0, 10), COLORS.Metal)
	return CFrame.new(center + Vector3.new(0, 4, 0))
end

function MapService.Build()
	assert(not Workspace:FindFirstChild("GhostShiftMap"), "GhostShiftMap already exists. Build the new project in a separate place; existing map was not changed.")
	local map = Instance.new("Model")
	map.Name = "GhostShiftMap"
	map:SetAttribute("GhostShiftGeneratedMap", true)
	map.Parent = Workspace
	local props = Instance.new("Folder")
	props.Name = "Props"
	props.Parent = map
	buildStation(map, props)
	local lobbySpawn = buildLobby(map)

	Lighting.ClockTime = 3 + 17 / 60
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(68, 74, 92)
	Lighting.OutdoorAmbient = Color3.fromRGB(53, 58, 74)
	Lighting.FogColor = Color3.fromRGB(24, 30, 45)
	Lighting.FogStart = 130
	Lighting.FogEnd = 330
	Lighting.GlobalShadows = true
	Lighting.ExposureCompensation = 0.15
	Lighting.EnvironmentDiffuseScale = 0.45
	Lighting.EnvironmentSpecularScale = 0.6
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "GhostShiftGrade"
	grade.Brightness = 0.015
	grade.Contrast = 0.09
	grade.Saturation = -0.15
	grade.TintColor = Color3.fromRGB(220, 232, 255)
	grade.Parent = Lighting

	return {
		Map = map,
		Props = props,
		Spawns = {
			Lobby = lobbySpawn,
			Ghosts = {
				CFrame.new(-56, 4, -30), CFrame.new(52, 4, 41),
				CFrame.new(-50, 4, 41), CFrame.new(30, 4, -26),
			},
			Hunters = {
				CFrame.new(52, 4, -4), CFrame.new(42, 4, -7),
				CFrame.new(53, 4, 7), CFrame.new(35, 4, -4),
			},
		},
	}
end

return MapService
