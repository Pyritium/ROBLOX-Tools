local Dispatcher = {};
Dispatcher.__index = Dispatcher;

function Dispatcher.new()
    local self = setmetatable({}, Dispatcher);
    self._Listeners = {};
    return self;
end

function Dispatcher:Connect(key, callback)
	self._Listeners[key] = callback;
end

function Dispatcher:Disconnect(key)
	self._Listeners[key] = nil;
end

function Dispatcher:Fire(key, ...)
	local callback = self._Listeners[key];
	if callback then
		callback(...);
	end
end



return Dispatcher;
