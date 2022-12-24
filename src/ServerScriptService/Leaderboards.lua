local KDKit = require(game:GetService("ReplicatedFirst"):WaitForChild("KDKit"))

local Leaderboards = {}

type LeaderStat = {
    name: string,
    display_name: string,
    rebirths: number,
}

function Leaderboards:apply(data: { LeaderStat }, gui: SurfaceGui)
    for i = 1, 10 do
        local instance = gui:FindFirstChild(tostring(i))
            or error(("leaderboard %s is missing row %d"):format(gui:GetFullName(), i))
        local row: LeaderStat? = data[i]

        if row then
            instance.displayName.Text = row.display_name
            instance.name.Text = row.name
            instance.value.Text = KDKit.Humanize:money(row.rebirths, true)
            instance.Visible = true
        else
            instance.Visible = false
        end
    end
end

function Leaderboards:waitForGuis(): { SurfaceGui }
    local guis: { SurfaceGui } = {}

    while true do
        for _, plot in workspace:WaitForChild("PLOTS"):GetChildren() do
            if plot:IsA("Model") and plot:FindFirstChild("LEADERBOARD") then
                table.insert(guis, plot.LEADERBOARD.gui)
            end
        end

        if #guis == 6 then
            return guis
        else
            table.clear(guis)
            task.wait(1)
        end
    end
end

function Leaderboards:update()
    local guis = self:waitForGuis()
    local leaderStats: { LeaderStat } = (KDKit.API.game / "leaderboards"):eGET()

    for _, gui in guis do
        self:apply(leaderStats, gui)
    end
end

return Leaderboards
