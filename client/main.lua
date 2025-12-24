local Utils = require 'client.utils'
local Blips = require 'client.blip'
local cops = {}
local nearbyCops = {}
local whiteListed = false
local STREAMING_DISTANCE = 550.0
local STREAMING_DISTANCE_SQ = STREAMING_DISTANCE * STREAMING_DISTANCE

local function getCopFromSource(source)
    for i = 1, #cops do
        if cops[i].source == source then
            return i
        end
    end
end

local function clearNearbyCop(source)
    if nearbyCops[source] then
        nearbyCops[source] = nil
        local index = getCopFromSource(source)
        local cop = index and cops[index]

        if cop and cop.blip then
            local blipCoord = GetBlipCoords(cop.blip)

            RemoveBlip(cop.blip)

            cop.blip = Blips.addBlipForCoord(blipCoord, {
                color = cop.color,
                name = cop.name,
            })
        end
    end
end

Utils.registerNetEvent('Renewed-Dutyblips:updateBlips', function(data)
    for i = 1, #data do
        local cop = cops[i]

        if cop then
            cop.lastCoords = data[i]

            if not nearbyCops[cop.source] and cop.source ~= cache.serverId then
                if cop.blip then
                    Blips.changeBlipCoords(cop.blip, data[i])
                else
                    cop.blip = Blips.addBlipForCoord(data[i], {
                        color = cop.color,
                        name = cop.name,
                    })
                end
            end
        end
    end
end)


local loopRunning = false
local function nearbyLoop()
    if loopRunning then return end
    loopRunning = true

    while next(nearbyCops) do
        local playerCoords = GetEntityCoords(cache.ped)

        for i = 1, #cops do
            local cop = cops[i]

            local pedHandle = cop and nearbyCops[cop.source]

            if cop and cop.blip and pedHandle then
                if pedHandle > 0 and DoesEntityExist(pedHandle) then
                    local pedCoords = GetEntityCoords(pedHandle)
                    local dx = pedCoords.x - playerCoords.x
                    local dy = pedCoords.y - playerCoords.y

                    if dx * dx + dy * dy > STREAMING_DISTANCE_SQ then
                        clearNearbyCop(cop.source)
                    else
                        Blips.changeBlipForEntity(cop.blip, pedHandle)
                    end
                elseif cop.lastCoords then
                    local dx = cop.lastCoords.x - playerCoords.x
                    local dy = cop.lastCoords.y - playerCoords.y

                    if dx * dx + dy * dy > STREAMING_DISTANCE_SQ then
                        clearNearbyCop(cop.source)
                    end
                else
                    clearNearbyCop(cop.source)
                end
            end

        end
        Wait(1000)
    end

    loopRunning = false
end

AddStateBagChangeHandler('renewed_dutyblips', nil, function(bagName, _, value)
    local source = tonumber(bagName:gsub('player:', ''), 10)

    if not whiteListed or source == cache.serverId then
        return
    end

    if not value then
        return clearNearbyCop(source)
    end

    local index = getCopFromSource(source)

    if index then
        local playerId = GetPlayerFromServerId(source)
        local pedHandle = Utils.awaitPedHandle(playerId)

        if pedHandle then
            local cop = cops[index]

            if cop.blip then
                RemoveBlip(cop.blip)
                cop.blip = nil
            end

            cop.blip = Blips.addBlipForEntity(pedHandle, cop)
            nearbyCops[source] = pedHandle

            if not loopRunning then
                SetTimeout(0, nearbyLoop)
            end
        end
    end

end)

RegisterNetEvent('onPlayerDropped', function(serverId)
    clearNearbyCop(serverId)
end)


Utils.registerNetEvent('Renewed-Dutyblips:addOfficer', function(data)
    cops[#cops+1] = {
        source = tonumber(data.source),
        name = data.name,
        color = data.color or 1,
    }
end)

Utils.registerNetEvent('Renewed-Dutyblips:removeOfficer', function(index)
    local cop = cops[index]

    if cop then
        if cop.source then
            nearbyCops[cop.source] = nil
        end

        local blip = cop.blip

        if blip then
            RemoveBlip(blip)
        end

        table.remove(cops, index)
    end
end)


Utils.registerNetEvent('Renewed-Dutyblips:goOffDuty', function()
    for i = 1, #cops do
        local cop = cops[i]

        if cop.blip then
            RemoveBlip(cop.blip)
        end
    end

    table.wipe(cops)
    table.wipe(nearbyCops)
    whiteListed = false
end)

Utils.registerNetEvent('Renewed-Dutyblips:goOnDuty', function(copsData)
    for i = 1, #copsData do
        local cop = copsData[i]

        cops[i] = {
            source = tonumber(cop.source),
            name = cop.name,
            color = cop.color or 1,
        }
    end

    whiteListed = true
end)
