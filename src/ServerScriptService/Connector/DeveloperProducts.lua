local MarketPlaceService = game:GetService("MarketplaceService")

local KDKit = require(game:GetService("ReplicatedFirst"):WaitForChild("KDKit"))
local DeveloperProducts = require(game:GetService("ServerScriptService"):WaitForChild("DeveloperProducts"))
local Players = require(game:GetService("ServerScriptService"):WaitForChild("Players"))

MarketPlaceService.ProcessReceipt = function(receipt: DeveloperProducts.Receipt): Enum.ProductPurchaseDecision
    local player = Players:get(receipt.PlayerId)

    if not player then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    return KDKit.Utils:ensure(function(failed, traceback)
        if failed then
            (KDKit.API.log / "error"):dpePOST(player.instance, {
                title = "Unhandled Exception",
                description = traceback,
                fields = {
                    during = "MarketPlaceService.ProcessReceipt",
                    receipt = receipt,
                },
            })
        end
    end, DeveloperProducts.processReceipt, DeveloperProducts, player, receipt)
end

return Players
