local plugin_data = {}
local vehicle_data = {}
local plates = {}

require "resources/essentialmode/lib/MySQL"
-- MySQL:open("IP", "databasname", "user", "password")
MySQL:open("127.0.0.1", "gta5_script_carshop", "root", "1202")

AddEventHandler("es:playerLoaded", function(source, target)
	local executed_query = MySQL:executeQuery("SELECT * FROM vehicles WHERE owner = '@name'", {['@name'] = target.identifier})
	local result = MySQL:getResults(executed_query, {'owner', 'model', 'colour', 'scolour', 'plate', 'wheels', 'windows', 'platetype', 'exhausts', 'grills', 'spoiler'}, "identifier")

	vehicle_data[source] = result

	local send = {}
	for k,v in ipairs(vehicle_data[source])do
		send[v.model] = true
	end

	TriggerClientEvent("es_carshop3:sendOwnedVehicles", source, send)
end)

function get3DDistance(x1, y1, z1, x2, y2, z2)
	return math.sqrt(math.pow(x1 - x2, 2) + math.pow(y1 - y2, 2) + math.pow(z1 - z2, 2))
end

local plates = {}
local plate_possibilities = {"Expired license",	"Stolen vehicle",	"Unregistered plate", "Warrant for owner"}

TriggerEvent('es:addCommand', 'checkplate', function(source, args, user)
	TriggerEvent("es_roleplay:getPlayerJob", function(job)
		if(job or (tonumber(user.permission_level) > 2))then
			if(#args < 2)then
				TriggerClientEvent('chatMessage', source, "JOB", {255, 0, 0}, "Usage: ^2/checkplate (PLATE)")
				return
			end

			if(job.job == "police" or tonumber(user.permission_level) > 2)then
				local plate = args[2]

				plate = string.lower(plate)

				if plate == "reborn" then
					TriggerClientEvent('chatMessage', source, "JOB", {255, 0, 0}, "Plate returns: ^1just reported stolen.")
					return
				end

				if(#plate ~= 8)then
					TriggerClientEvent('chatMessage', source, "JOB", {255, 0, 0}, "Invalid plate.")
					return
				end

				TriggerEvent('es_carshop3:getVehicleOwner', plate, function(owner, veh)
					local returns = ""

					if(owner)then
						TriggerClientEvent('es_roleplay:checkCar', source, owner, plate, veh[1])
						return;
					else
						returns = "^1STOLEN"
					end

					TriggerClientEvent('chatMessage', source, "JOB", {255, 0, 0}, "Plate returns: " .. returns .. "")
				end)
			else
				TriggerClientEvent('chatMessage', source, "JOB", {255, 0, 0}, "Tu dois etre policier .")
			end
		else
			TriggerClientEvent('chatMessage', source, "JOB", {255, 0, 0}, "Tu dois etre policer .")
		end
	end)
end)

local carshops = {
	{['x'] = -907.442, ['y'] = -1337.24, ['z'] = 1.60517},
}

local carshop_vehicles = {
	['marquis'] = 666666,

}

local spawned_vehicles = {}

AddEventHandler("es:reload", function()
	TriggerEvent('es:getPlayers', function(players)
		for i,v in pairs(players) do
			if(GetPlayerName(i))then
				TriggerEvent('es:getPlayerFromId', i, function(target)
					local executed_query = MySQL:executeQuery("SELECT * FROM vehicles WHERE owner = '@name'", {['@name'] = target.identifier})
					local result = MySQL:getResults(executed_query, {'owner', 'model', 'colour', 'scolour', 'plate', 'wheels', 'windows', 'platetype', 'exhausts', 'grills', 'spoiler'}, "identifier")

					vehicle_data[i] = result

					local send = {}
					for k,v in ipairs(vehicle_data[i])do
						send[v.model] = true
					end

					TriggerClientEvent("es_carshop3:sendOwnedVehicles", i, send)
				end)
			end
		end
	end)
end)

AddEventHandler('es_carshop3:getVehicleOwner', function(pl, cb)
	if(plates[pl])then
		TriggerEvent('es:getPlayerFromId', plates[pl], function(user)
			if(user)then
				cb(plates[pl], vehicle_data[plates[pl]])
			else
				cb(plates[pl], nil)
			end
		end)
	else
		cb(plates[pl], nil)
	end
end)

AddEventHandler("onResourceStart", function(rs)
	if(rs ~= 'es_carshop3')then
		return
	end

	SetTimeout(2000, function()
		TriggerEvent('es:getPlayers', function(players)
			for i,v in pairs(players) do
				if(GetPlayerName(i))then
					TriggerEvent('es:getPlayerFromId', i, function(target)
						if(target)then
							local executed_query = MySQL:executeQuery("SELECT * FROM vehicles WHERE owner = '@name'", {['@name'] = target.identifier})
							local result = MySQL:getResults(executed_query, {'owner', 'model', 'colour', 'scolour', 'plate', 'wheels', 'windows', 'platetype', 'exhausts', 'grills', 'spoiler'}, "identifier")

							vehicle_data[i] = result

							local send = {}
							for k,v in ipairs(vehicle_data[i])do
								send[v.model] = true
							end

							TriggerClientEvent("es_carshop3:sendOwnedVehicles", i, send)
						end
					end)
				end
			end
		end)

		end)
end)

TriggerEvent('es:addCommand', 'rv', function(source, args, user)
	TriggerClientEvent('es_carshop3:removeVehiclesDeleting', source)
end)

RegisterServerEvent('es_carshop3:vehicleRemoved')
AddEventHandler('es_carshop3:vehicleRemoved', function()
	spawned_vehicles[source] = nil
end)

function deletePlate(pl)
	plates[pl] = nil
end

AddEventHandler('playerDropped', function()
	spawned_vehicles[source] = nil
end)

RegisterServerEvent('es_carshop3:buyVehicle')
AddEventHandler('es_carshop3:buyVehicle', function(veh)
	if(spawned_vehicles[source] ~= nil)then
		TriggerClientEvent('es_carshop3:closeWindow', source)
		TriggerClientEvent('chatMessage', source, "SHOP", {255, 0, 0}, "Tu as déjà un autre véhicule sorti, pour le ranger monte dedans et tape ^2/rv")
		return
	end

	TriggerEvent('es:getPlayerFromId', source, function(user)
		TriggerEvent('es_roleplay:getPlayerJob', user.identifier, function(job)
			if(veh == "police")then
				if(job)then
					if(job.job ~= "police")then
						TriggerClientEvent('es_carshop3:closeWindow', source)
						TriggerClientEvent('chatMessage', source, "SHOP", {255, 0, 0}, "Tu ne peux acheter ou faire spawn ce véhicule que si tu es ^2policier^0.")
						return
					end
				else
					TriggerClientEvent('es_carshop3:closeWindow', source)
					TriggerClientEvent('chatMessage', source, "SHOP", {255, 0, 0}, "Tu ne peux acheter ou faire spawn ce véhicule que si tu es ^2policier^0.")
					return
				end
			end

			if(veh == "mule" or veh == "benson")then
				if(job)then
					if(job.job ~= "trucker")then
						TriggerClientEvent('es_carshop3:closeWindow', source)
						TriggerClientEvent('chatMessage', source, "SHOP", {255, 0, 0}, "Tu ne peux acheter ou faire spawn ce véhicule que si tu es ^2trucker^0.")
						return
					end
				else
					TriggerClientEvent('es_carshop3:closeWindow', source)
					TriggerClientEvent('chatMessage', source, "SHOP", {255, 0, 0}, "Tu ne peux acheter ou faire spawn ce véhicule que si tu es ^2trucker^0.")
					return
				end
			end

			for k,v in carshops do
				if(get3DDistance(v.x, v.y, v.z, user.coords.x, user.coords.y, user.coords.z) < 2.0)then
					return
				end
			end

			if(vehicle_data[source])then
				for k,v in ipairs(vehicle_data[source]) do
					if(v.owner == user.identifier and veh == v.model)then
						TriggerClientEvent('es_carshop3:closeWindow', source)
						TriggerClientEvent('chatMessage', source, "SHOP", {255, 0, 0}, "Véhicule personnel sorti.")
						TriggerClientEvent('es_carshop3:removeVehicles', source)
						if(v.model == "police" or v.model == "mule" or v.model == "benson")then
							v.colour = "255,255,255"
						end
						TriggerClientEvent('es_carshop3:createVehicle', source, veh, { main_colour = stringsplit(v.colour, ","), secondary_colour = stringsplit(v.scolour, ","), plate = v.plate, wheels = v.wheels, windows = v.windows, platetype = v.platetype, exhausts = v.exhausts, grills = v.grills, spoiler = v.spoiler }  )
						spawned_vehicles[source] = true
						plates[string.lower(v.plate)] = source
						return
					end
				end
			end


			if(carshop_vehicles[veh])then
				local price = carshop_vehicles[veh]

				if(tonumber(user.money) >= price)then
					user:removeMoney(price)
					TriggerClientEvent('es_carshop3:closeWindow', source)
					TriggerClientEvent('chatMessage', source, "SHOP", {255, 0, 0}, "Véhicule acheté!")
					TriggerClientEvent('es_carshop3:sendOwnedVehicle', source, veh)
					addVehicle(source, veh)
					spawned_vehicles[source] = true
				else
					TriggerClientEvent('chatMessage', source, "SHOP", {255, 0, 0}, "Pas assez d'argent.")
				end
			end
		end)
	end)
end)

local spawned_vehicles = {}

RegisterServerEvent('es_carshop3:newVehicleSpawned')
AddEventHandler('es_carshop3:newVehicleSpawned', function(veh)
	if(spawned_vehicles[source])then
		if(spawned_vehicles[source] ~= veh)then
			TriggerClientEvent('es_carshop3:removeNetworkVehicle', -1, spawned_vehicles[source])
			spawned_vehicles[source] = veh
		end
	else
		spawned_vehicles[source] = veh
	end
end)

local limiter = {}

RegisterServerEvent('es_carshop3:vehicleCustom')
AddEventHandler('es_carshop3:vehicleCustom', function(model, data)
	if(true)then
		if(spawned_vehicles[source] ~= nil)then
			local pstring = "" .. data.r .. "," .. data.g .. "," .. data.b
			local sstring = "" .. data.r2 .. "," .. data.g2 .. "," .. data.b2
			if(vehicle_data[source] ~= nil)then
				for k,v in ipairs(vehicle_data[source])do
					if(v.model == model)then
						if(limiter[source] == nil)then
							limiter[source] = 0
						end
						if(limiter[source] < os.time())then
							TriggerEvent("es:getPlayerFromId", source, function(user)
								limiter[source] = os.time() + 60
								user:removeMoney(1500)
								vehicle_data[source][k].colour = pstring
								vehicle_data[source][k].scolour = sstring

								vehicle_data[source][k].wheels = data.wheels
								vehicle_data[source][k].windows = data.windows
								vehicle_data[source][k].platetype = data.platetype
								vehicle_data[source][k].exhausts = data.dexhausts
								vehicle_data[source][k].grills = data.grills
								vehicle_data[source][k].spoiler = data.spoiler

								setDynamicMulti(source, model, {
									{row = "colour", value = pstring},
									{row = "scolour", value = sstring},
									{row = "wheels", value = data.wheels},
									{row = "windows", value = data.windows},
									{row = "platetype", value = data.platetype},
									{row = "exhausts", value = data.exhausts},
									{row = "grills", value = data.grills},
									{row = "spoiler", value = data.spoiler},
								})

								TriggerClientEvent('chatMessage', source, "CUSTOMS", {255, 0, 0}, "Modifications apportées au véhicule sauvegardées.")
							end)
						else
							TriggerClientEvent('chatMessage', source, "CUSTOMS", {255, 0, 0}, "Tu pourras à nouveau sauvegarder ton véhicule dans ^2^*" .. (limiter[source] - os.time()) .. " ^r^0secondes.")
						end
					end
				end
			end
		else
			TriggerClientEvent("chatMessage", source, "CUSTOMS", {255, 0, 0}, "Pas de véhicule personnel à sauvegarder.")
		end
	end
end)

function setDynamicMulti(source, vehicle, options)
	TriggerEvent('es:getPlayerFromId', source, function(user)
		local str = "UPDATE vehicles SET "
		for k,v in ipairs(options)do
			if(k ~= #options)then
				str = str .. v.row .. "=" .. "'" .. v.value .. "',"
			else
				str = str .. v.row .. "=" .. "'" .. v.value .. "' WHERE owner='" .. user.identifier .. "' AND model='" .. vehicle .. "'"
			end
		end

		MySQL:executeQuery(str)
	end)
end

function setDynamic(source, vehicle, row, val)
	TriggerEvent('es:getPlayerFromId', source, function(user)
		MySQL:executeQuery("UPDATE vehicles SET @row='@value' WHERE owner = '@owner' AND model = '@model'",
		{['@row'] = row, ['@value'] = val, ['@owner'] = user.identifier, ['@model'] = vehicle})
	end)
end

function addVehicle(s, v)
	TriggerEvent('es:getPlayerFromId', s, function(user)
		local plate = generatePlate(8)
		TriggerClientEvent('es_carshop3:removeVehicles', source)
		TriggerClientEvent('es_carshop3:createVehicle', source, v, { main_colour = stringsplit("0,0,0", ","), secondary_colour = stringsplit("0,0,0", ","), plate = plate, wheels = v.wheels, windows = v.windows, platetype = v.platetype, exhausts = v.exhausts, grills = v.grills, spoiler = v.spoiler })

		if(vehicle_data[s] == nil)then
			vehicle_data[s] = {}
			vehicle_data[s][1] = {owner = user.identifier, model = v, colour = '0,0,0', scolour = '0,0,0', plate = plate}

			vehicle_data[source][1].wheels = 0
			vehicle_data[source][1].windows = 0
			vehicle_data[source][1].platetype = 0
			vehicle_data[source][1].exhausts = 0
			vehicle_data[source][1].grills = 0
			vehicle_data[source][1].spoiler = 0


		else
			vehicle_data[s][#vehicle_data[s] + 1] = {owner = user.identifier, model = v, colour = '0,0,0', scolour = '0,0,0'}
		end

		MySQL:executeQuery("INSERT INTO vehicles (`owner`, `model`, `colour`, `scolour`, `plate`) VALUES ('@username', '@model', '0,0,0', '0,0,0', '@plate')",
		{['@username'] = user.identifier, ['@model'] = v, ['@plate'] = plate})

		plates[string.lower(plate)] = s
	end)
end

-- Util function stuff
function stringsplit(self, delimiter)
  local a = self:Split(delimiter)
  local t = {}

  for i = 0, #a - 1 do
     table.insert(t, a[i])
  end

  return t
end

local charset = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","1","2","3","4","5","6","7","8","9"}

function generatePlate(length)
  if length > 0 then
    return generatePlate(length - 1) .. charset[math.random(1, #charset)]
  else
    return ""
  end
end
