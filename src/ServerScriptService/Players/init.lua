local KDKit = require(game.ReplicatedFirst:WaitForChild("KDKit"))

local Players = {}
Players.list = {}
Players.Player = require(script:WaitForChild("Player"))
Players.folder = game:GetService("Players")
Players.rt = {}
KDKit.ReplicatedTable.players = Players.rt

function Players:getUserId(something: any): number | nil
    if type(something) == "number" then
        return something
    elseif type(something) ~= "nil" then
        local function tryAttr(attr)
            return self:getUserId(KDKit.Utils:getattr(something, attr))
        end

        return tryAttr("UserId") or tryAttr("instance") or tryAttr("user_id") or tryAttr("player_id") or tryAttr("id")
    end
end

function Players:get(something: any): "Class.Player"?
    return self.list[self:getUserId(something)]
end

function Players:joined(playerInstance: Player): nil
    local id = self:getUserId(playerInstance)

    if self.list[id] then
        playerInstance:Kick(
            "Somehow you managed to join the game before leaving it. Please submit a bug report in the Khronos Development Discord server."
        )
        error(("Player <%s> somehow joined before leaving..."):format(KDKit.Utils:repr(id)))
    end

    self.list[id] = self.Player.new(playerInstance)
    self.list[id]:initialize()
end

function Players:left(playerInstance: Player): nil
    local id = self:getUserId(playerInstance)
    local player = self.list[id]
    self.list[id] = nil

    if not player then
        -- indicative that Player:joined() errored.
        -- but just in case...
        (KDKit.API.log / "debug"):dpePOST(playerInstance, {
            title = "Player left before joining.",
            description = "This likely indicates that Players:joined() errored. Make sure there was an error log for that!",
            fields = {
                player_id = playerInstance.UserId,
            },
        })
        return
    end

    player:left()
end

function Players:rebirth(playerInstance: Player): boolean
    local player = self:get(playerInstance)
    if not player or not player:isValid() then
        error("Invalid player.")
    end

    return player:rebirth()
end

return Players
