local KDKit = require(game.ReplicatedFirst:WaitForChild("KDKit"))

local Plot = KDKit.Class.new("Player.Plot")
Plot.static.Manager = require(script:WaitForChild("Manager"))

function Plot:__init(player: "Class.Player")
    self.maid = KDKit.Maid.new()

    self.player = player

    self.manager = Plot.Manager:claim(self)
    self.maid:give(self.manager.unclaim, self.manager)

    self.loaded = false -- true upon first import
    self.rebirths = 0
    self.data = {}
end

function Plot:load(data, rebirths)
    self.data = { money = data.money or 0, purchases = data.purchases or {} }
    self.rebirths = rebirths or 0

    self:setRebirths(rebirths)

    self:setMoney(data.money)
    for _, purchase in self.data.purchases or {} do
        self:grantPurchase(purchase)
    end

    self.loaded = true
end

function Plot:setRebirths(n)
    self.rebirths = n
    self.player.stats:setRebirths(n)
end

function Plot:setMoney(n)
    self.data.money = n
    self.player.stats:setMoney(n)
end

function Plot:earnMoney(n)
    self:setMoney(self.data.money + n)
end

function Plot:grantPurchase(p)
    if not table.find(self.data.purchases, p) then
        table.insert(self.data.purchases, p)
    end

    print("granting purchase:", p)
end

function Plot:getSpawnPoint(): CFrame
    return self.manager.spawnPoint
end

function Plot:destroy()
    self.maid:clean()
end

return Plot
