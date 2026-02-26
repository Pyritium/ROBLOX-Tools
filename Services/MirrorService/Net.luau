local Net = {};

local RemotesFolder = script:FindFirstChild("Folder") or Instance.new("Folder", script);

local function GetRemote(Name: string, remoteType)
    if not(RemotesFolder:FindFirstChild(Name)) then
        local RemoteEvent = Instance.new(remoteType, RemotesFolder);
        RemoteEvent.Name = Name;
    end

    return RemotesFolder:FindFirstChild(Name);
end

function Net.RemoteEvent(Name: string)
    return GetRemote(Name, "RemoteEvent");
end

function Net.RemoteFunction(Name: string)
    return GetRemote(Name, "RemoteFunction");
end

function Net.FireClient(Name: string, Player: Player, ...)
    GetRemote(Name):FireClient(Player, ...);
end

return Net;
