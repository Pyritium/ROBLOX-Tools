local RunService = game:GetService("RunService");


local HitboxManager = {};
HitboxManager.ActiveHitboxes = {};


function HitboxManager:GetIndex(hb)
    return table.find(HitboxManager.ActiveHitboxes, hb);
end

function HitboxManager:Add(hb)
    if not(HitboxManager:GetIndex(hb)) then
        table.insert(HitboxManager.ActiveHitboxes, hb);
    end
end


function HitboxManager:Remove(hb)
    local idx = HitboxManager:GetIndex(hb)
    if (idx) then
        table.remove(HitboxManager.ActiveHitboxes, idx);
    end
end


RunService.Heartbeat:Connect(function(dt)
    for i,hb in pairs(HitboxManager.ActiveHitboxes) do
        task.spawn(function()
            local finiteTime = (hb._RunTimeMax > 0);
            local timeUp = finiteTime and hb._RunTime >= hb._RunTimeMax or false;
            if (timeUp) then
                HitboxManager:Remove(hb);
            else
                hb:_Update(dt);
            end
        end)
    end
end)


return HitboxManager;
