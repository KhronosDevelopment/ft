local KDKit = require(game:GetService("ReplicatedFirst"):WaitForChild("KDKit"))
local app = require(script.Parent)
local page = app:getPage("home")

page.buttons.rebirth = KDKit.GUI.Button.new(page.instance.container.rebirth.button, function()
    app:goTo("rebirth", "BUTTON_PRESS")
end)

local firstPositiveDeltaAt = math.huge
local positiveDeltasInTheLastMinute = {}
local function updateMoneyPerSecond()
    local dollarsEarnedInTheLastMinute = KDKit.Utils:sum(positiveDeltasInTheLastMinute)
    local incomePerSecond = dollarsEarnedInTheLastMinute / math.clamp(os.clock() - firstPositiveDeltaAt, 1, 60)

    page.instance.container.moneyPerSecond.Text = "$" .. KDKit.Humanize:money(incomePerSecond) .. "/s"
    page.instance.container.moneyPerSecondShadow.Text = page.instance.container.moneyPerSecond.Text
end
updateMoneyPerSecond()

local lastValue = 0
app.common.LRT.stats.money(function(value)
    value = value or 0
    local delta = value - lastValue
    lastValue = value

    if delta > 0 and lastValue ~= 0 then
        firstPositiveDeltaAt = math.min(firstPositiveDeltaAt, os.clock())
        table.insert(positiveDeltasInTheLastMinute, delta)
        updateMoneyPerSecond()
        task.delay(60, function()
            table.remove(positiveDeltasInTheLastMinute, 1)
            updateMoneyPerSecond()
        end)
    end

    page.instance.container.money.Text = "$" .. KDKit.Humanize:money(value, true)
    page.instance.container.moneyShadow.Text = page.instance.container.money.Text
end)

return page
