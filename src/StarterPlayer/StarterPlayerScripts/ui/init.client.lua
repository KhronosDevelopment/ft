local KDKit = require(game:GetService("ReplicatedFirst"):WaitForChild("KDKit"))

local loadingApp = require(game:GetService("ReplicatedFirst"):WaitForChild("loading"):WaitForChild("app"))
local mainApp = KDKit.GUI.App.new(script:WaitForChild("main"))

loadingApp:waitForClose()
mainApp:open()
