
--[[
----------------------------------------------~//[ MirrorService ]\\~----------------------------------------------
        A Server->Client state handler:

        To create instanced containers that synchronize data both across the server & client simultaneously with minimal calls to
        remotes as possible, so that data can be concurrently synced real time with loops for instance.

        It is **imperative** that this only be worked with ON the server. The goal of MirrorService is to replicate values real time into
        the client as a 'funneling' so you can create object orientated containers that replicate across the server. There are exceptions
        for players who are subscribed w/ security features


        Static Members:
            MirrorService.SecurityCapabilities:   Enum{None,Read,Write);

        Static Functions:
            MirrorService.new(key: (string | number) params?):          MirrorService
                params : {[key] = value...};
                -- We take in n amount of arguments to be indexed as long as they are synonymously allowed within
                   ROBLOX's instance values, they will work (e.g. int, bool, float, etc...)

            MirrorService.FromKey(key: (string | number)):              MirrorService

        Instance Members:

        private: -- DONT TOUCH!!!
            MirrorService._Key:                     Key indexing for name schemes for containers
            MirrorService._ID:                      ID indexing based on insertion
            MirrorService._Data:                    Folder -- Contains all values pertaining to replicated values
            MirrorService._Subscribers:             {[plr: Player]: SecurityCapabilities}
            MirrorService._GetReferences:           References to table copies created via :Get()
        public:
            MirrorService.ValueChanged:             Signal.new<path, value, oldValue>
            MirrorService.Subscribed:               Signal.new<plr>
            MirrorService.Unsubscribed:             Signal.new<plr>
        Instance Methods:
        client:
        server:
            MirrorService:Set(path: {string | number}, value: any)
            MirrorService:SetValues(path: {string | number}, values: {[(string | number)]: any});

            MirrorService:Get(path: {string | number}?, liveReturn: boolean?);
            -- Creates readable data that isn't physical data, if no index is specified data
               itself will be returned with all values pertaining to the instance
            -- liveReturn will return a table and require it be indexed in `_GetReferences`, which will forcibly return an updated version
               of the data so that we don't need to re-reference it if per-say we waited until a value changed in a while true loop.

            MirrorService:Subscribe(plr: Player, SecurityLevel: SecuritiyCapabilities)
            MirrorService:Unsubscribe(plr: Player)
]]--

local MirrorService = {};
MirrorService.__index = MirrorService;


-- Enums
MirrorService.SecurityCapabilities = {
    None = 0,
    Read = 1,
    Write = 2;
}

-- Services
local RunService = game:GetService("RunService");
local Players = game:GetService("Players");

-- Dependencies
local Signal = require(script.Signal);
local Remotes = require(script.Remotes);

-- Other
local ClientHandler = script.MirrorClient;

local Mirrors = {};

local MIRROR_CONTAINER_INSTANCES = script:FindFirstChild("MirrorContainers") or Instance.new("Folder", script);
MIRROR_CONTAINER_INSTANCES.Name = "MirrorContainers";

type SignalType = typeof(setmetatable({}, Signal));

export type MirrorService = {
    _Key: string | number,
    _ID: number,


    ValueChanged: SignalType,
    Subscribed: SignalType,
    Unsubscribed: SignalType,
}

export type InstanceValue = ObjectValue | NumberValue | BoolValue | CFrameValue | StringValue | Vector3Value | BrickColorValue;

local function CapitalizeString(str): string
    str=(string.upper(string.sub(str, 1, 1))..string.sub(str, 2, -1));
    return str;
end

local function InterpretString(str)
    local objTypes = {"Instance","Nil"};
    if (str == "Boolean") then
        return "Bool";
    elseif (table.find(objTypes,str)) then
        return "Object";
    end

    return str;
end

local function NewInstanceValue(idx, value): InstanceValue
    local typeVal = InterpretString(CapitalizeString(typeof(value)));
    local suc,physValue = pcall(function() return Instance.new(`{typeVal}Value`) end);
    if not(suc) then
        physValue = Instance.new("Folder");
    else
        physValue.Value = value;
    end
    physValue.Name = idx;

    return physValue;
end

