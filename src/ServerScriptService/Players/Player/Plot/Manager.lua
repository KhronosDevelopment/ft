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

        if part:IsDescendantOf(self.owner.player.character.instance) then
            purchasable:purchase()
        end
    end)
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
    self:clear()
end

function Manager:clear()
    print("clearing")
end

KDKit.Preload:ensureDescendants(Manager.folder)
Manager.static.list = KDKit.Utils:map(Manager.new, Manager.folder:GetChildren())

return Manager
