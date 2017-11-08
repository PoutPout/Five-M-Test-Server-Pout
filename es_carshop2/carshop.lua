local guiEnabled = false
local inCustomization = false
local isOwnedVehicleSpawned = false

local vehicles = {}

RegisterNUICallback('escape', function(data, cb)
    EnableGui(false)

    cb('ok')
end)

RegisterNUICallback('buy_vehicle', function(veh, cb)
    TriggerServerEvent('es_carshop2:buyVehicle', veh.vehicle)

    cb('ok')
end)

RegisterNetEvent("es_carshop2:sendOwnedVehicles")
AddEventHandler('es_carshop2:sendOwnedVehicles', function(v)
	SendNUIMessage({
        type = "vehicles",
        enable = v
    })
end)

RegisterNetEvent("es_carshop2:sendOwnedVehicle")
AddEventHandler('es_carshop2:sendOwnedVehicle', function(v)
	SendNUIMessage({
        type = "vehicle",
        enable = v
    })
end)

-- Util function stuff
function stringsplit(self, delimiter)
  local a = self:Split(delimiter)
  local t = {}

  for i = 0, #a - 1 do
     table.insert(t, a[i])
  end

  return t
end

RegisterNetEvent('es_carshop2:closeWindow')
AddEventHandler('es_carshop2:closeWindow', function()
	EnableGui(false)
end)

local spawnedVehicle = nil

RegisterNetEvent('es_roleplay:checkCar')
AddEventHandler('es_roleplay:checkCar', function(owner, pl, v)
	local vehicle = GetVehiclePedIsIn(GetPlayerPed(GetPlayerFromServerId(owner)),  false)

	if(vehicle)then
		local plate = GetVehicleNumberPlateText(vehicle)

		if(string.lower(plate) == pl)then
			TriggerEvent('chatMessage', 'JOB', {255, 0, 0}, "Plate returns: ^2^*clean^r^0, Owner: ^*^2" .. GetPlayerName(GetPlayerFromServerId(owner)))
		else
			TriggerEvent('chatMessage', 'JOB', {255, 0, 0}, "Plate returns: ^1^*stolen^r^0, Owner: ^*^2" .. GetPlayerName(GetPlayerFromServerId(owner)))
		end
	else
		local vehicle = GetVehiclePedIsIn(GetPlayerPed(GetPlayerFromServerId(owner)),  true)

		if vehicle then
			local plate = GetVehicleNumberPlateText(vehicle)

			if(string.lower(plate) == pl and (GetPedInVehicleSeat(vehicle, -1) == GetPlayerPed(-1) or GetPedInVehicleSeat(vehicle, -1) == false))then
				TriggerEvent('chatMessage', 'JOB', {255, 0, 0}, "Plate returns: ^2^*clean^r^0, Owner: ^*^2" .. GetPlayerName(GetPlayerFromServerId(owner)))
			else
				TriggerEvent('chatMessage', 'JOB', {255, 0, 0}, "Plate returns: ^1^*stolen^r^0, Owner: ^*^2" .. GetPlayerName(GetPlayerFromServerId(owner)))
			end
		else
			TriggerEvent('chatMessage', 'JOB', {255, 0, 0}, "Plate returns: ^1^*stolen^r^0, Owner: ^*^2NPC^0")
		end
	end
end)

DecorRegister("owner", 3)

RegisterNetEvent('es_carshop2:createVehicle')
AddEventHandler('es_carshop2:createVehicle', function(v, options)
	local carid = GetHashKey(v)
	local playerPed = GetPlayerPed(-1)
	if playerPed and playerPed ~= -1 and isOwnedVehicleSpawned == false then
		RequestModel(carid)
		while not HasModelLoaded(carid) do
				Citizen.Wait(0)
		end
		local playerCoords = GetEntityCoords(playerPed)

		DoScreenFadeOut(0)

		local veh = CreateVehicle(carid, playerCoords, 0.0, true, false)
		spawnedVehicle = NetworkGetNetworkIdFromEntity(veh);
		DecorSetInt(veh, "owner", GetPlayerServerId(PlayerId()))
		SetVehicleModKit(veh, 0)
		TaskWarpPedIntoVehicle(playerPed, veh, -1)
		SetVehicleNumberPlateText(veh, options.plate)
		SetVehicleMod(veh, 23, options.wheels, false)
		SetVehicleWindowTint(veh, options.windows)
		SetVehicleNumberPlateTextIndex(veh, options.platetype)
		SetVehicleMod(veh,  4,  options.exhausts,  false)
		SetVehicleMod(veh,  6,  options.grills,  false)
		SetVehicleMod(veh,  0,  options.spoiler,  false)
		SetVehicleDirtLevel(veh, 0)
		TriggerServerEvent('es_carshop2:newVehicleSpawned', NetworkGetNetworkIdFromEntity(veh))
		SetEntityInvincible(veh, false)
		SetVehicleEngineOn(veh, true, true)
		local blip = AddBlipForEntity(veh)
		SetBlipSprite(blip, 225)
		Citizen.Trace(spawnedVehicle .. "\n")

		isOwnedVehicleSpawned = true

		DoScreenFadeIn(2500)
	end
end)

