--!strict
-- Public gameplay tuning only. The server remains authoritative.
return table.freeze({
    MinPlayers = 2,
    IntermissionSeconds = 15,
    HideSeconds = 20,
    HuntSeconds = 150,
    ResultsSeconds = 10,
    CaptureReward = 15,
    WinReward = 40,
    GhostSpeed = 16,
    HunterSpeed = 16,
    SprintSpeed = 28,
    SprintSeconds = 3,
    SprintCooldown = 12,
    DisguiseDistance = 10,
    DetectorRange = 90,
    Weapons = table.freeze({
        Pulse = table.freeze({
            Magazine = 6,
            FireInterval = 0.65,
            ReloadSeconds = 2.5,
            Range = 130,
        }),
    }),
})
