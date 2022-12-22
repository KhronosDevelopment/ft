local MarketPlaceService = game:GetService("MarketplaceService")

local KDKit = require(game:GetService("ReplicatedFirst"):WaitForChild("KDKit"))
local Configuration = require(game:GetService("ServerStorage"):WaitForChild("DeveloperProducts.Configuration"))

local DeveloperProducts = {}

function DeveloperProducts:get(nameOrId: string | number): Configuration.Config?
    local product = Configuration[nameOrId]
    if not product then
        warn("tried to lookup invalid dev product: " .. nameOrId)
    end
    return product
end

function DeveloperProducts:playerPurchased(player: "Class.Player", name: string): boolean
    self:get(name) -- for the warning, potentially
    return not not player.remote.player["has_dev_product_" .. name]
end

function DeveloperProducts:prompt(player: "Class.Player", name: string)
    local cfg = self:get(name)

    if self:playerPurchased(player, name) then
        return false
    end

    if not cfg then
        return false
    end

    MarketPlaceService:PromptProductPurchase(player.instance, cfg.id)

    return true
end

export type Receipt = {
    PlayerId: number,
    PlaceIdWherePurchased: number,
    PurchaseId: string,
    ProductId: number,
    CurrencyType: Enum.CurrencyType,
    CurrencySpent: number,
}
function DeveloperProducts:processReceipt(player: "Class.Player", receipt: Receipt): Enum.ProductPurchaseDecision
    local product = self:get(receipt.ProductId)
    if not product then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    if self:playerPurchased(player, product.name) then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local remotePlayer = (KDKit.API.game / "purchase_dev_product"):pePOST(player.instance, {
        name = product.name,
        external_id = receipt.PurchaseId,
        product_id = product.id,
        currency_spent = receipt.CurrencySpent,
        currency_type = receipt.CurrencyType.Name,
        raw_receipt = receipt,
    })

    player.remote.player = remotePlayer
    task.defer(player.awardDeveloperProduct, player, product, true)
    return Enum.ProductPurchaseDecision.PurchaseGranted
end

return DeveloperProducts
