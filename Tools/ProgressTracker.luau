local Signal = require(script.Parent.Signal);
local RunService = game:GetService("RunService");

local ProgressTracker = {}
ProgressTracker.__index = ProgressTracker;

export type ProgressTrackerInstance = typeof(setmetatable({}, ProgressTracker));

local ProgressTrackers = {};

RunService.Stepped:Connect(function(_t, dT)
    for _,progressTracker in pairs(ProgressTrackers) do
        if (progressTracker._Recording) then
            progressTracker._Time += dT;
            if (progressTracker._Progress >= progressTracker._ProgressMax) then
                progressTracker._Recording = false;
                progressTracker.Finished:Fire(progressTracker._Time);
            end
        end
    end
end)

local function RecordExistence(new)
    table.insert(ProgressTrackers, new);
end

function ProgressTracker.new(progStart: number?)
    progStart = not(progStart) and 0 or progStart;

    local self = setmetatable({}, ProgressTracker);
    self._ProgressStart = progStart;
    self._Progress = progStart;
    self._ProgressMax = 1;
    self._Time = 0;
    self._Recording = true;

    self.Changed = Signal.new();
    self.Finished = Signal.new();


    function ProgressTracker:GetProgress()
        return self._Progress;
    end

    function ProgressTracker:UpdateProgress(ptg: number, add: boolean)
        assert(type(ptg) == "number", `Failed to set progress because {ptg} is not a number.`);
        local percentage = self._ProgressMax*ptg;
        local newValue = add and self._Progress+percentage or percentage;
        local prevProgress = self._Progress;


        self._Progress = newValue;
        self.Changed:Fire(newValue, prevProgress);

    end
    RecordExistence(self);
    return self;
end



return ProgressTracker;
