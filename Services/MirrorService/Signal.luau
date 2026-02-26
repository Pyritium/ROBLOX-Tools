-- For asynchronous calling so we yield loops, true lua listening functionality!
local module = {};
module.__index = module;

function module.new()
	local self = setmetatable({}, module);
	self._Listeners = {};
	-- For wait();
	self._BindableEvent = Instance.new("BindableEvent");

	return self;
end

function module:Connect(callback)
	table.insert(self._Listeners, callback);
	return {
		Disconnect = function()
			table.remove(self._Listeners, table.find(self._Listeners,callback));
		end
	};
end

function module:Fire(...)
	for _,callback in ipairs(self._Listeners) do
		callback(...);
	end

	self._BindableEvent:Fire(...);
end

function module:Wait()
	self._BindableEvent.Event:Wait();
end

function module:Destroy()
	self._Listeners = nil;
	self._BindableEvent:Destroy();
end

return module
