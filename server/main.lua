lib.versionCheck('Renewed-Scripts/Renewed-Dutyblips')

local blipType = require 'config.server'.blipType
local dutyBlips = require 'server.duty'


SetInterval(function()
    local currentDutyBlips = dutyBlips.getCopsOnDuty()
    local size = #currentDutyBlips

	if size > 0 then
		local activeBlips = table.create(0, size)

		for i = 1, size do
			local cop = currentDutyBlips[i]
			local ped = cop.ped

			if not ped or not DoesEntityExist(ped) then
				ped = GetPlayerPed(cop.source)
				cop.ped = ped
			end

			local coords

			if ped and ped > 0 and DoesEntityExist(ped) then
				coords = GetEntityCoords(ped).xy
				cop.lastCoords = coords
			else
				coords = cop.lastCoords
			end

			if coords then
				activeBlips[i] = coords
			end
		end

		dutyBlips.triggerDutyEvent('Renewed-Dutyblips:updateBlips', activeBlips)
	end
end, math.random(3, 5) * 1000)


local path = ('bridge.%s'):format(blipType)

lib.load(path)
