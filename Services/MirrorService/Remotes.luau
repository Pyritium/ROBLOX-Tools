local Net = require(script.Parent.Net);
local Signal = require(script.Parent.Signal);

local Remotes = {
    ["InvokeClient"] = Net.RemoteEvent("InvokeClient");
};

local connCache = {};

local function SetupConnectionAndCleanCache(newSig, remoteName, reqPlrName)
    local connName = reqPlrName..remoteName;
    local existing = connCache[connName] :: typeof(Signal);
    if (existing) then
        existing:Destroy();
    end

    connCache[connName] = newSig;
end

function Remotes:ListenToRemoteWithPlayer(remote, method, reqPlr)
    local newSig = Signal.new();
    local conn;

    SetupConnectionAndCleanCache(newSig, remote.Name, reqPlr.Name);

    conn = remote[method]:Connect(function(plr, ...)
        if (reqPlr == plr) then
            newSig:Fire(...);
        end
    end)

    newSig.Destroying.Event:Connect(function()
        conn:Disconnect();
    end)

    return newSig;
end

local InvokeClient = Remotes.InvokeClient;
function Remotes:ClientExecute(plr: Player, ...)
    if (game:GetService("RunService"):IsServer()) then
        InvokeClient:FireClient(plr, ...);
    end
end


return Remotes;
