local KDKit = require(game.ReplicatedFirst:WaitForChild("KDKit"))
local DeveloperProducts = require(game:GetService("ServerScriptService"):WaitForChild("DeveloperProducts"))
local Purchasable = KDKit.Class.new("Player.Plot.Purchasable")
Purchasable.static.Item = require(script:WaitForChild("Item"))
Purchasable.static.buttonTemplate = game:GetService("ServerStorage"):WaitForChild("BUTTON_PAD") :: Model

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
    self.affordable = false

    self.developerProductName = self.instance:GetAttribute("developer_product")
    if self.developerProductName then
        self.developerProduct = DeveloperProducts:get(self.developerProductName)
        if not self.developerProduct then
            error("Invalid developer product for purchasable: " .. self.instance:GetFullName())
        end
    end
    self.playerHasDeveloperProduct = false

    self.name = if parent then parent.name .. "." .. instance.Name else instance.Name
    self.humanName = self.instance:GetAttribute("humanName")
    if not self.humanName then
        error("missing humanName attribute for purchasable: " .. self.instance:GetFullName())
    end

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

            self.button = child :: Part
            self.button.Transparency = 1

            local visual = Purchasable.buttonTemplate:Clone() :: Model
            visual:PivotTo(self.button.CFrame)
            visual.Name = "visual"
            visual.Parent = self.button
            visual.gui.title.Text = self.humanName
        else
            error("Unrecognized instance in Purchasable: " .. child:GetFullName())
        end
    end

    if not self.button then
        error("Purchasable is missing a button pad: " .. self.name)
    end
    self:restyleButton()
    self.button.visual.gui.subtitle.Text = self.item:getSubtitle()

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
    self:restyleButton()

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

function Purchasable:restyleButton()
    self.button.Parent = if self:purchasable() then workspace else nil

    if self.developerProduct and not self.playerHasDeveloperProduct then
        self.button.visual.gui.price.Text = "R$" .. KDKit.Humanize:money(self.developerProduct.price)
        self.button.visual.gui.price.TextColor3 = Color3.fromRGB(56, 208, 54)

        self.button.visual.neon.Material = Enum.Material.Neon
        self.button.visual.neon.Color = Color3.fromRGB(171, 122, 52)

        self.button.visual.neon.light.PointLight.Color = Color3.fromRGB(171, 122, 52)
        self.button.visual.neon.light.PointLight.Brightness = 1

        self.button.visual.neon.beam.Beam.Color = ColorSequence.new(Color3.fromRGB(171, 122, 52))
        self.button.visual.neon.beam.Beam.Brightness = 1
    else
        if self.price == 0 then
            self.button.visual.gui.price.Text = "FREE"
            self.button.visual.gui.price.TextColor3 = Color3.fromRGB(55, 145, 205)
        else
            self.button.visual.gui.price.TextColor3 = Color3.fromRGB(255, 255, 255)
            self.button.visual.gui.price.Text = "$" .. KDKit.Humanize:money(self.price)
        end

        if self.affordable then
            self.button.visual.neon.Material = Enum.Material.Neon
            self.button.visual.neon.Color = Color3.fromRGB(147, 171, 142)

            self.button.visual.neon.light.PointLight.Color = Color3.fromRGB(156, 255, 138)
            self.button.visual.neon.light.PointLight.Brightness = 1

            self.button.visual.neon.beam.Beam.Color = ColorSequence.new(Color3.fromRGB(199, 255, 156))
            self.button.visual.neon.beam.Beam.Brightness = 1
        else
            self.button.visual.neon.Material = Enum.Material.Glass
            self.button.visual.neon.Color = Color3.fromRGB(70, 81, 67)

            self.button.visual.neon.beam.Beam.Brightness = 0
            self.button.visual.neon.light.PointLight.Brightness = 0
        end
    end
end

function Purchasable:setAffordable(isAffordable)
    if self.affordable == isAffordable then
        return
    end

    self.affordable = isAffordable
    self:restyleButton()
end

function Purchasable:setPlayerHasDeveloperProduct(playerHasDeveloperProduct)
    if self.playerHasDeveloperProduct == playerHasDeveloperProduct then
        return
    end
    self.playerHasDeveloperProduct = playerHasDeveloperProduct

    self:restyleButton()
end

function Purchasable:reset(newPlayer)
    self:unPurchase()
    self:setAffordable(self.price <= 0)
    if newPlayer then
        self:setPlayerHasDeveloperProduct(false)
    end
end

return Purchasable
