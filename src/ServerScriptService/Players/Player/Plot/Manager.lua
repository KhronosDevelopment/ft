local DeveloperProducts = require(game:GetService("ServerScriptService"):WaitForChild("DeveloperProducts"))
local DeveloperProductsConfiguration =
    require(game:GetService("ServerStorage"):WaitForChild("DeveloperProducts.Configuration"))
local KDKit = require(game.ReplicatedFirst:WaitForChild("KDKit"))

local Purchasable = require(script.Parent:WaitForChild("Purchasable"))

local Manager = KDKit.Class.new("Player.Plot.Manager")
Manager.static.folder = workspace:WaitForChild("PLOTS")

function Manager:__init(instance: Model)
    self.instance = instance
    self.owner = nil :: "Class.Player.Plot"?

    self.spawnPoint = self.instance.spawn.CFrame :: CFrame
    self.instance.dropoff.Touched:Connect(function(fruit)
        if not self.owner or not self.owner.player then
            return
        end

        while fruit and fruit.Parent ~= Purchasable.Item.fruitFolder do
            fruit = fruit.Parent
        end

        if not fruit then
            return
        end

        if fruit:GetAttribute("owner") ~= self.owner.player.id then
            return
        end

        local value = fruit:GetAttribute("value")
        fruit:Destroy()

        self.instance.moneyGui.container.label.Text = "+$"
            .. KDKit.Humanize:money(value * self.owner:getCashMultiplier())
        self.instance.moneyGui:SetAttribute("n", (self.instance.moneyGui:GetAttribute("n") or 0) + 1)

        self.owner:earnMoney(value)
    end)

    self.purchasablesByName = {} :: { [string]: "Class.Player.Plot.Purchasable" }

    for _, purchasableInstance in self.instance.buttons:GetChildren() do
        Purchasable.new(self, purchasableInstance)
    end
end

function Manager:addPurchasable(purchasable: "Class.Player.Plot.Purchasable")
    if self.purchasablesByName[purchasable.name] then
        error("duplicate purchasable name: " .. purchasable.name)
    end

    self.purchasablesByName[purchasable.name] = purchasable

    purchasable.button.Touched:Connect(function(part)
        if not self.owner or not purchasable:purchasable() then
            return
        end

        if not part:IsDescendantOf(self.owner.player.character.instance) then
            return
        end

        if purchasable.developerProduct and not purchasable.playerHasDeveloperProduct then
            DeveloperProducts:prompt(self.owner.player, purchasable.developerProduct.name)
        else
            self.owner:purchase(purchasable.name, purchasable.price)
        end
    end)
end

function Manager:purchase(name)
    self.purchasablesByName[name]:purchase()
end

function Manager:claim(by: "Class.Player.Plot"): "Class.Player.Plot.Manager"
    if self == Manager then
        -- statically called
        for _, manager in self.list do
            if not manager.owner then
                manager:claim(by)
                return manager
            end
        end

        error("failed to claim a manager")
    else
        -- called on an instance
        if self.owner ~= nil then
            error(("cannot claim a manager which is already owned (by %d)"):format(self.owner.player.id))
        end

        self.owner = by
        return self
    end
end

function Manager:unclaim()
    self.owner = nil
    self:clear(true)
end

function Manager:clear(newPlayer)
    for name, purchasable in self.purchasablesByName do
        purchasable:unPurchase(newPlayer)
    end
end

function Manager:awardDeveloperProduct(product: DeveloperProductsConfiguration.Config, afterPurchase: boolean): boolean
    if product.purchases then
        local purchasable = self.purchasablesByName[product.purchases]
        purchasable:setPlayerHasDeveloperProduct(true)

        if afterPurchase and purchasable:purchasable() then
            purchasable:purchase()
        end

        return true
    end

    return false
end

function Manager:onMoneyChanged(money: number)
    for name, purchasable in self.purchasablesByName do
        if purchasable.purchasable then
            purchasable:setAffordable(purchasable.price <= money)
        end
    end
end

KDKit.Preload:ensureDescendants(Manager.folder)
Manager.static.list = KDKit.Utils:map(Manager.new, Manager.folder:GetChildren())

return Manager