local player_owned = {}
RegisterNetEvent('es_carshop2:removeVehiclesDeleting')
AddEventHandler('es_carshop2:removeVehiclesDeleting', function()
	if isOwnedVehicleSpawned then

		if DecorGetInt(GetVehiclePedIsIn(GetPlayerPed(-1), false), "owner") then

			if DecorGetInt(GetVehiclePedIsIn(GetPlayerPed(-1), false), "owner") == GetPlayerServerId(PlayerId()) then
				SetEntityAsMissionEntity(GetVehiclePedIsIn(GetPlayerPed(-1), false))
				Citizen.InvokeNative(0xEA386986E786A54F, Citizen.PointerValueIntInitialized(GetVehiclePedIsIn(GetPlayerPed(-1))))

				TriggerServerEvent('es_carshop2:vehicleRemoved')
				TriggerEvent('chatMessage', 'SHOP', {255, 0, 0}, 'Tu as rangé ton vehicule!')
				isOwnedVehicleSpawned = false
			else
				TriggerEvent('chatMessage', 'SHOP', {255, 0, 0}, 'Tu dois etre dans ton vehicule pour le ranger.')
			end
		else
			TriggerEvent('chatMessage', 'SHOP', {255, 0, 0}, 'Tu dois etre dans ton vehicule pour le ranger.')
		end
	else
		TriggerEvent('chatMessage', 'SHOP', {255, 0, 0}, 'Pour ranger ton vehicule tu dois deja le faire apparaitre.')
	end
end)


function EnableGui(enable)
    SetNuiFocus(enable)
    guiEnabled = enable

    SendNUIMessage({
        type = "enableui",
        enable = enable
    })
end

local carshops = {
	{['x'] = -978.59, ['y'] = -3007.38, ['z'] = 13.9451},
  {['x'] = 1603.62, ['y'] = 3232.93, ['z'] = 39.9673},
  {['x'] = 2138.63, ['y'] = 4811.77, ['z'] = 40.7026},
}

function DisplayHelpText(str)
	SetTextComponentFormat("STRING")
	AddTextComponentString(str)
	DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

Citizen.CreateThread(function()
	for k,v in ipairs(carshops) do
		TriggerEvent('es_carshop2:createBlip', 90, v.x, v.y, v.z)
	end
end)

local menu = {
	["Primary Colour"] = function(e)
		print(e)
	end,
	["Secondary Colour"] = function(e)
		print(e)
	end
}

RegisterNetEvent("es_carshop2:createBlip")
AddEventHandler("es_carshop2:createBlip", function(type, x, y, z)
	local blip = AddBlipForCoord(x, y, z)
	SetBlipSprite(blip, type)
	SetBlipScale(blip, 0.8)
	SetBlipAsShortRange(blip, true)

	if(type == 67)then
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString("Trucking mission")
		EndTextCommandSetBlipName(blip)
	elseif(type == 110)then
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString("Weapon store")
		EndTextCommandSetBlipName(blip)
	elseif(type == 237)then
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString("Jail")
		EndTextCommandSetBlipName(blip)
	elseif(type == 50)then
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString("Garage")
		EndTextCommandSetBlipName(blip)
	end
end)

RegisterNetEvent('es_carshop2:setColour')
AddEventHandler('es_carshop2:setColour', function(r, g, b)
	SetVehicleCustomPrimaryColour(NetworkGetEntityFromNetworkId(spawnedVehicle),  r,  g,  b)
end)

RegisterNetEvent('es_carshop2:setColourSecondary')
AddEventHandler('es_carshop2:setColourSecondary', function(r, g, b)
	SetVehicleCustomSecondaryColour(NetworkGetEntityFromNetworkId(spawnedVehicle),  r,  g,  b)
end)

