local LocalizationService = game:GetService("LocalizationService")

local KDKit = require(game.ReplicatedFirst:WaitForChild("KDKit"))

local Players = KDKit.LazyRequire(script.Parent)
local Player = KDKit.Class.new("Player")
Player.static.Character = require(script:WaitForChild("Character"))
Player.static.Stats = require(script:WaitForChild("Stats"))
Player.static.Plot = require(script:WaitForChild("Plot"))

Player.static.STATES = {
    JOINED = 1,
    INITIALIZING = 2,
    LOADING_PLOT = 3,
    PLAYING = 4,
    LEAVING = 5,
    LEFT = 6,
}

function Player:__init(instance: Player)
    self.instance = instance

    self.id = Players:getUserId(instance)
    self.state = Player.STATES.JOINED
    self.kicked = false

    self.maid = KDKit.Maid.new()
    self.mutex = self.maid:give(KDKit.Mutex.new())
    self.character = self.maid:give(Player.Character.new(self))
    self.stats = self.maid:give(Player.Stats.new(self))
    self.plot = self.maid:give(Player.Plot.new(self))

    self.rt = {
        stats = self.stats.rt,
    }
    Players.rt[self.id] = self.rt

    self.remote = {
        user = nil,
        player = nil,
        session = nil,
    }
end

function Player:initialize(): nil
    self.mutex:lock(function(unlock)
        if self.state >= Player.STATES.INITIALIZING then
            error("You may only initialize once.")
        end
        self.state = Player.STATES.INITIALIZING

        local correct_country_code, country_code =
            pcall(LocalizationService.GetCountryRegionForPlayerAsync, LocalizationService, self.instance)
        local user_success, user_response = (KDKit.API.root / "users"):PATCH({
            id = self.id,
            name = self.instance.Name,
            display_name = self.instance.DisplayName,
            country_code = if correct_country_code then country_code else nil,
        })

        local player_success, player_response
        if not user_success then
            player_success, player_response = false, "User load failed. Cannot load player without loading user first."
        else
            player_success, player_response = (KDKit.API.game / "players"):pGET(self.instance)
        end

        if user_success then
            self.remote.user = user_response.user
            self.remote.session = user_response.session

            self.rt.admin = self.remote.user.admin
        end

        if player_success then
            self.remote.player = player_response
        end

        if user_success and player_success then
            self.plot:load(self.remote.player.data, self.remote.player.rebirths)
            self.state = Player.STATES.PLAYING
            KDKit.Remotes.loaded(self.instance)
        else
            if not user_success then
                (KDKit.API.log / "error"):dpePOST(
                    self.instance,
                    { title = "User load failed.", description = user_response }
                )
                self:kick("Failed to load user.")
            else
                (KDKit.API.log / "error"):dpePOST(
                    self.instance,
                    { title = "Player load failed.", description = player_success }
                )
                self:kick("Failed to load player.")
            end
        end
    end)
end

function Player:isValid(): boolean
    return not self.kicked and self.state < Player.STATES.LEAVING
end

function Player:isPlaying(): boolean
    return self:isValid() and self.state == Player.STATES.PLAYING
end

function Player:save()
    if not self.plot.loaded then
        return
    end

    (KDKit.API.game / "players" / "save"):dpePOST(
        self.instance,
        { data = self.plot.data, rebirths = self.plot.rebirths }
    )
end

function Player:left(): nil
    self.mutex:lock(function(unlock)
        if self.state >= Player.STATES.LEAVING then
            error("You may only leave the game once.")
        end
        self.state = Player.STATES.LEAVING
        self:save();
        (KDKit.API.root / "users" / "leave"):dpePOST(self.instance)
        self.maid:clean()
        self.state = Player.STATES.LEFT
    end)
end

function Player:kick(reason: any): nil
    self.kicked = reason or "No reason given."
    self.instance:Kick(self.kicked)
end

function Player:getSpawnPoint(): nil | CFrame | Vector3
    return self.plot:getSpawnPoint()
end

return Player
