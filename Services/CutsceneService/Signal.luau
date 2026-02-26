local module = {}
module.__index = module;

function module.new()
	local self = setmetatable({}, module);

	self.BindableEvent = Instance.new("BindableEvent");

	return self;
end

function module:Connect(Handler)
	self.BindableEvent.Event:Connect(Handler);
end

function module:Fire(...)
	self.BindableEvent:Fire(...);
end


return module;
