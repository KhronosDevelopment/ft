local KDKit = require(game:GetService("ReplicatedFirst"):WaitForChild("KDKit"))

return {
    transitionSources = {},
    LocalPlayer = game.Players.LocalPlayer,
    LRT = KDKit.ReplicatedTable.players[game.Players.LocalPlayer.UserId],
}
