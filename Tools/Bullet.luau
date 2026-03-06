local Debris = game:GetService("Debris")
local Bullet = {};
Bullet.__index = Bullet;

type BulletType = {
    Speed: number,
    GravityCoefficient: number,
    MaxSimulationTime: number,
    Debug: boolean,
};

type Segment = {
    Start: Vector3,
    End: Vector3,
    _Part: BasePart
}


local DEBUG_PART = Instance.new("Part");
DEBUG_PART.Color = Color3.new(1,0,0);
DEBUG_PART.Transparency = .5;
DEBUG_PART.Material = Enum.Material.Neon;
DEBUG_PART.Anchored = true;
DEBUG_PART.CanCollide = false;
DEBUG_PART.CastShadow = false;
DEBUG_PART:AddTag("Ignore");

local CollectionService = game:GetService("CollectionService") :: CollectionService;


local function DrawDebugPart(p0, p1, direction)
    local part = DEBUG_PART:Clone();
    local dist = direction.Magnitude;
    part.CFrame = CFrame.new(p1, p0)*CFrame.new(0,0,-dist/2);
    part.Size = Vector3.new(1,1,dist);
    return part;
end


local function projectileMotionEquation(g, v, initialPosition, t)
	return 0.5 * g * t ^ 2 + v * t + initialPosition;
end

local function raycastAlongQuadraticPath(self, initialPosition, vUnit)
    local maxTime = self.MaxSimulationTime;
    local g = Vector3.new(0,-self.GravityCoefficient,0);
    local vMag = self.Speed;
    local v = vUnit*vMag;
	local segments = 10*math.round(maxTime*3);
	local timeGapIncrements = maxTime/segments
	local currentTime = 0;
    local segs = {} :: {Segment};
	for i=1, segments do
        local newSegment = {} :: Segment;
		local point1 = projectileMotionEquation(g,v,initialPosition,currentTime)
		local point2 = projectileMotionEquation(g,v,initialPosition,currentTime+timeGapIncrements)

        newSegment.Start = point1;
        newSegment.End = point2;

		local direction = point2-point1;
		--local rayResult = workspace:Raycast(point1,direction,RaycastParams.new());
        if (self.Debug) then
            local dbgPart = DrawDebugPart(point1, point2, direction);
            newSegment._Part = dbgPart;
        end
		--[[if rayResult then
			return rayResult;
		end]]--
		currentTime += timeGapIncrements;
        table.insert(segs, newSegment);
	end
    return segs;
end

function Bullet.new(speed: number, gravCoeff: number, maxTime)
    local self = {};
    self.Speed = speed or 300;
    self.GravityCoefficient = gravCoeff or 25;
    self.Debug = true;
    self.MaxSimulationTime = maxTime or 3;

    return setmetatable(self, Bullet);
end

local BASE_TRAVEL_STEP = .0003;
function Bullet:Cast(startPos: Vector3, dirUnit: Vector3)
    local segments = raycastAlongQuadraticPath(self, startPos, dirUnit);

    local exp = math.exp(11/self.Speed);
    local step = BASE_TRAVEL_STEP*exp;
    for _,seg in pairs(segments) do task.wait(step);
        if (self.Debug) then
            seg._Part.Parent = workspace;
            Debris:AddItem(seg._Part, 1);
        end
        local point1,point2 = seg.Start, seg.End;
        local direction = point2-point1;

        local rayParams = RaycastParams.new();
        rayParams.FilterType = Enum.RaycastFilterType.Exclude;
        rayParams.FilterDescendantsInstances = {CollectionService:GetTagged("Ignore")};

        local rayResult = workspace:Raycast(point1,direction,rayParams);
        if rayResult then
            return;
        end

    end
end






return Bullet;