local function drawTxt(x,y ,width,height,scale, text, r,g,b,a, outline, center)
    SetTextFont(0)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
	if(center)then
		Citizen.Trace("CENTER\n")
		SetTextCentre(false)
	end
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    if(outline)then
	    SetTextOutline()
	end
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x - width/2, y - height/2 + 0.005)
end
vehicle_names = {
	[-901163259] = 'dodo',
  [788747387] = 'frogger',
  [1077420264] = 'velum2',
  [970356638] = 'duster',
  [621481054] = 'luxor',
  [-1295027632] = 'nimbus',
  [-1845487887] = 'volatus'

}

local selected = 1
local keyboard = false
local tkeyboard = nil
local vehicleLocked = false

local selected = 1
local keyboard = false
local tkeyboard = nil

local showFixMessage = false

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if(showFixMessage)then
			Citizen.Wait(3000)
			showFixMessage = false
		end
	end
end)

Citizen.CreateThread(function()
    while true do
			Citizen.Wait(1)

			for k,v in ipairs(vehicles) do
				SetVehicleTyresCanBurst(v, true)
			end

			if(showFixMessage)then
				DisplayHelpText("Tu ~g~as reparer~w~ ton ~b~vehicle~w~!")
			end

			local pos = GetEntityCoords(GetPlayerPed(-1), true)

				for k,v in ipairs(carshops) do
					if(Vdist(pos.x, pos.y, pos.z, v.x, v.y, v.z) < 100.0)then
						DrawMarker(1, v.x, v.y, v.z - 1, 0, 0, 0, 0, 0, 0, 3.0001, 3.0001, 1.5001, 255, 165, 0,165, 0, 0, 0,0)

						if(Vdist(pos.x, pos.y, pos.z, v.x, v.y, v.z) < 2.0 and showFixMessage == false)then
							if(not IsPedInAnyVehicle(GetPlayerPed(-1), false))then
								DisplayHelpText("Appuies sur ~INPUT_CONTEXT~ pour acceder au ~b~garage~w~ pour acheter et faire spawn ton vehicule.")

								if(IsControlJustReleased(1, 51))then
									EnableGui(true)
								end
							else
								if(IsVehicleDamaged(GetVehiclePedIsIn(GetPlayerPed(-1), false)) and GetPedInVehicleSeat(GetVehiclePedIsIn(GetPlayerPed(-1)), -1) == GetPlayerPed(-1))then
									DisplayHelpText("Appuies sur ~INPUT_CONTEXT~ pour reparer ton vehicule actuel.")
									if(IsControlJustReleased(1, 51))then
										showFixMessage = true
										SetVehicleFixed(GetVehiclePedIsIn(GetPlayerPed(-1)))
									end
								else
									DisplayHelpText("Tu ne peux pas etre dans un vehicule pour acceder au garage.")
								end
							end
						end
					end
				end

        if guiEnabled then
			DisableControlAction(1, 18, true)
			DisableControlAction(1, 24, true)
			DisableControlAction(1, 69, true)
			DisableControlAction(1, 92, true)
			DisableControlAction(1, 106, true)
			DisableControlAction(1, 122, true)
			DisableControlAction(1, 135, true)
			DisableControlAction(1, 142, true)
			DisableControlAction(1, 144, true)
			DisableControlAction(1, 176, true)
			DisableControlAction(1, 223, true)
			DisableControlAction(1, 229, true)
			DisableControlAction(1, 237, true)
			DisableControlAction(1, 257, true)
			DisableControlAction(1, 329, true)

			DisableControlAction(1, 14, true)
			DisableControlAction(1, 16, true)
			DisableControlAction(1, 41, true)
			DisableControlAction(1, 43, true)
			DisableControlAction(1, 81, true)
			DisableControlAction(1, 97, true)
			DisableControlAction(1, 180, true)
			DisableControlAction(1, 198, true)
			DisableControlAction(1, 39, true)
			DisableControlAction(1, 50, true)

			DisableControlAction(1, 22, true)
			DisableControlAction(1, 55, true)
			DisableControlAction(1, 76, true)
			DisableControlAction(1, 102, true)
			DisableControlAction(1, 114, true)
			DisableControlAction(1, 143, true)
			DisableControlAction(1, 179, true)
			DisableControlAction(1, 193, true)
			DisableControlAction(1, 203, true)
			DisableControlAction(1, 216, true)
			DisableControlAction(1, 255, true)
			DisableControlAction(1, 298, true)
			DisableControlAction(1, 321, true)
			DisableControlAction(1, 328, true)
			DisableControlAction(1, 331, true)

            if IsDisabledControlJustReleased(0, 142) then -- MeleeAttackAlternate
                SendNUIMessage({
                    type = "click"
                })
            end
        end
    end
end)

EnableGui(false)
