local DeveloperProducts = require(game:GetService("ServerScriptService"):WaitForChild("DeveloperProducts"))
local DeveloperProductsConfiguration =
    require(game:GetService("ServerStorage"):WaitForChild("DeveloperProducts.Configuration"))
local KDKit = require(game.ReplicatedFirst:WaitForChild("KDKit"))

local Purchasable = require(script.Parent:WaitForChild("Purchasable"))

local Manager = KDKit.Class.new("Player.Plot.Manager")
Manager.static.folder = workspace:WaitForChild("PLOTS")
while true do
    Manager.static.template = workspace:FindFirstChild("PLOT_TEMPLATE")
        or game:GetService("ServerStorage"):WaitForChild("PLOT_TEMPLATE")

    if Manager.template then
        break
    else
        task.wait(0.1)
    end
end
Manager.static.list = {}

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
        self.instance:SetAttribute("fruitSold", (self.instance:GetAttribute("fruitSold") or 0) + 1)

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
        for _, manager in KDKit.Random:shuffle(self.list) do
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
        purchasable:reset(newPlayer)
    end

    -- because this requires top-down information, we need to re-render again
    for name, purchasable in self.purchasablesByName do
        purchasable:restyleButton()
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

Manager.template.Parent = game:GetService("ServerStorage")
KDKit.Preload:ensureDescendants(Manager.folder)
KDKit.Preload:ensureDescendants(Manager.template)
for _, root in Manager.folder:GetChildren() do
    local instance = Manager.template:Clone()
    local orientation: CFrame = root.CFrame - root.CFrame.Position

    instance:PivotTo(root.CFrame)
    instance.Parent = Manager.folder
    instance.Name = "plot"

    for _, descendant in instance:GetDescendants() do
        if descendant:IsA("BasePart") then
            descendant.AssemblyLinearVelocity = orientation:PointToWorldSpace(descendant.AssemblyLinearVelocity)
        end
    end

    table.insert(Manager.static.list, Manager.new(instance))
    root:Destroy()
end

return Manager
