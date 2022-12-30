local KDKit = require(game:GetService("ReplicatedFirst"):WaitForChild("KDKit"))

local app = KDKit.GUI.App.new(script:WaitForChild("app"))
app:open()

if not game:IsLoaded() then
    game.Loaded:Wait()
end
KDKit.Remotes.loaded:wait()

app:close()
