local KDKit = require(game:GetService("ReplicatedFirst"):WaitForChild("KDKit"))
local app = require(script.Parent)
local page = app:getPage("rebirth")

page.buttons.close = KDKit.GUI.Button
    .new(page.instance.window.close.button, function()
        app:goBack("BUTTON_PRESS")
    end)
    :bind("X")
    :bind(Enum.KeyCode.ButtonB)

page.buttons.submit = KDKit.GUI.Button
    .new(page.instance.window.inner.submit.button, function()
        if KDKit.Remotes.rebirth() then
            app:goBack("BUTTON_PRESS")
        end
    end)
    :bind(Enum.KeyCode.ButtonX)

local function updateSubmitEnabled()
    if page.opened and (app.common.LRT.rebirthCost() or 1000000) <= (app.common.LRT.stats.money() or 0) then
        page.buttons.submit:enable()
    else
        page.buttons.submit:disable()
    end
end

app.common.LRT.rebirthCost(updateSubmitEnabled)
app.common.LRT.stats.money(updateSubmitEnabled)

app.common.LRT.rebirthCost(function(value)
    page.instance.window.inner.cost.Text = "$" .. KDKit.Humanize:money(value or 0, true)
end)

app.common.LRT.stats.rebirths(function(value)
    value = value or 0

    local bonus = 2 ^ value
    page.instance.window.inner.label.Text = (
        "Rebirthing allows you to <b><i>restart the tycoon</i></b> with a <b><i>2x cash bonus</i></b>. You can rebirth multiple times to become a trillionaire!"
        .. "\n\n"
        .. "<b><i>Current Multiplier: %dx</i></b>"
    ):format(KDKit.Humanize:money(bonus, true))
end)

function page:afterOpened()
    updateSubmitEnabled()
end

return page
