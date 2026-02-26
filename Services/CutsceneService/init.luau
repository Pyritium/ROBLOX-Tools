local module = {}
module.__index = module;

local Signal = require(script.Signal);

local function DeriveTime(Points)
	local Time = 0;
	for _,Keyframe in pairs(Points) do
		Time += Keyframe.Time;
	end
	return Time;
end

local function VerifyIndexExists(Data, Index)
	for i,v in pairs(Data) do
		if (Index == i) then
			return true;
		end
	end

	return false;
end

local function VerifyValueExists(Data, Value)
	for i,v in pairs(Data) do
		if (Value == v) then
			return true;
		end
	end

	return false;
end

function module.new(Keyframes)
	local self = {};
	setmetatable(self, module);
	self.Points = {};
	self.Players = {};
	self.EasingStyle = "Linear";
	self.EasingDirection = "InOut";
	self.Playing = false;
	self.Finished = false;

	--Connections/Signals
	self.FinishedSignal = Signal.new();

	if (Keyframes) then
		for _,v in pairs(Keyframes) do
			table.insert(self.Points, v);
		end
	end
	return self;
end

function module:AddKeyframe(Keyframe)
	if (VerifyValueExists(require(script.Keyframe).index, Keyframe)) then
		table.insert(self, Keyframe);
	else
		error("Invalid keyframe instance: Make sure you're using the keyframe constructor (and require the keyframe constructor instance inside this module!)")
	end
end

local function CompareTables(Table1, Table2)
	if (#Table1 ~= #Table2) then
		return false;
	end

	local function InstanceNameSort(a, b)
		return a.Name < b.Name;
	end

	table.sort(Table1, InstanceNameSort);
	table.sort(Table2, InstanceNameSort);

	for i, v in ipairs(Table1) do
		if (v ~= Table2[i]) then
			return false;
		end
	end

	return true;
end

local RunService = game:GetService("RunService");
function module:Play()
	task.spawn(function()
		local CompletedPlayers = {};
		if not(self.Playing) then
			self.Playing = true;
			local Timeout = DeriveTime(self.Points)+1;
			print("Setting up cutscene");
			for _,Player in pairs(self.Players) do
				local Connection;
				Connection = task.spawn(function()
					local CutsceneLocal = Player.PlayerGui:FindFirstChild("CutsceneLocal") or script.CutsceneLocal:Clone();
					CutsceneLocal.Parent = Player.PlayerGui;
					CutsceneLocal.Enabled = true;
					CutsceneLocal:SetAttribute("Path", tostring(script:GetFullName()));

					local Return;
					task.spawn(function()
						local Time = 0;
						local TimeConnection;
						TimeConnection = RunService.Heartbeat:Connect(function(dT)
							if (Time >= Timeout) then
								TimeConnection:Disconnect();
								task.wait();
								if not(Return) then
									print("Timed out, FINISHED");
									table.insert(CompletedPlayers, Player);
									if (CutsceneLocal) then
										CutsceneLocal.Enabled = false;
									end
								end
							end
							Time += dT;
						end)
					end)
					Return = script.RemoteFunction:InvokeClient(Player, self.Points);
					Return = true;
					print("FINISHED");
					table.insert(CompletedPlayers, Player);
	  			end)
			end
			repeat task.wait() until (CompareTables(self.Players, CompletedPlayers));
			print("Cutscene finished");
			--print("Completed Cutscene");
			self.Playing = false;
			self.Finished = true;
			self.FinishedSignal:Fire();
		end
	end)
end

function module:Stop()
	self.Playing = false;
	self.Finished = true;

	for _,Player in pairs(self.Players) do
		Player.PlayerGui.CutsceneLocal:Destroy();
	end
end

return module
