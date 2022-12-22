local KDKit = require(game:GetService("ReplicatedFirst"):WaitForChild("KDKit"))

return {
    transitionSources = {
        BUTTON_PRESS = "BUTTON_PRESS",
    },
    LocalPlayer = game.Players.LocalPlayer,
    LRT = KDKit.ReplicatedTable.players[game.Players.LocalPlayer.UserId],
}
