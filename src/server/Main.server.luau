-- GHOST SHIFT: one server owns the match and every gameplay decision.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local shared = ReplicatedStorage:WaitForChild("GhostShift")
local Config = require(shared:WaitForChild("Config"))
local MapService = require(script.Parent:WaitForChild("MapService"))
local GameplayService = require(script.Parent:WaitForChild("GameplayService"))
local RoundService = require(script.Parent:WaitForChild("RoundService"))

local function instance(parent, className, name)
    local existing = parent:FindFirstChild(name)
    if existing then
        assert(existing:IsA(className), name .. " has an unexpected class")
        return existing
    end
    local created = Instance.new(className)
    created.Name = name
    created.Parent = parent
    return created
end

local remoteFolder = instance(shared, "Folder", "Remotes")
local remotes = {}
for _, name in { "Fire", "Reload", "ToggleDisguise", "Ability", "State", "Effects", "RequestState" } do
    remotes[name] = instance(remoteFolder, "RemoteEvent", name)
end

local teams = {}
for name, color in { Lobby = "Medium stone grey", Ghosts = "Royal purple", Hunters = "Cyan" } do
    local team = instance(Teams, "Team", name)
    team.AutoAssignable = false
    team.TeamColor = BrickColor.new(color)
    teams[name] = team
end

local map = MapService.Build()
local ctx = {
    Config = Config,
    RoundRules = require(shared:WaitForChild("RoundRules")),
    Remotes = remotes,
    Teams = teams,
    Map = map.Map,
    Props = map.Props,
    Spawns = map.Spawns,
    PlayerState = {},
    Round = { Id = 0, Phase = "Lobby", EndsAt = 0, Winner = "", Message = "Waiting for players" },
}

function ctx.Award(player, statName, amount)
    if not player.Parent or type(amount) ~= "number" or amount <= 0 then
        return
    end
    local stats = player:FindFirstChild("leaderstats")
    local stat = stats and stats:FindFirstChild(statName)
    if stat and stat:IsA("IntValue") then
        stat.Value += math.floor(amount)
    end
end

function ctx.Broadcast(onlyPlayer)
    local ghostsAlive, huntersAlive = 0, 0
    for _, state in ctx.PlayerState do
        if state.Alive then
            if state.Role == "Ghost" then
                ghostsAlive += 1
            elseif state.Role == "Hunter" then
                huntersAlive += 1
            end
        end
    end
    for player, state in ctx.PlayerState do
        if player.Parent == Players and (onlyPlayer == nil or onlyPlayer == player) then
            local stats = player:FindFirstChild("leaderstats")
            local coins = stats and stats:FindFirstChild("Coins")
            local wins = stats and stats:FindFirstChild("Wins")
            remotes.State:FireClient(player, {
                phase = ctx.Round.Phase,
                roundId = ctx.Round.Id,
                endsAt = ctx.Round.EndsAt,
                winner = ctx.Round.Winner,
                message = ctx.Round.Message,
                role = state.Role,
                alive = state.Alive,
                ammo = state.Ammo,
                magazine = Config.Weapons.Pulse.Magazine,
                reloadUntil = state.ReloadUntil,
                captures = state.Captures,
                coins = if coins then coins.Value else 0,
                wins = if wins then wins.Value else 0,
                ghostsAlive = ghostsAlive,
                huntersAlive = huntersAlive,
                disguised = state.Disguise ~= nil,
                abilityReadyAt = state.AbilityReadyAt,
                detectorDistance = if ctx.DetectorDistance then ctx.DetectorDistance(player) else nil,
            })
        end
    end
end

GameplayService.Start(ctx)
RoundService.Start(ctx)

local requestTimes = {}
remotes.RequestState.OnServerEvent:Connect(function(player)
    local now = workspace:GetServerTimeNow()
    if now - (requestTimes[player] or -math.huge) < 1 then
        return
    end
    requestTimes[player] = now
    ctx.Broadcast(player)
end)

local function onPlayerAdded(player)
    if ctx.PlayerState[player] then
        return
    end
    ctx.PlayerState[player] = {
        Role = "Lobby",
        Alive = false,
        Captures = 0,
        Ammo = Config.Weapons.Pulse.Magazine,
        ReloadUntil = 0,
        LastFire = -math.huge,
        AbilityReadyAt = 0,
        Disguise = nil,
    }
    local stats = instance(player, "Folder", "leaderstats")
    for _, name in { "Coins", "Wins", "Captures" } do
        instance(stats, "IntValue", name)
    end
    ctx.HandleJoiningPlayer(player)
    local function onCharacter(character)
        local state = ctx.PlayerState[player]
        if not state or state.PreparingCharacter == character or state.PreparedCharacter == character then
            return
        end
        state.PreparingCharacter = character
        task.spawn(function()
            local humanoid = character:WaitForChild("Humanoid", 10)
            local root = character:WaitForChild("HumanoidRootPart", 10)
            if not humanoid or not root or player.Character ~= character or not ctx.PlayerState[player] then
                return
            end
            ctx.PrepareCharacter(player, character)
            ctx.HandleCharacter(player, character)
            if player.Character == character and ctx.PlayerState[player] == state then
                state.PreparedCharacter = character
                state.PreparingCharacter = nil
            end
        end)
    end
    player.CharacterAdded:Connect(onCharacter)
    if player.Character then
        onCharacter(player.Character)
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
    if ctx.Eliminate then
        ctx.Eliminate(player)
    end
    if ctx.CleanupPlayer then
        ctx.CleanupPlayer(player)
    end
    ctx.PlayerState[player] = nil
    requestTimes[player] = nil
end)
for _, player in Players:GetPlayers() do
    onPlayerAdded(player)
end

print("[GHOST SHIFT] Station loaded. Start a Studio server with at least two clients to play.")
