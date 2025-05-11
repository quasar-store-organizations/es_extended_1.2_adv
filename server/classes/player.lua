function CreateExtendedPlayer(playerId, identifier, group, accounts, inventory, weight, job, loadout, name, coords)
	local self = {}

	self.accounts = accounts
	self.coords = coords
	self.group = group
	self.identifier = identifier
	self.inventory = inventory
	self.job = job
	self.loadout = loadout
	self.name = name
	self.playerId = playerId
	self.source = playerId
	self.variables = {}
	self.weight = weight
	self.maxWeight = Config.MaxWeight

	ExecuteCommand(('add_principal identifier.license:%s group.%s'):format(self.identifier, self.group))

	self.triggerEvent = function(eventName, ...)
		TriggerClientEvent(eventName, self.source, ...)
	end

	self.setCoords = function(coords)
		self.updateCoords(coords)
		self.triggerEvent('esx:teleport', coords)
	end

	self.updateCoords = function(coords)
		self.coords = {x = ESX.Math.Round(coords.x, 1), y = ESX.Math.Round(coords.y, 1), z = ESX.Math.Round(coords.z, 1), heading = ESX.Math.Round(coords.heading or 0.0, 1)}
	end

	self.getCoords = function(vector)
		if vector then
			return vector3(self.coords.x, self.coords.y, self.coords.z)
		else
			return self.coords
		end
	end

	self.kick = function(reason)
		DropPlayer(self.source, reason)
	end

	self.setMoney = function(money)
		money = ESX.Math.Round(money)
		self.setAccountMoney('money', money)
	end

	self.getMoney = function()
		return self.getAccount('money').money
	end

	self.addMoney = function(money)
		money = ESX.Math.Round(money)
		self.addAccountMoney('money', money)
	end

	self.removeMoney = function(money)
		money = ESX.Math.Round(money)
		self.removeAccountMoney('money', money)
	end

	self.getIdentifier = function()
		return self.identifier
	end

	self.setGroup = function(newGroup)
		ExecuteCommand(('remove_principal identifier.license:%s group.%s'):format(self.identifier, self.group))
		self.group = newGroup
		ExecuteCommand(('add_principal identifier.license:%s group.%s'):format(self.identifier, self.group))
	end

	self.getGroup = function()
		return self.group
	end

	self.set = function(k, v)
		self.variables[k] = v
	end

	self.get = function(k)
		return self.variables[k]
	end

	self.getAccounts = function(minimal)
		if minimal then
			local minimalAccounts = {}

			for k,v in ipairs(self.accounts) do
				minimalAccounts[v.name] = v.money
			end

			return minimalAccounts
		else
			for k,v in ipairs(self.accounts) do
				local accounts = exports['qs-advancedinventory']:GetAccounts()
				if accounts[v.name] then
					v.money = exports['qs-advancedinventory']:GetItemTotalAmount(self.source, v.name)
				end
			end
			return self.accounts
		end
	end

	self.getAccount = function(account)
		for k,v in ipairs(self.accounts) do
			if v.name == account then
				local accounts = exports['qs-advancedinventory']:GetAccounts()
				if accounts[account] then
					v.money = exports['qs-advancedinventory']:GetItemTotalAmount(self.source, account)
				end
				return v
			end
		end
	end

	self.getInventory = function(minimal)
		local inventory = exports['qs-advancedinventory']:GetInventory(self.source)
		if not inventory then return {} end
		for k,v in pairs(inventory) do
		  	v.count = v.amount
		end
		return inventory
	end

	self.getJob = function()
		return self.job
	end

	self.getLoadout = function(minimal)
		return {}
	end

	self.getName = function()
		return self.name
	end

	self.setName = function(newName)
		self.name = newName
	end

	self.setAccountMoney = function(accountName, money)
		if money >= 0 then
			local account = self.getAccount(accountName)

			if account then
				local newNoney = ESX.Math.Round(money)
				account.money = newNoney

				self.triggerEvent('esx:setAccountMoney', account)
				TriggerEvent('esx:setAccountMoney', self.source, accountName, newNoney)
				local accounts = exports['qs-advancedinventory']:GetAccounts()
				if accounts[accountName] then
					exports['qs-advancedinventory']:SetInventoryItems(self.source, accountName, newNoney)
				end
			end
		end
	end

	self.addAccountMoney = function(accountName, money)
		if money > 0 then
			local account = self.getAccount(accountName)

			if account then
				local newNoney = ESX.Math.Round(money)
				account.money = account.money + newNoney

				self.triggerEvent('esx:setAccountMoney', account)
				TriggerEvent('esx:addAccountMoney', self.source, accountName, newNoney)
				local accounts = exports['qs-advancedinventory']:GetAccounts()
				if accounts[accountName] then
					exports['qs-advancedinventory']:AddItem(self.source, accountName, newNoney)
				end
			end
		end
	end

	self.removeAccountMoney = function(accountName, money)
		if money > 0 then
			local account = self.getAccount(accountName)

			if account then
				local newNoney = ESX.Math.Round(money)
				account.money = account.money - newNoney

				self.triggerEvent('esx:setAccountMoney', account)
				TriggerEvent('esx:removeAccountMoney', self.source, accountName, newNoney)
				local accounts = exports['qs-advancedinventory']:GetAccounts()
				if accounts[accountName] then
					exports['qs-advancedinventory']:RemoveItem(self.source, accountName, newNoney)
				end
			end
		end
	end

	self.getInventoryItem = function(name, metadata)
		local item = exports['qs-advancedinventory']:GetItemByName(self.source, name)
		if not item then
			return {
			  	count = 0,
			}
		end

		item.count = item.amount
		return item
	end

	self.addInventoryItem = function(name, count, metadata, slot)
		exports['qs-advancedinventory']:AddItem(self.source, name, count or 1, slot, metadata)
	end

	self.removeInventoryItem = function(name, count, metadata, slot)
		exports['qs-advancedinventory']:RemoveItem(self.source, name, count or 1, slot, metadata)
	end

	self.setInventoryItem = function(name, count, metadata)
		exports['qs-advancedinventory']:SetInventoryItem(self.source, name, count, metadata)
	end

	self.getWeight = function()
		return self.weight
	end

	self.getMaxWeight = function()
		return self.maxWeight
	end

	self.canCarryItem = function(name, count, metadata)
		exports['qs-advancedinventory']:CanCarryItem(self.source, name, count)
	end

	self.canSwapItem = function(firstItem, firstItemCount, testItem, testItemCount)
		return true
	end

	self.setMaxWeight = function(newWeight)
		self.maxWeight = newWeight
		self.triggerEvent('esx:setMaxWeight', self.maxWeight)
	end

	self.setJob = function(job, grade)
		grade = tostring(grade)
		local lastJob = json.decode(json.encode(self.job))

		if ESX.DoesJobExist(job, grade) then
			local jobObject, gradeObject = ESX.Jobs[job], ESX.Jobs[job].grades[grade]

			self.job.id    = jobObject.id
			self.job.name  = jobObject.name
			self.job.label = jobObject.label

			self.job.grade        = tonumber(grade)
			self.job.grade_name   = gradeObject.name
			self.job.grade_label  = gradeObject.label
			self.job.grade_salary = gradeObject.salary

			if gradeObject.skin_male then
				self.job.skin_male = json.decode(gradeObject.skin_male)
			else
				self.job.skin_male = {}
			end

			if gradeObject.skin_female then
				self.job.skin_female = json.decode(gradeObject.skin_female)
			else
				self.job.skin_female = {}
			end

			TriggerEvent('esx:setJob', self.source, self.job, lastJob)
			self.triggerEvent('esx:setJob', self.job)
		else
			print(('[es_extended] [^3WARNING^7] Ignoring invalid .setJob() usage for "%s"'):format(self.identifier))
		end
	end

	self.addWeapon = function(weaponName, ammo)
		return exports['qs-advancedinventory']:GiveWeaponToPlayer(self.source, weaponName, ammo)
	end

	self.addWeaponComponent = function(weaponName, weaponComponent)

	end

	self.addWeaponAmmo = function(weaponName, ammoCount)

	end

	self.updateWeaponAmmo = function(weaponName, ammoCount)

	end

	self.setWeaponTint = function(weaponName, weaponTintIndex)

	end

	self.getWeaponTint = function(weaponName)

	end

	self.removeWeapon = function(weaponName)

	end

	self.removeWeaponComponent = function(weaponName, weaponComponent)

	end

	self.removeWeaponAmmo = function(weaponName, ammoCount)

	end

	self.hasWeaponComponent = function(weaponName, weaponComponent)

	end

	self.hasWeapon = function(weaponName)

	end

	self.getWeapon = function(weaponName)

	end

	self.showNotification = function(msg)
		self.triggerEvent('esx:showNotification', msg)
	end

	self.showHelpNotification = function(msg, thisFrame, beep, duration)
		self.triggerEvent('esx:showHelpNotification', msg, thisFrame, beep, duration)
	end

	return self
end
