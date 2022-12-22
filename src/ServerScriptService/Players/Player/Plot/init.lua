local DeveloperProductsConfiguration =
    require(game:GetService("ServerStorage"):WaitForChild("DeveloperProducts.Configuration"))
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

function Plot:getCashMultiplier()
    local m = 1.5 ^ self.rebirths

    if self.manager.purchasablesByName["doublecash"].purchased then
        m *= 2
    end

    return m
end

function Plot:load(data, rebirths)
    self.data = { money = data.money or 0, purchases = data.purchases or {} }
    self.rebirths = rebirths or 0

    self:setMoney(data.money)

    KDKit.Utils:isort(self.data.purchases, function(k: string)
        return { select(2, k:gsub("%.", "")), k }
    end)
    for _, purchase in self.data.purchases do
        self.manager:purchase(purchase)
    end

    self:setRebirths(rebirths)

    self.loaded = true
end

function Plot:setRebirths(n)
    self.rebirths = n
    self.player.stats:setRebirths(n)
end

function Plot:setMoney(n)
    self.data.money = n
    self.player.stats:setMoney(n)
    self.manager:onMoneyChanged(n)
end

function Plot:earnMoney(n)
    self:setMoney(self.data.money + n * self:getCashMultiplier())
end

function Plot:spendMoney(n)
    if self.data.money >= n then
        self:setMoney(self.data.money - n)
        return true
    end

    return false
end

function Plot:purchase(name: string, price: number)
    if table.find(self.data.purchases, name) then
        self.manager:purchase(name)
        return
    end

    if self:spendMoney(price) then
        table.insert(self.data.purchases, name)
        self.manager:purchase(name)
    end
end

function Plot:getSpawnPoint(): CFrame
    return self.manager.spawnPoint
end

function Plot:awardDeveloperProduct(product: DeveloperProductsConfiguration.Config, afterPurchase: boolean): boolean
    return self.manager:awardDeveloperProduct(product, afterPurchase)
end

function Plot:destroy()
    self.maid:clean()
end

function Plot:rebirth()
    self:setRebirths(self.rebirths + 1)
    self.manager:clear(false)
end

return Plot
