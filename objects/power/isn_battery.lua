require "/objects/power/isn_sharedpowerscripts.lua"

function init()
	if storage.currentstoredpower == nil then storage.currentstoredpower = 0 end
	if storage.excessCurrent ~= nil then storage.excessCurrent = nil end
	
	isn_powerInit()
end

function update(dt)
	if not storage.init then
		storage.currentstoredpower = world.getObjectParameter(entity.id(), 'isnStoredPower') or 0
		storage.init = true
	end

	storage.recentlyDischarged = false

	if storage.currentstoredpower < storage.voltage then
		animator.setAnimationState("meter", "d")
	else
		local powerlevel = math.floor(isn_numericRange(isn_getXPercentageOfY(storage.currentstoredpower,storage.powercapacity)/10,0,10))
		animator.setAnimationState("meter", tostring(powerlevel))
	end

	local powerinput = dt*isn_getCurrentPowerInput()
	storage.currentstoredpower = storage.currentstoredpower + (powerinput or 0)
	
	local poweroutput = isn_sumOutboundPowerReq()
	
	if powerinput>0 then
		if poweroutput>0 then
			animator.setAnimationState("status","on")
		else
			animator.setAnimationState("status","error")
		end
	else
		animator.setAnimationState("status","off")
	end
	
	if isn_hasStoredPower() then
		storage.recentlyDischarged = isn_getCurrentPowerOutput()
		storage.currentstoredpower = storage.currentstoredpower - dt*((storage.voltage/10.0)+storage.recentlyDischarged)
	end

	storage.currentstoredpower = math.min(storage.currentstoredpower, storage.powercapacity)
	object.setConfigParameter('description', isn_makeBatteryDescription())
end

function isn_getCurrentPowerStorage()
	return isn_getXPercentageOfY(storage.currentstoredpower,storage.powercapacity)
end

function isn_hasStoredPower()
	return storage.currentstoredpower > 0
end

function isn_getCurrentPowerOutput()
	return (not isn_hasStoredPower() and 0) or storage.voltage
end

function onNodeConnectionChange()
	nodeStuff()
end
function onInputNodeChange()
	nodeStuff()
end

function nodeStuff()
	if storage.powerOutNode then
		object.setOutputNodeLevel(storage.powerOutNode, isn_getCurrentPowerOutput()>0)
	end
end

function die()
	if storage.currentstoredpower >= storage.voltage then
		local charge = isn_getCurrentPowerStorage()
		local iConf = root.itemConfig(object.name())
		local newObject = { isnStoredPower = storage.currentstoredpower }

		if iConf and iConf.config then
			if iConf.config.inventoryIcon then
				local colour

				if     charge <  25 then colour = 'FF0000'
				elseif charge <  50 then colour = 'FF8000'
				elseif charge <  75 then colour = 'FFFF00'
				elseif charge < 100 then colour = '80FF00'
				else                     colour = '00FF00'
				end
				newObject.inventoryIcon = iConf.config.inventoryIcon .. '?border=1;' .. colour .. '?fade=' .. colour .. 'FF;0.1'
			end

			newObject.description = isn_makeBatteryDescription(iConf.config.description or '', charge)
		end

		world.spawnItem(object.name(), entity.position(), 1, newObject)
	else
		world.spawnItem(object.name(), entity.position())
	end
end

function isn_makeBatteryDescription(desc, charge)
	if desc == nil then
		desc = root.itemConfig(object.name())
		desc = desc and desc.config and desc.config.description or ''
	end
	if charge == nil then charge = isn_getCurrentPowerStorage() end
	if charge == 0 then return desc end

	if charge < 0.5 then
		charge = '< 0.5'
	else
		charge = math.floor (charge * 2) / 2
	end

	return desc .. (desc ~= '' and "\n" or '') .. "^yellow;Stored charge: " .. charge .. '%'
end
