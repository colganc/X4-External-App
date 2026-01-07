-- Inventory widget reporter
-- Returns best-effort player/ship metadata and normalized inventory array

local ffi = require("ffi")
local C = ffi.C

local output = {}

local function safe_pairs(t)
    if type(t) ~= "table" then return function() return nil end end
    return pairs(t)
end

local function try_call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, res = pcall(fn, ...)
    if not ok then return nil end
    return res
end

function output.handle()
    local data = {}

    pcall(function()
        -- Player metadata (best-effort)
        local player = try_call(GetPlayer) or try_call(Game and Game.GetPlayer)
        if player then
            data.playerId = player.id or player.idString or tostring(player)
            data.playerName = player.name or player.callSign or nil
            data.playerFaction = player.faction or (player.GetFaction and player:GetFaction()) or nil
        end

        -- Ship metadata (best-effort)
        local ship = try_call(GetPlayerShip) or (player and player.ship) or try_call(Game and Game.GetPlayerShip)
        if ship then
            data.shipId = ship.id or ship.idString or tostring(ship)
            data.shipName = ship.name or ship.callSign or nil
        end

        -- Capacity / usage (best-effort)
        if type(GetComponentData) == "function" then
            local comp = try_call(GetComponentData, ship)
            if comp and type(comp) == "table" then
                data.capacity = comp.capacity
                data.usedCapacity = comp.usedCapacity
            end
        end

        -- Normalize inventory: produce array of { id = <string>, count = <number> }
        local items = {}

        local function push(id, count)
            if id == nil then return end
            count = tonumber(count) or 0
            table.insert(items, { id = tostring(id), count = count })
        end

        local rawInv = try_call(GetInventory) or nil
        if not rawInv and ship then
            rawInv = ship.inventory or ship.cargo or (ship.GetInventory and try_call(ship.GetInventory, ship))
        end

        if rawInv and type(rawInv) == "table" then
            for k, v in safe_pairs(rawInv) do
                if type(k) == "string" and (type(v) == "number" or type(v) == "string") then
                    push(k, v)
                elseif type(v) == "table" then
                    if v.id and v.count then
                        push(v.id, v.count)
                    else
                        for k2, v2 in pairs(v) do
                            if type(k2) == "string" and (type(v2) == "number" or type(v2) == "string") then
                                push(k2, v2)
                            end
                        end
                    end
                else
                    push(k, v)
                end
            end
        end

        data.inventory = items
    end)

    return data
end

return output
