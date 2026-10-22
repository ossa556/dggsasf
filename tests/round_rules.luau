local rules = require("../src/shared/RoundRules")
local cases = 0

local function expect(actual, expected, description)
    cases += 1
    assert(actual == expected, description .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

expect(rules.chooseGhostCount(0), 0, "Empty server cannot assign a ghost")
expect(rules.chooseGhostCount(1), 0, "One player cannot start a competitive match")
for count = 2, 24 do
    local ghosts = rules.chooseGhostCount(count)
    local hunters = count - ghosts
    expect(ghosts >= 1 and hunters >= 1, true, "Both teams exist at player count " .. count)
    expect(math.abs(ghosts - hunters) <= 1, true, "Teams stay balanced at player count " .. count)
end

expect(rules.getWinner(1, 1, false), nil, "An active chase continues")
expect(rules.getWinner(2, 1, false), nil, "Unequal surviving teams do not end the chase")
expect(rules.getWinner(0, 1, false), "Hunters", "Capturing the last ghost ends the round")
expect(rules.getWinner(1, 0, false), "Ghosts", "Losing every hunter ends the round")
expect(rules.getWinner(1, 1, true), "Ghosts", "Surviving until timeout wins")
expect(rules.getWinner(0, 1, true), "Hunters", "Last capture takes priority over timeout")
expect(rules.getWinner(0, 0, false), "Draw", "Both teams gone is a draw")
expect(rules.getWinner(0, 0, true), "Draw", "Empty teams do not receive a timed win")
print("RoundRules: " .. cases .. " behavioral assertions passed.")
