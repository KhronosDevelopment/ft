local KDKit = require(game:GetService("ReplicatedFirst"):WaitForChild("KDKit"))

return {
    transitionSources = {
        BUTTON_PRESS = "BUTTON_PRESS",
    },
    LocalPlayer = game.Players.LocalPlayer,
    LRV = KDKit.ReplicatedValue:get("player_" .. game.Players.LocalPlayer.UserId),
}
