local KDKit = require(game:GetService("ReplicatedFirst"):WaitForChild("KDKit"))
local sound = game:GetService("SoundService"):WaitForChild("madePurchase") :: Sound

KDKit.Remotes.madePurchase:connect(function()
    sound:Stop()

    sound.TimePosition = 0.5
    sound:Play()
end)
