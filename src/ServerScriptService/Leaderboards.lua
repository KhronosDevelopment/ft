local KDKit = require(game:GetService("ReplicatedFirst"):WaitForChild("KDKit"))

local Leaderboards = { folder = workspace:WaitForChild("LEADERBOARDS") }
KDKit.Preload:ensureDescendants(Leaderboards.folder)

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

function Leaderboards:update()
    local leaderStats: { LeaderStat } = (KDKit.API.game / "leaderboards"):eGET()

    for _, instance in self.folder:GetChildren() do
        self:apply(leaderStats, instance.gui)
    end
end

return Leaderboards
