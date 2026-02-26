local MirrorService = game.ReplicatedStorage:FindFirstChild("MirrorService", true);
local Remotes = require(MirrorService.Remotes);
local InvokeClient = Remotes.InvokeClient;

InvokeClient.OnClientEvent:Connect(function(method, ...)
    print(method, ...);
    require(MirrorService)[method](...);
end)
