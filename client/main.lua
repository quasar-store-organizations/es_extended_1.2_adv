local isPaused, isDead, pickups = false, false, {}

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if NetworkIsPlayerActive(PlayerId()) then
			TriggerServerEvent('esx:onPlayerJoined')
			break
		end
	end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerData)
	ESX.PlayerLoaded = true
	ESX.PlayerData = playerData

	-- check if player is coming from loading screen
	if GetEntityModel(PlayerPedId()) == GetHashKey('PLAYER_ZERO') then
		local defaultModel = GetHashKey('a_m_y_stbla_02')
		RequestModel(defaultModel)

		while not HasModelLoaded(defaultModel) do
			Citizen.Wait(10)
		end

		SetPlayerModel(PlayerId(), defaultModel)
		SetPedDefaultComponentVariation(PlayerPedId())
		SetPedRandomComponentVariation(PlayerPedId(), true)
		SetModelAsNoLongerNeeded(defaultModel)
	end

	-- freeze the player
	FreezeEntityPosition(PlayerPedId(), true)

	-- enable PVP
	SetCanAttackFriendly(PlayerPedId(), true, false)
	NetworkSetFriendlyFireOption(true)

	-- disable wanted level
	ClearPlayerWantedLevel(PlayerId())
	SetMaxWantedLevel(0)

	if Config.EnableHud then
		for k,v in ipairs(playerData.accounts) do
			local accountTpl = '<div><img src="img/accounts/' .. v.name .. '.png"/>&nbsp;{{money}}</div>'
			ESX.UI.HUD.RegisterElement('account_' .. v.name, k, 0, accountTpl, {money = ESX.Math.GroupDigits(v.money)})
		end

		local jobTpl = '<div>{{job_label}} - {{grade_label}}</div>'

		if playerData.job.grade_label == '' or playerData.job.grade_label == playerData.job.label then
			jobTpl = '<div>{{job_label}}</div>'
		end

		ESX.UI.HUD.RegisterElement('job', #playerData.accounts, 0, jobTpl, {
			job_label = playerData.job.label,
			grade_label = playerData.job.grade_label
		})
	end

	ESX.Game.Teleport(PlayerPedId(), {
		x = playerData.coords.x,
		y = playerData.coords.y,
		z = playerData.coords.z + 0.25,
		heading = playerData.coords.heading
	}, function()
		TriggerServerEvent('esx:onPlayerSpawn')
		TriggerEvent('esx:onPlayerSpawn')
		TriggerEvent('playerSpawned') -- compatibility with old scripts, will be removed soon
		TriggerEvent('esx:restoreLoadout')

		Citizen.Wait(4000)
		ShutdownLoadingScreen()
		ShutdownLoadingScreenNui()
		FreezeEntityPosition(PlayerPedId(), false)
		DoScreenFadeIn(10000)
		StartServerSyncLoops()
	end)

	TriggerEvent('esx:loadingScreenOff')
end)

RegisterNetEvent('esx:setMaxWeight')
AddEventHandler('esx:setMaxWeight', function(newMaxWeight) ESX.PlayerData.maxWeight = newMaxWeight end)

AddEventHandler('esx:onPlayerSpawn', function() isDead = false end)
AddEventHandler('esx:onPlayerDeath', function() isDead = true end)

AddEventHandler('skinchanger:modelLoaded', function()
	while not ESX.PlayerLoaded do
		Citizen.Wait(100)
	end

	TriggerEvent('esx:restoreLoadout')
end)

RegisterNetEvent('esx:setAccountMoney')
AddEventHandler('esx:setAccountMoney', function(account)
	for k,v in ipairs(ESX.PlayerData.accounts) do
		if v.name == account.name then
			ESX.PlayerData.accounts[k] = account
			break
		end
	end

	if Config.EnableHud then
		ESX.UI.HUD.UpdateElement('account_' .. account.name, {
			money = ESX.Math.GroupDigits(account.money)
		})
	end
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
end)

RegisterNetEvent('esx:teleport')
AddEventHandler('esx:teleport', function(coords)
	local playerPed = PlayerPedId()

	-- ensure decmial number
	coords.x = coords.x + 0.0
	coords.y = coords.y + 0.0
	coords.z = coords.z + 0.0

	ESX.Game.Teleport(playerPed, coords)
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	if Config.EnableHud then
		ESX.UI.HUD.UpdateElement('job', {
			job_label = job.label,
			grade_label = job.grade_label
		})
	end
end)

