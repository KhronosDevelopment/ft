local KDKit = require(game:GetService("ReplicatedFirst"):WaitForChild("KDKit"))
local Players = require(game:GetService("ServerScriptService"):WaitForChild("Players"))

Players.folder.PlayerAdded:Connect(function(playerInstance: Player)
    KDKit.Utils:ensure(function(failed, traceback)
        if failed then
            (KDKit.API.log / "error"):dpePOST(playerInstance, {
                title = "Unhandled Exception",
                description = traceback,
                fields = {
                    during = "Players.joined",
                    player_id = playerInstance.UserId,
                },
            })
        end
    end, Players.joined, Players, playerInstance)
end)

Players.folder.PlayerRemoving:Connect(function(playerInstance: Player)
    KDKit.Utils:ensure(function(failed, traceback)
        if failed then
            (KDKit.API.log / "error"):dpePOST(playerInstance, {
                title = "Unhandled Exception",
                description = traceback,
                fields = {
                    during = "Players.left",
                    player_id = playerInstance.UserId,
                },
            })
        end
    end, Players.left, Players, playerInstance)
end)

KDKit.Remotes.rebirth:connect(function(playerInstance: Player): boolean
    return Players:rebirth(playerInstance)
end)

return Players
