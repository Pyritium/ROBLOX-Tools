local RunService = game:GetService("RunService");

local HitboxManager = require(script.HitboxManager);
local Signal = require(script.PureSignal);

local Hitbox = {};
Hitbox.__index = Hitbox;

local BASE_HITBOX_SIZE = Vector3.new(3,3,3);
type Anchor = (CFrame | BasePart);
type SignalType = typeof(setmetatable({}, Signal));
type HitboxMetadata = {
    Anchor: Anchor,
    Offset: CFrame,
    Size: Vector3,
    ExcludeTable: {any}?,
    Visible: boolean;

    Touched: SignalType;

    _Heartbeat: RBXScriptConnection;
    _RunTime: number,
    _RunTimeMax: number,
};

export type HitboxInstance = typeof(setmetatable({} :: HitboxMetadata, Hitbox));

-- TODO: Construct like so:
-- Hitbox.new(hitboxCastMax: number? (default 1))
function Hitbox.new(anchor: Anchor?, offset: CFrame?, size: Vector3?)
    local self = {
        Anchor = anchor or CFrame.new(),
        Offset = offset or CFrame.new(),
		Size = size or BASE_HITBOX_SIZE,
        ExcludeTable = {};
    } :: HitboxMetadata;

    self.Touched = Signal.new();
    self.HumanoidTouched = Signal.new();

    return setmetatable(self, Hitbox);
end

local function IsContained(exclude, inst)
    for _, excludeInstance in pairs(exclude) do
        if inst == excludeInstance or inst:IsDescendantOf(excludeInstance) then
            return true;
        end
    end
    return false;
end

local function EvaluateHumanoid(part)
    local char = part:FindFirstAncestorOfClass("Model");
    local humanoid = char and char:FindFirstChildOfClass("Humanoid");
    return humanoid and char;
end

local CollectionService = game:GetService("CollectionService");
function Hitbox:_Update(dT: number)
    local baseCFrame = typeof(self.Anchor) == "Instance" and self.Anchor.CFrame or self.Anchor :: CFrame;
    local finalCFrame = baseCFrame * self.Offset :: CFrame;

    if (self.Visible) then
        local Part = Instance.new("Part", workspace);
        Part.Anchored = true;
        Part.CFrame = finalCFrame;
        Part.Size = self.Size;
        Part.Transparency = .5;
        Part.CanCollide = false;
        Part.Color = Color3.new(1, 0.309804, 0.321569);
        Part:AddTag("HitboxExclude");
        game:GetService("Debris"):AddItem(Part,.1);
    end

    local overlapParameters = OverlapParams.new();
    overlapParameters.FilterDescendantsInstances = {self.ExcludeTable, CollectionService:GetTagged("HitboxExclude")};

    local Hitbox = workspace:GetPartBoundsInBox(finalCFrame, self.Size, overlapParameters);

    for _,v in pairs(Hitbox) do
        if not(IsContained(self.ExcludeTable, v)) then
            self.Touched:Fire(v, finalCFrame);
            local char = EvaluateHumanoid(v);
            if (char) then
                self.HumanoidTouched:Fire(char, finalCFrame);
            end
        end
    end

    self._RunTime += dT;
end


-- global scope
function Hitbox:Exclude(exclude, removeTime: number?)
    table.insert(self.ExcludeTable, exclude);

    if (removeTime) then
        task.spawn(function()
            task.wait(removeTime);
            self:RemoveFromExclude(exclude);
        end)
    end
end

function Hitbox:RemoveFromExclude(removeExclude)
    table.remove(self.ExcludeTable, table.find(self.ExcludeTable, removeExclude));
end

function Hitbox:Cast(runTime: number?, visible: boolean?, anchor: Anchor?, offset: CFrame?, size: Vector3)
    self._RunTime = 0;
    self._RunTimeMax = runTime or self._RunTimeMax;
    self.Visible = visible or self.Visible;
    self.Anchor = anchor or self.Anchor;
    self.Offset = offset or self.Offset;
    self.Size = size or self.Size;

    HitboxManager:Add(self);
end

function Hitbox:Active()
    return HitboxManager:GetIndex(self);
end

function Hitbox:Stop()
    HitboxManager:Remove(self);
end

function Hitbox:Destroy()
    HitboxManager:Remove(self);
    self = nil;
end




return Hitbox;
