local PhysicsService = game:GetService("PhysicsService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local KDKit = require(game.ReplicatedFirst:WaitForChild("KDKit"))
local Item = KDKit.Class.new("Player.Plot.Purchasable.Item")
Item.static.fruitFolder = workspace:WaitForChild("FRUITS")

Item.static.droppers = {}

function Item:__init(purchasable: "Class.Player.Plot.Purchasable", instance: Model)
    self.purchasable = purchasable
    self.instance = instance

    self.type = instance.Name
    if self.type == "dropper" then
        self.fruit = self.instance.drop
        self.fruit.Parent = nil
        self.droppedFruits = {}

        self.seconds = self.instance:GetAttribute("seconds")
        self.value = self.instance:GetAttribute("value")

        if not self.seconds then
            error("dropper is missing seconds attribute: " .. instance:GetFullName())
        end

        if not self.value then
            error("dropper is missing value attribute: " .. instance:GetFullName())
        end

        for _, descendant in self.fruit:GetDescendants() do
            if descendant:IsA("BasePart") then
                descendant.Anchored = false
            end
        end

        table.insert(Item.droppers, self)
    elseif self.type == "upgrader" then
        self.toucher = self.instance.toucher
        self.multiplier = self.instance:GetAttribute("multiplier")
        self.uuid = KDKit.Random:uuid(8)

        if not self.multiplier then
            error("upgrader is missing multiplier attribute: " .. instance:GetFullName())
        end
    elseif self.type == "model" then
        -- do nothing :)
    else
        error("invalid purchasable item type: " .. instance:GetFullName())
    end

    self:disable()
end

function Item:getSubtitle()
    if self.type == "dropper" then
        return ("(+$%s)"):format(KDKit.Humanize:money(self.value))
    elseif self.type == "upgrader" then
        return ("(x%g)"):format(self.multiplier)
    end

    return ""
end

function Item:disable()
    debug.profilebegin("Item:disable()")
    self.enabled = false
    self.instance.Parent = nil

    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end

    if self.type == "dropper" then
        for fruit, _ in self.droppedFruits do
            pcall(fruit.Destroy, fruit)
        end

        table.clear(self.droppedFruits)
    end
    debug.profileend()
end

function Item:enable()
    debug.profilebegin("Item:enable()")
    self.instance.Parent = workspace
    self.enabled = true

    if self.type == "dropper" then
        self.nextDropAt = os.clock()
    elseif self.type == "upgrader" then
        self.connection = self.toucher.Touched:Connect(function(fruit)
            debug.profilebegin("upgrader.Touched")
            while fruit and fruit.Parent ~= Item.fruitFolder do
                fruit = fruit.Parent
            end
            if not fruit then
                debug.profileend()
                return
            end

            if fruit:GetAttribute("upgraded_by_" .. self.uuid) then
                debug.profileend()
                return
            end

            fruit:SetAttribute("value", fruit:GetAttribute("value") * self.multiplier)
            fruit:SetAttribute("upgraded_by_" .. self.uuid, true)
            debug.profileend()
        end)
    end

    debug.profileend()
end

function Item:performDrop()
    debug.profilebegin("Item:performDrop()")
    assert(self.type == "dropper", "cannot perform drop for non-dropper")

    local fruit = self.fruit:Clone()
    fruit:SetAttribute("owner", self.purchasable.manager.owner.player.id)
    fruit:SetAttribute("value", self.value)
    fruit.Parent = Item.fruitFolder
    self.droppedFruits[fruit] = true

    for _, descendant in fruit:GetDescendants() do
        if descendant:IsA("BasePart") then
            PhysicsService:SetPartCollisionGroup(descendant, "fruits")
            descendant:SetNetworkOwner(self.purchasable.manager.owner.player.instance)
        end
    end

    Debris:AddItem(fruit, 300)
    debug.profileend()
end

function Item.static:cycle()
    debug.profilebegin("Item.static:cycle()")
    local now = os.clock()
    for _, dropper in self.droppers do
        if dropper.enabled and now >= dropper.nextDropAt then
            dropper:performDrop()
            dropper.nextDropAt = now + dropper.seconds
        end
    end
    debug.profileend()
end

RunService.Heartbeat:Connect(function()
    Item:cycle()
end)

return Item
