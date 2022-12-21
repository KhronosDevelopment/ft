local KDKit = require(game.ReplicatedFirst:WaitForChild("KDKit"))

local Plot = KDKit.Class.new("Player.Base")
Plot.static.folder = workspace:WaitForChild("PLOTS")

KDKit.Preload:ensureChildren(Plot.folder)
Plot.static.instances = Plot.folder:GetChildren()

function Plot.static:claimNext(player: "Class.Player"): Instance
    local available = {}
    for _, instance in Plot.instances do
        if instance.Name == "unclaimed" then
            table.insert(available, instance)
        end
    end

    if not next(available) then
        task.wait(1)
        return self:claimNext()
    end

    local plot = KDKit.Random:linearChoice(available)
    assert(player:isValid(), "Player became invalid before being able to claim a plot")

    plot.Name = player.id

    return plot
end

function Plot.static:unclaim(plot: Instance): nil
    plot.Name = "unclaimed"
end

function Plot:__init(player: "Class.Player")
    self.player = player
    self.instance = Plot:claimNext(self.player)

    self.loaded = false -- true upon first import
    self.rebirths = 0
    self.data = {}

    self.maid = KDKit.Maid.new()
    self.maid:give(Plot.unclaim, Plot, self.instance)
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

function Plot:grantPurchase(p)
    if not table.find(self.data.purchases, p) then
        table.insert(self.data.purchases, p)
    end

    print("granting purchase:", p)
end

function Plot:destroy()
    self.maid:clean()
end

return Plot
