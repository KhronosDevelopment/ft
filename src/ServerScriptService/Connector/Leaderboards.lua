local KDKit = require(game:GetService("ReplicatedFirst"):WaitForChild("KDKit"))
local Leaderboards = require(game:GetService("ServerScriptService"):WaitForChild("Leaderboards"))

function update()
    KDKit.Utils:ensure(function(failed, traceback)
        if failed then
            (KDKit.API.log / "error"):dePOST({
                title = "Unhandled Exception",
                description = traceback,
                fields = {
                    during = "Leaderboards.update",
                },
            })
        end
    end, Leaderboards.update, Leaderboards)
end

task.defer(function()
    while true do
        task.defer(update)
        task.wait(60)
    end
end)

return nil
