local KDKit = require(game:GetService("ReplicatedFirst"):WaitForChild("KDKit"))

export type Config = {
    name: string,
    id: number,
    price: number,
    purchases: string?,
    instance: Instance,
}

local DeveloperProductsConfiguration = {} :: { [string | number]: Config }

KDKit.Preload:ensureDescendants(script)
for _, child in script:GetChildren() do
    local cfg: Config = {
        name = child.Name,
        id = child:GetAttribute("id"),
        price = child:GetAttribute("price"),
        purchases = child:GetAttribute("purchases"),
        instance = child,
    }

    if DeveloperProductsConfiguration[cfg.name] then
        error("duplicate dev product config name: " .. cfg.name)
    end

    if DeveloperProductsConfiguration[cfg.id] then
        error("duplicate dev product config id: " .. cfg.id)
    end

    DeveloperProductsConfiguration[cfg.name] = cfg
    DeveloperProductsConfiguration[cfg.id] = cfg
end

return DeveloperProductsConfiguration