RegisterNetEvent('esx:spawnVehicle')
AddEventHandler('esx:spawnVehicle', function(vehicleName)
	local model = (type(vehicleName) == 'number' and vehicleName or GetHashKey(vehicleName))

	if IsModelInCdimage(model) then
		local playerPed = PlayerPedId()
		local playerCoords, playerHeading = GetEntityCoords(playerPed), GetEntityHeading(playerPed)

		ESX.Game.SpawnVehicle(model, playerCoords, playerHeading, function(vehicle)
			TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
		end)
	else
		TriggerEvent('chat:addMessage', {args = {'^1SYSTEM', 'Invalid vehicle model.'}})
	end
end)

RegisterNetEvent('esx:registerSuggestions')
AddEventHandler('esx:registerSuggestions', function(registeredCommands)
	for name,command in pairs(registeredCommands) do
		if command.suggestion then
			TriggerEvent('chat:addSuggestion', ('/%s'):format(name), command.suggestion.help, command.suggestion.arguments)
		end
	end
end)

RegisterNetEvent('esx:deleteVehicle')
AddEventHandler('esx:deleteVehicle', function(radius)
	local playerPed = PlayerPedId()

	if radius and tonumber(radius) then
		radius = tonumber(radius) + 0.01
		local vehicles = ESX.Game.GetVehiclesInArea(GetEntityCoords(playerPed), radius)

		for k,entity in ipairs(vehicles) do
			local attempt = 0

			while not NetworkHasControlOfEntity(entity) and attempt < 100 and DoesEntityExist(entity) do
				Citizen.Wait(100)
				NetworkRequestControlOfEntity(entity)
				attempt = attempt + 1
			end

			if DoesEntityExist(entity) and NetworkHasControlOfEntity(entity) then
				ESX.Game.DeleteVehicle(entity)
			end
		end
	else
		local vehicle, attempt = ESX.Game.GetVehicleInDirection(), 0

		if IsPedInAnyVehicle(playerPed, true) then
			vehicle = GetVehiclePedIsIn(playerPed, false)
		end

		while not NetworkHasControlOfEntity(vehicle) and attempt < 100 and DoesEntityExist(vehicle) do
			Citizen.Wait(100)
			NetworkRequestControlOfEntity(vehicle)
			attempt = attempt + 1
		end

		if DoesEntityExist(vehicle) and NetworkHasControlOfEntity(vehicle) then
			ESX.Game.DeleteVehicle(vehicle)
		end
	end
end)

-- Pause menu disables HUD display
if Config.EnableHud then
	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(300)

			if IsPauseMenuActive() and not isPaused then
				isPaused = true
				ESX.UI.HUD.SetDisplay(0.0)
			elseif not IsPauseMenuActive() and isPaused then
				isPaused = false
				ESX.UI.HUD.SetDisplay(1.0)
			end
		end
	end)

	AddEventHandler('esx:loadingScreenOff', function()
		ESX.UI.HUD.SetDisplay(1.0)
	end)
end

function StartServerSyncLoops()
	-- sync current player coords with server
	Citizen.CreateThread(function()
		local previousCoords = vector3(ESX.PlayerData.coords.x, ESX.PlayerData.coords.y, ESX.PlayerData.coords.z)

		while true do
			Citizen.Wait(1000)
			local playerPed = PlayerPedId()

			if DoesEntityExist(playerPed) then
				local playerCoords = GetEntityCoords(playerPed)
				local distance = #(playerCoords - previousCoords)

				if distance > 1 then
					previousCoords = playerCoords
					local playerHeading = ESX.Math.Round(GetEntityHeading(playerPed), 1)
					local formattedCoords = {
						x = ESX.Math.Round(playerCoords.x, 1),
						y = ESX.Math.Round(playerCoords.y, 1),
						z = ESX.Math.Round(playerCoords.z, 1),
						heading = playerHeading
					}
					TriggerServerEvent('esx:updateCoords', formattedCoords)
				end
			end
		end
	end)
end