local function WriteToTableWithPath(tbl, path, value)
    local physical = (typeof(tbl) == "Instance") :: boolean;
    local current = tbl;
    for i = 1, #path - 1 do
        local key = path[i];
        assert(current[key],"Invalid path: " .. key);
        current = current[key];
    end


    local inst = current[path[#path]];
    if (inst) then
        if (physical) then
            local validValue = not(typeof(value) == "table");
            if (validValue) then
                inst.Value = value;
            end
        else
            current[path[#path]] = value;
        end
    else
        if (physical) then
            NewInstanceValue(current[path[#path]], value);
        else
            current[path[#path]] = value;
        end
    end
end

local function ParametersToInstanceValuesInFolder(params, parent) : Folder
    parent = parent or MIRROR_CONTAINER_INSTANCES;
    local physicalFolder = Instance.new("Folder", parent) :: Folder;

    for i,v in pairs(params) do
        if (type(v) == "table") then
            local folder = ParametersToInstanceValuesInFolder(v, physicalFolder);
            folder.Name = i;
        elseif (type(v) ~= "table") then
            local new = NewInstanceValue(i,v);
            new.Parent = physicalFolder;
        end
    end


    return physicalFolder;
end

local function ComposeDictFromInstanceValues(values)
    local dict = {};
    for _,v in pairs(values) do
        if (v:IsA("Folder")) then
            dict[v.Name] = ComposeDictFromInstanceValues(v:GetChildren());
        else
            dict[tonumber(v.Name) or v.Name] = v.Value;
        end

    end
    return dict;
end

local function GetPath(tbl, path, createNew)
    local pathTrue = string.split(path, "/");
    local current = tbl;
    local resultPath = {};

    for i, key in ipairs(pathTrue) do
        --print(current,key, current[key]);
        --assert((createNew) and current[key]~=nil,"Invalid path: " .. key);
        table.insert(resultPath, key);

        if (createNew~=nil) and not(current:FindFirstChild(key)) then
            local value = NewInstanceValue(key, createNew);
            value.Parent = current;
        end

        current = current[key];
    end

    return resultPath, current;
end

local function UpdateReferences(self, path, newValue)
    for _,v in pairs(self._GetReferences) do
        WriteToTableWithPath(v, path, newValue);
    end
end

local function ConnectSignals(self)
    --[[self.ValueChanged:Connect(function(new, old)
        for _,v in pairs(self._Subscribers) do

        end
    end)]]--

    self.Subscribed:Connect(function(plr: Player)
        local key = self._Key;

        --Remotes:ClientExecute(plr, "new", key)
    end)

    self.ValueChanged:Connect(function(path, value, newValue)
        UpdateReferences(self, path, value);
    end)
end

local function ReturnExisting(key: (string | number))
    return MirrorService.FromKey(key);
end

local function ValidateIsServer()
    return RunService:IsRunning() and RunService:IsServer();
end

local function InitializeServer(key, params)
    if (ReturnExisting(key)) then
        return ReturnExisting(key);
    end

    local instanceValues = params and ParametersToInstanceValuesInFolder(params) :: Folder;
    instanceValues.Name = key;
    local self = setmetatable({}, MirrorService);
    self._Key = key;
    self._Data = instanceValues;
    self._Subscribers = {};
    self._ID = #MIRROR_CONTAINER_INSTANCES:GetChildren();

    self._GetReferences = {};


    self.ValueChanged = Signal.new();
    self.Subscribed = Signal.new();
    self.Unsubscribed = Signal.new();

    ConnectSignals(self);

    Mirrors[key] = self;
    return self;
end

-- Rethink this, I mean we only need to return it when we *need* it lol
local function InitializeClient(key)
    local self = setmetatable({}, MirrorService);
    local mirrorFolder = MIRROR_CONTAINER_INSTANCES:FindFirstChild(key);
    self._Data = mirrorFolder;
    -- TODO: Initialize based on values on server already initialized
    return self;
end

function MirrorService.new(key, params)
    local server = RunService:IsServer();

    if (server) then
        return InitializeServer(key, params);
    else
        return InitializeClient(key);
    end
end;


---------------------------~--------------------------- ~[ SERVER ]~ ---------------------------~---------------------------

---------------------------~--------------------------- ~[ FULLSTACK ]~ ---------------------------~---------------------------

function MirrorService:Set(path: {string | number}, value: any)
    assert(ValidateIsServer(), `You can only set values of containers in MirrorService on the server!`);

    local resultingPath,old = GetPath(self._Data, path, value);
    WriteToTableWithPath(self._Data, resultingPath, value);
    self.ValueChanged:Fire(resultingPath, value, old);
end

local function SetValuesInternal(self, values, path, physRef)
    for i,v in pairs(values) do
        local newPath = `{path}/{i}`;
        local resultingPath,val = GetPath(self._Data, newPath, v);
        if (typeof(v) == "table") then
            SetValuesInternal(self, v, `{path}/{i}`, physRef);
        else
            WriteToTableWithPath(self._Data, resultingPath, v);
            self.ValueChanged:Fire(resultingPath, values, val);
            --local val = physRef[i] or NewInstanceValue(i, v);
        end
    end
end

function MirrorService:SetValues(path: {string | number}, values: {[(string|number)]: any})
    assert(ValidateIsServer(), `You can only set values of containers in MirrorService on the server!`);

    local _tablePath,tbl = GetPath(self._Data, path, values);
    local vals = tbl:GetChildren();
    SetValuesInternal(self, values, path, vals);
end


function MirrorService:Subscribe(plr: Player)
    self._Subscribers[plr] = MirrorService.SecurityCapabilities.None;
    self.Subscribed:Fire(plr);
end

function MirrorService:Unsubscribe(plr: Player)
    self.Unsubscribed:Fire(plr);
end

function MirrorService:GetID()
    return self._ID;
end

function MirrorService.GetContainers()
    return MIRROR_CONTAINER_INSTANCES:GetChildren();
end

---------------------------~--------------------------- ~[ FULLSTACK ]~ ---------------------------~---------------------------


---------------------------~--------------------------- ~[ SERVER ]~ ---------------------------~---------------------------

function MirrorService.FromKey(key: (string | number)): MirrorService
    return Mirrors[key];
end

function MirrorService:Get(path: {string | number}?, liveReturn: boolean?)
    if not(path) then
        local tbl = ComposeDictFromInstanceValues(self._Data:GetChildren());
        if (tbl) and (liveReturn) then
            table.insert(self._GetReferences, tbl);
        end

        return tbl;
    else
        return GetPath(self._Data, path);
    end
end

function MirrorService:Destroy()
    if (ValidateIsServer()) then
        Mirrors[self._Key] = nil;
        self._Data:Destroy();
    end
end


---------------------------~--------------------------- ~[ CLIENT ]~ ---------------------------~---------------------------
---------------------------~--------------------------- ~[ CLIENT ]~ ---------------------------~---------------------------


-- Connections
local function CharacterAdded(char: Model)
    local plr = Players:GetPlayerFromCharacter(char);
    local newClientHandler = ClientHandler:Clone();
    newClientHandler.Parent = plr.PlayerGui;
end

local function PlayerAdded(plr: Player)
    plr.CharacterAdded:Connect(CharacterAdded);
end


Players.PlayerAdded:Connect(PlayerAdded);






return MirrorService;
