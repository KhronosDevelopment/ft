local KDKit = require(game:WaitForChild("ReplicatedFirst"):WaitForChild("KDKit"))
local Players = require(game:WaitForChild("ServerScriptService"):WaitForChild("Players"))

Players.folder.PlayerAdded:Connect(function(playerInstance)
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

Players.folder.PlayerRemoving:Connect(function(playerInstance)
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

return Players
