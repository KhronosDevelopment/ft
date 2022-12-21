local PhysicsService = game:GetService("PhysicsService")

local KDKit = require(game.ReplicatedFirst:WaitForChild("KDKit"))
local Item = KDKit.Class.new("Player.Plot.Purchasable.Item")
Item.static.fruitFolder = workspace:WaitForChild("FRUITS")

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

function Item:disable()
    self.enabled = false
    self.instance.Parent = nil

    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end

    for fruit, _ in self.droppedFruits do
        pcall(fruit.Destroy, fruit)
    end

    table.clear(self.droppedFruits)
end

function Item:enable()
    self.instance.Parent = workspace
    self.enabled = true

    if self.type == "dropper" then
        local elapsed = 0
        self.connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
            elapsed += dt

            if elapsed > self.seconds then
                elapsed = 0
                self:performDrop()
            end
        end)
    elseif self.type == "upgrader" then
        self.connection = self.toucher.Touched:Connect(function(fruit)
            while fruit and fruit.Parent ~= Item.fruitFolder do
                fruit = fruit.Parent
            end
            if not fruit then
                return
            end

            if fruit:GetAttribute("upgraded_by_" .. self.uuid) then
                return
            end

            fruit:SetAttribute("value", fruit:GetAttribute("value") * self.multiplier)
            fruit:SetAttribute("upgraded_by_" .. self.uuid, true)
        end)
    end
end

function Item:performDrop()
    assert(self.type == "dropper", "cannot perform drop for non-dropper")

    local fruit = self.fruit:Clone()
    fruit:SetAttribute("owner", self.purchasable.manager.owner.player.id)
    fruit:SetAttribute("value", self.value)
    fruit.Parent = Item.fruitFolder
    self.droppedFruits[fruit] = true

    for _, descendant in fruit:GetDescendants() do
        if descendant:IsA("BasePart") then
            PhysicsService:SetPartCollisionGroup(descendant, "fruits")
        end
    end

    task.delay(180, function()
        if fruit.Parent then
            fruit:Destroy()
        end
    end)
end

return Item
