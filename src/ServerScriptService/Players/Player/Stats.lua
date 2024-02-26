local KDKit = require(game.ReplicatedFirst:WaitForChild("KDKit"))
local Stats = KDKit.Class.new("Player.Stats")

function Stats:__init(player)
    self.player = player

    self.maid = KDKit.Maid.new()
    self.player.rv:set("stats", { money = 0, rebirths = 0 })

    self.instance = self.maid:give(Instance.new("Folder", self.player.instance))
    self.instance.Name = "leaderstats"

    Instance.new("IntValue", self.instance).Name = "Money"
    Instance.new("IntValue", self.instance).Name = "Rebirths"
end

function Stats:setMoney(value)
    self.player.rv:set("stats.money", value)
    self.instance.Money.Value = math.floor(value)
end

function Stats:setRebirths(rebirths)
    self.player.rv:set("stats.rebirths", rebirths)
    self.instance.Rebirths.Value = rebirths
end

function Stats:destroy()
    self.maid:clean()
end

return Stats
