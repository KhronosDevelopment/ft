local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")

local KDKit = require(game.ReplicatedFirst:WaitForChild("KDKit"))
require = KDKit.LazyRequire

local Player = require(script.Parent)
local Character = KDKit.Class.new("Player.Character")
Character.static.folder = Instance.new("Folder", workspace)
Character.static.folder.Name = "CHARACTERS"

function Character:__init(player)
    self.player = player

    self.maid = KDKit.Maid.new()

    self.instanceMaid = nil
    self.maid:give(self.player.instance.CharacterAdded:Connect(function(character: Model)
        if self.instanceMaid then
            self.maid:clean(self.instanceMaid)
        end
        self.instanceMaid = self.maid:give(KDKit.Maid.new())

        self.instance = character

        self.instanceMaid:give(character.AncestryChanged:Connect(function()
            task.defer(function()
                character.Parent = Character.folder
            end)
        end))

        local childAddedConnection
        local function childAdded(child: Instance)
            if child:IsA("Humanoid") then
                local humanoid: Humanoid = child
                self.instanceMaid:clean(childAddedConnection)
                self.instanceMaid:give(humanoid.Died:Connect(function()
                    self.instanceMaid:clean()
                    self:onDied(character, humanoid)
                end))
            end

            if child:IsA("BasePart") then
                PhysicsService:SetPartCollisionGroup(child, "characters")
            end
        end
        childAddedConnection = self.instanceMaid:give(character.ChildAdded:Connect(childAdded))
        for _, child in character:GetChildren() do
            task.defer(childAdded, child)
        end

        local heartbeatConnection
        heartbeatConnection = self.instanceMaid:give(RunService.Heartbeat:Connect(function()
            if not self:isValid() then
                return
            end
            self.instanceMaid:clean(heartbeatConnection)

            local spawnPoint = self.player:getSpawnPoint()
            if spawnPoint then
                self:teleport(spawnPoint)
            end
        end))
    end))
end

function Character:isValid(): boolean
    -- must have an instance
    local instance: Model = self.instance
    if not instance then
        return false
    end

    -- must have a humanoid
    local humanoid: Humanoid = instance:FindFirstChild("Humanoid")
    if not humanoid then
        return false
    end

    -- must have a valid RootPart/PrimaryPart
    if not humanoid.RootPart or humanoid.RootPart.Parent ~= instance then
        return false
    end

    -- must be alive
    if humanoid.Health <= 0 then
        return false
    end

    -- for R6 rigs, must have a Left Leg (which is used to calculate the height)
    if humanoid.RigType == Enum.HumanoidRigType.R6 and not instance:FindFirstChild("Left Leg") then
        return false
    end

    return true
end

function Character:onDied(character: Model, humanoid: Humanoid): nil
    -- Feel free to overwrite me!
    self:spawn()
end

function Character:getRootPartDistanceFromGround(): number
    if not self:isValid() then
        return 0
    end

    local humanoid: Humanoid = self.instance.Humanoid
    local rigType = humanoid.RigType

    if rigType == Enum.HumanoidRigType.R15 then
        return humanoid.HipHeight + humanoid.RootPart.Size.Y / 2
    else
        return self.instance["Left Leg"].Size.Y + humanoid.HipHeight + humanoid.RootPart.Size.Y / 2
    end
end

function Character:getPrimaryPartDistanceFromGround(): number
    if not self:isValid() then
        return 0
    end

    return self:getRootPartDistanceFromGround()
        + self.instance.PrimaryPart.CFrame:ToObjectSpace(self.instance.Humanoid.RootPart.CFrame).Y
end

function Character:teleport(to: CFrame | Vector3, fromFoot: boolean?): nil
    if fromFoot == nil then
        fromFoot = true
    end

    if not self:isValid() then
        return
    end

    if typeof(to) == "Vector3" then
        local ppCFrame = self.instance.PrimaryPart.CFrame
        local orientation = ppCFrame - ppCFrame.p
        to = orientation + to
    end

    if fromFoot then
        to *= CFrame.new(0, self:getPrimaryPartDistanceFromGround(), 0)
    end

    self.instance:PivotTo(to)
end

function Character:spawn()
    self:despawn()
    self.player.instance:LoadCharacter()
end

function Character:despawn()
    if self.instanceMaid then
        self.instanceMaid:clean()
    end
    if self.instance then
        self.instance:Destroy()
        self.instance = nil
    end
end

function Character:destroy()
    self.maid:clean()
end

return Character
