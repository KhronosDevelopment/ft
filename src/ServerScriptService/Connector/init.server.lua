local KDKit = require(game:GetService("ReplicatedFirst"):WaitForChild("KDKit"))

KDKit.Preload:ensureDescendants(script)
KDKit.Utils:map(require, script:GetChildren())
