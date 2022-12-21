local KDKit = require(game.ReplicatedFirst:WaitForChild("KDKit"))
local Purchasable = KDKit.Class.new("Player.Plot.Purchasable")
Purchasable.static.Item = require(script:WaitForChild("Item"))

function Purchasable:__init(
    manager: "Class.Player.Plot.Manager",
    instance: Folder,
    parent: "class.Player.Plot.Purchasable"?
)
    self.manager = manager
    self.instance = instance
    self.parent = parent
    self.price = self.instance:GetAttribute("price")
    if not self.price then
        error("missing price attribute for purchasable: " .. self.instance:GetFullName())
    end

    self.name = if parent then parent.name .. "." .. instance.Name else instance.Name

    self.children = {}
    for _, child in self.instance:GetChildren() do
        if child:IsA("Folder") then
            table.insert(self.children, Purchasable.new(self.manager, child, self))
        elseif child:IsA("Model") then
            if self.item then
                error("Purchasable has multiple items: " .. self.name)
            end

            self.item = Purchasable.Item.new(self, self.instance:FindFirstChildOfClass("Model"))
        elseif child:IsA("Part") and child.Name == "pad" then
            if self.button then
                error("Purchasable has multiple button pads: " .. self.name)
            end

            self.button = child
        else
            error("Unrecognized instance in Purchasable: " .. child:GetFullName())
        end
    end

    if not self.button then
        error("Purchasable is missing a button pad: " .. self.name)
    end

    if not self.item then
        error("Purchasable is missing an item: " .. self.name)
    end

    self.purchased = true
    self:unPurchase()

    self.manager:addPurchasable(self)
end

function Purchasable:unPurchase()
    if not self.purchased then
        return
    end
    self.purchased = false

    self.item:disable()
    self.button.Parent = if self:purchasable() then workspace else nil

    for _, child in self.children do
        child:unPurchase()
    end
end

function Purchasable:purchase()
    if self.purchased then
        return
    end
    self.purchased = true

    self.item:enable()
    self.button.Parent = nil

    for _, child in self.children do
        child.button.Parent = workspace
    end
end

function Purchasable:purchasable()
    return not self.purchased and (not self.parent or self.parent.purchased)
end

return Purchasable
