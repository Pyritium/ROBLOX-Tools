local module = {
	index = {};
}
module.__index = module;

--[[ Each point should be structured like this:
Keyframe = {
	CFrame = CFrame,
	Time = number,
	EasingStyle = Enum.EasingStyle,
	EasingDirection = Enum.EasingDirection,
	Actor = {
		Actor = Model, (Focus Model [camera will pan to the spot while focusing on the character?])
		Keyframe = CFrame, (Transition point for character to move to)
		Animation = Animation, (Animation to be played)
		Focus = boolean, (To focus on the actor while camera moves)
		Time = number (Time for transition & animation speed?)
	}
}
]]--


function module.new(CoordinatePoint : CFrame, Time : number, EasingStyle : string, EasingDirection : string, Model : Model, ActorCoordinatePoint : CFrame, AnimationId : string, FocusOnActor : boolean, ActorTime :number)
	if (CoordinatePoint) and (Time) then

		local self = {};
		setmetatable(self, module);

		self.CFrame = CoordinatePoint;
		self.Time = Time;
		self.EasingStyle = EasingStyle;
		self.EasingDirection = EasingDirection;

		-- Unsupported:
		self.Actor = {
			Actor = Model or nil,
			Keyframe = ActorCoordinatePoint or CFrame.new(),
			AnimationId = AnimationId or "rbxassetid://0",
			Focus = FocusOnActor or false,
			Time = ActorTime or 0;
		}
		table.insert(module.index, self);

		return self;
	else
		error("Missing definition(s): CFrame, Time, EasingStyle, EasingDirection")
	end
end


return module
